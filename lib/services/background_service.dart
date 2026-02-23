import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/download_status.dart';
import '../models/download_task.dart';
import '../services/engine/download_engine_provider.dart';
import '../services/ffmpeg_service.dart';
import '../services/queue_service.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';

import 'download/connectivity_monitor.dart';
import 'download/download_executor.dart';
import 'download/download_orchestrator.dart';
import 'download/notification_manager.dart';
import 'download/service_lifecycle_manager.dart';

@pragma('vm:entry-point')
class BackgroundDownloadService {
  @pragma('vm:entry-point')
  static Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    // Check notification permission for Android 13+
    final hasPermission = await NotificationManager.checkPermission();
    if (!hasPermission) {
      AppLogger.warning(
        'Notification permission denied - background service may not work properly',
      );
    }

    final service = FlutterBackgroundService();

    // Ensure notification channel exists
    await NotificationManager.initializeChannel();

    await service.configure(
      androidConfiguration: NotificationManager.createAndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    unawaited(_onStart(service));
  }

  @pragma('vm:entry-point')
  static Future<void> _onStart(ServiceInstance service) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      await service.stopSelf();
      return;
    }

    // DartPluginRegistrant registers ALL plugins in this background isolate.
    // flutter_background_service_android throws because it is UI-only;
    // this is expected and safe to ignore -- the native side handles it.
    try {
      DartPluginRegistrant.ensureInitialized();
    } catch (e) {
      // Swallow registration errors from UI-only plugins (e.g.
      // flutter_background_service_android) that cannot run in a
      // background isolate.
    }
    AppLogger.debug('[BackgroundService] Service starting...');

    // 1. Initialize Managers
    final notificationManager = NotificationManager(service);

    // Ensure channel exists in this isolate
    await NotificationManager.initialize();

    final connectivityMonitor = ConnectivityMonitor(notificationManager);
    final lifecycleManager = ServiceLifecycleManager(
      service,
      notificationManager,
    );

    // Start lifecycle monitoring
    lifecycleManager.start();

    StreamSubscription<dynamic>? progressSubscription;

    // 2. Initialize Core Services
    try {
      // Initialize platform download engine
      await DownloadEngineProvider.instance.initialize();

      // FFmpegKit relies on channels that are not stable in background isolates.
      // Keep Android background downloads on yt-dlp direct output path only.
      if (!Platform.isAndroid) {
        await FFmpegService.instance.initialize();
      }
    } catch (e, st) {
      AppLogger.error('FATAL: Init failed', error: e, stackTrace: st);
      await service.stopSelf();
      return;
    }

    // Initialize QueueService (load from storage)
    await QueueService.instance.initialize();
    await SettingsService.instance.initialize();
    QueueService.instance.setServiceBridgeEnabled(false);

    // 3. Setup Executor and Orchestrator
    // Define UI Callback for updates
    void onUiUpdate(String method, Map<String, dynamic> args) {
      service.invoke(method, args);
    }

    final executor = DownloadExecutor(
      notificationManager: notificationManager,
      connectivityMonitor: connectivityMonitor,
      uiCallback: onUiUpdate,
    );

    final orchestrator = DownloadOrchestrator(
      executor: executor,
      queueService: QueueService.instance,
      connectivityMonitor: connectivityMonitor,
      lifecycleManager: lifecycleManager,
      notificationManager: notificationManager,
      uiCallback: onUiUpdate,
    );

    // Forward yt-dlp progress from plugin event channel to UI isolate listeners.
    progressSubscription = DownloadEngineProvider.instance.progressStream
        .listen(
          (event) {
            if (event is! Map) return;
            final data = Map<String, dynamic>.from(event);
            if (data['taskId'] == null) return;
            service.invoke('progress', data);
          },
          onError: (Object error) {
            AppLogger.error('Progress stream bridge error', error: error);
          },
        );

    // 4. Setup Service Listeners
    service.on('addTask').listen((event) async {
      if (event != null) {
        try {
          final task = DownloadTask.fromJson(Map<String, dynamic>.from(event));
          await QueueService.instance.addTask(task);
          unawaited(orchestrator.startProcessing());
        } catch (e) {
          AppLogger.error('Failed to add task', error: e);
        }
      }
    });

    service.on('removeTask').listen((event) async {
      if (event != null) {
        final taskId = event['taskId'] as String;
        await QueueService.instance.deleteTask(taskId);
      }
    });

    service.on('clearCompleted').listen((event) async {
      await QueueService.instance.clearCompleted();
    });

    service.on('clearErrors').listen((event) async {
      await QueueService.instance.clearErrors();
    });

    service.on('retryAllErrors').listen((event) async {
      await QueueService.instance.retryAllErrors();
      unawaited(orchestrator.startProcessing());
    });

    service.on('pauseQueue').listen((event) async {
      await SettingsService.instance.initialize();
    });

    service.on('resumeQueue').listen((event) async {
      await SettingsService.instance.initialize();
      unawaited(orchestrator.startProcessing());
    });

    service.on('cancelTask').listen((event) async {
      if (event != null) {
        final taskId = event['taskId'] as String;
        AppLogger.debug('[BackgroundService] Received cancelTask for $taskId');

        // Notify orchestrator to prevent starting if pending
        orchestrator.cancelTask(taskId);

        // Update status in queue immediately
        final task = await QueueService.instance.getTask(taskId);
        if (task != null) {
          task.status = DownloadStatus.cancelled;
          task.errorMessage = 'Cancelled by user';
          await QueueService.instance.updateTask(task);
        }

        // Attempt to cancel active download
        try {
          await DownloadEngineProvider.instance.cancelDownload(taskId);
        } catch (e) {
          AppLogger.error('Failed to cancel python download', error: e);
        }
      }
    });

    service.on('updateSettings').listen((event) {
      // Refresh settings from SharedPreferences for this background isolate.
      unawaited(SettingsService.instance.initialize());
    });

    service.on('stopService').listen((event) {
      unawaited(progressSubscription?.cancel());
      connectivityMonitor.stopMonitoring();
      unawaited(service.stopSelf());
    });

    // 5. Start Monitoring
    connectivityMonitor.startMonitoring(
      onConnectionRestored: () {
        // Resume processing when connection returns
        unawaited(orchestrator.startProcessing());
      },
    );

    // 6. Start Processing
    unawaited(orchestrator.startProcessing());
  }
}
