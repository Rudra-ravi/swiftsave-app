import 'dart:async';

import '../../models/download_status.dart';
import 'connectivity_monitor.dart';
import 'download_executor.dart';
import 'notification_manager.dart';
import 'service_lifecycle_manager.dart';
import '../queue_service.dart';
import '../settings_service.dart';
import '../../utils/app_logger.dart';

class DownloadOrchestrator {
  final DownloadExecutor _executor;
  final QueueService _queueService;
  final ConnectivityMonitor _connectivityMonitor;
  final ServiceLifecycleManager _lifecycleManager;
  final NotificationManager _notificationManager;
  final void Function(String method, Map<String, dynamic> args)? _uiCallback;

  bool _isProcessing = false;
  bool _queueProcessingScheduled = false;
  bool _pauseNotificationShown = false;
  int _activeDownloads = 0;
  final List<Completer<void>> _queueCompleter = [];
  final Set<String> _cancelledTasks = {};

  DownloadOrchestrator({
    required DownloadExecutor executor,
    required QueueService queueService,
    required ConnectivityMonitor connectivityMonitor,
    required ServiceLifecycleManager lifecycleManager,
    required NotificationManager notificationManager,
    void Function(String method, Map<String, dynamic> args)? uiCallback,
  }) : _executor = executor,
       _queueService = queueService,
       _connectivityMonitor = connectivityMonitor,
       _lifecycleManager = lifecycleManager,
       _notificationManager = notificationManager,
       _uiCallback = uiCallback;

  /// Start processing the download queue
  Future<void> startProcessing() async {
    if (_isProcessing) return;
    _isProcessing = true;

    // Cancel idle timer while processing
    _lifecycleManager.cancelIdleTimer();

    final settings = SettingsService();

    try {
      while (true) {
        // Check service runtime limits
        final shouldStop = await _lifecycleManager.checkRuntime(
          onRestartRequired: () async {
            // Nothing specific to save here as QueueService saves automatically
            // But we could force a flush if needed
          },
        );
        if (shouldStop) return;

        // Check WiFi-only constraint
        if (settings.wifiOnlyDownloads) {
          final allowed = await _connectivityMonitor
              .isPreferredNetworkAvailable();
          if (!allowed) {
            await _connectivityMonitor.waitForPreferredNetwork(
              wifiOnlyDownloads: true,
            );
            continue;
          }
        }

        // Soft pause: keep active downloads running but do not start new tasks.
        if (settings.queuePaused) {
          if (!_pauseNotificationShown) {
            _pauseNotificationShown = true;
            await _notificationManager.show(
              'Queue paused',
              'Resume queue to continue pending downloads',
            );
          }
          await Future<void>.delayed(const Duration(seconds: 1));
          continue;
        }
        _pauseNotificationShown = false;

        // Manage concurrency
        final maxConcurrent = settings.maxConcurrentDownloads;
        while (_activeDownloads >= maxConcurrent) {
          final completer = Completer<void>();
          _queueCompleter.add(completer);

          await Future.any([
            completer.future,
            Future<void>.delayed(const Duration(seconds: 30)),
          ]);

          _queueCompleter.remove(completer);

          if (_activeDownloads >= maxConcurrent) {
            await Future<void>.delayed(const Duration(seconds: 1));
          }
        }

        // Fetch next pending task
        // We get the current list from QueueService
        final tasks = _queueService.tasks;
        final pendingTaskIndex = tasks.indexWhere(
          (t) => t.status == DownloadStatus.idle,
        );

        if (pendingTaskIndex == -1) {
          // No more pending tasks
          if (_activeDownloads == 0) {
            break;
          }
          await Future<void>.delayed(const Duration(seconds: 1));
          continue;
        }

        final task = tasks[pendingTaskIndex];
        final String taskId = task.id;

        // Check if task was cancelled
        if (_cancelledTasks.contains(taskId)) {
          _cancelledTasks.remove(taskId);
          task.status = DownloadStatus.cancelled;
          task.errorMessage = 'Cancelled by user';
          await _queueService.updateTask(task);
          _notifyUi(
            taskId,
            DownloadStatus.cancelled,
            errorMessage: 'Cancelled by user',
          );
          continue;
        }

        // Prepare task for execution
        task.status = DownloadStatus.downloading;
        await _queueService.updateTask(task);
        _notifyUi(taskId, DownloadStatus.downloading);

        _activeDownloads++;
        _updateNotificationCount();

        // Execute download in background (don't await here to allow concurrency)
        unawaited(
          _executor.execute(task).then((_) {
            _activeDownloads--;

            // Signal waiting queue processors
            if (_queueCompleter.isNotEmpty) {
              final completer = _queueCompleter.removeAt(0);
              if (!completer.isCompleted) {
                completer.complete();
              }
            }

            // Schedule next iteration if needed
            if (_activeDownloads < maxConcurrent &&
                _queueService.tasks.any(
                  (t) => t.status == DownloadStatus.idle,
                ) &&
                !_queueProcessingScheduled) {
              _queueProcessingScheduled = true;
              unawaited(
                Future.microtask(() {
                  _queueProcessingScheduled = false;
                  return startProcessing();
                }),
              );
            }
          }),
        );
      }
    } catch (e, stack) {
      AppLogger.error('Orchestrator error', error: e, stackTrace: stack);
    } finally {
      _isProcessing = false;

      // Update notification when all done
      await _showReadyNotification();

      // Start idle timer
      _checkIdle();
    }
  }

  void cancelTask(String taskId) {
    _cancelledTasks.add(taskId);
  }

  void _updateNotificationCount() {
    // We assume the NotificationManager/Executor handles specific task titles
    // But we might want to show a summary if multiple are running.
    // For now, Executor updates notification with specific task info.
    // If we want a summary, we'd need to coordinate.
    // BackgroundDownloadService mostly let the individual task update the notification.
  }

  Future<void> _showReadyNotification() async {
    final completedCount = _queueService.tasks
        .where((t) => t.status == DownloadStatus.completed)
        .length;
    final totalCount = _queueService.tasks.length;

    await _notificationManager.show(
      'SwiftSave',
      'Ready to download ($completedCount/$totalCount completed)',
    );
  }

  void _checkIdle() {
    final hasPending = _queueService.tasks.any(
      (t) =>
          t.status == DownloadStatus.idle ||
          t.status == DownloadStatus.downloading,
    );

    if (!hasPending && _activeDownloads == 0) {
      _lifecycleManager.startIdleTimer(
        isIdle: () =>
            _activeDownloads == 0 &&
            !_queueService.tasks.any((t) => t.status == DownloadStatus.idle),
        onStop: () async {
          // Hook for future cleanup if needed.
        },
      );
    }
  }

  void _notifyUi(String taskId, DownloadStatus status, {String? errorMessage}) {
    _uiCallback?.call('update', {
      'taskId': taskId,
      'status': status.index,
      'errorMessage': ?errorMessage,
    });
  }
}
