import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/interfaces/i_queue_repository.dart';
import '../models/download_task.dart';
import '../models/download_status.dart';
import '../models/media_type.dart';
import 'background_service.dart';
import 'download/connectivity_monitor.dart';
import 'download/download_executor.dart';
import 'download/notification_manager.dart';
import 'engine/download_engine_provider.dart';
import 'file_opener_service.dart';
import 'settings_service.dart';
import '../utils/app_logger.dart';

class QueueService extends ChangeNotifier implements IQueueRepository {
  static QueueService? _instance;

  static QueueService get instance {
    _instance ??= QueueService._internal();
    return _instance!;
  }

  // Factory for backward compatibility
  factory QueueService() => instance;

  QueueService._internal();

  List<DownloadTask> _tasks = [];
  final Map<String, DownloadTask> _taskMap = {};
  static const String _storageKey = 'download_queue';
  Timer? _saveDebounceTimer;
  bool _savePending = false;
  bool _isInitialized = false;
  bool _serviceBridgeEnabled = true;
  DateTime? _lastNotifyTime;
  static const Duration _minNotifyInterval = Duration(milliseconds: 100);

  // Store stream subscriptions to properly cancel them
  StreamSubscription<Map<String, dynamic>?>? _progressSubscription;
  StreamSubscription<Map<String, dynamic>?>? _updateSubscription;
  StreamSubscription<dynamic>? _desktopProgressSubscription;
  bool _desktopProcessing = false;

  final _taskUpdatesController = StreamController<DownloadTask>.broadcast();

  bool get _useBackgroundService => Platform.isAndroid || Platform.isIOS;

  @override
  Stream<DownloadTask> get taskUpdates => _taskUpdatesController.stream;

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  @override
  Future<List<DownloadTask>> getAllTasks() async => List.unmodifiable(_tasks);

  @override
  Future<List<DownloadTask>> getActiveTasks() async {
    return _tasks
        .where(
          (t) =>
              t.status == DownloadStatus.fetching ||
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.idle ||
              t.status == DownloadStatus.ready,
        )
        .toList();
  }

  // Getter for backward compatibility
  List<DownloadTask> get activeTasks => _tasks
      .where(
        (t) =>
            t.status == DownloadStatus.fetching ||
            t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.idle ||
            t.status == DownloadStatus.ready,
      )
      .toList();

  @override
  Future<List<DownloadTask>> getCompletedTasks({
    int limit = 50,
    int offset = 0,
  }) async {
    final completed = _tasks
        .where((t) => t.status == DownloadStatus.completed)
        .toList();
    // Sort by completion time or creation time descending (assuming newer is better for UI)
    completed.sort((a, b) => b.createdDate.compareTo(a.createdDate));

    if (offset >= completed.length) return [];
    final end = (offset + limit < completed.length)
        ? offset + limit
        : completed.length;
    return completed.sublist(offset, end);
  }

  // Getter for backward compatibility
  List<DownloadTask> get completedTasks =>
      _tasks.where((t) => t.status == DownloadStatus.completed).toList();

  /// Returns true if service is ready to accept operations
  bool get isInitialized => _isInitialized;

  /// Enable/disable forwarding queue mutations back to background service.
  /// Background isolate should disable this to avoid invoke loops.
  void setServiceBridgeEnabled(bool enabled) {
    _serviceBridgeEnabled = enabled;
  }

  /// Rate-limited notifyListeners to prevent UI jank from rapid updates
  void _throttledNotify() {
    final now = DateTime.now();
    if (_lastNotifyTime == null ||
        now.difference(_lastNotifyTime!) >= _minNotifyInterval) {
      _lastNotifyTime = now;
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadQueue();
    _setupServiceListener();
    _isInitialized = true;
  }

  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // SharedPreferences keeps per-isolate caches; force reload to avoid
      // stale queue reads when background isolate updates storage.
      await prefs.reload();
      final String? jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
        _tasks = jsonList
            .map(
              (dynamic j) => DownloadTask.fromJson(j as Map<String, dynamic>),
            )
            .toList();
        _taskMap.clear();
        for (var task in _tasks) {
          _taskMap[task.id] = task;
        }
        await _verifyCompletedFiles();
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error loading queue', error: e);
    }
  }

  Future<void> _verifyCompletedFiles() async {
    final completedTasks = _tasks
        .where((t) => t.status == DownloadStatus.completed)
        .toList();

    if (completedTasks.isEmpty) return;

    final results = await Future.wait(
      completedTasks.map((task) async {
        bool taskChanged = false;

        if (task.mediaType == MediaType.gallery ||
            task.mediaType == MediaType.mixed) {
          final files = task.filenames ?? <String>[];
          if (files.isEmpty) {
            task.status = DownloadStatus.error;
            task.errorMessage = 'Downloaded files not found';
            task.progress = 0.0;
            taskChanged = true;
            _taskUpdatesController.add(task);
            return true;
          }

          final fileExistence = await Future.wait(
            files.map((path) => File(path).exists()),
          );

          int existingCount = 0;
          int missingCount = 0;

          for (final exists in fileExistence) {
            if (exists) {
              existingCount++;
            } else {
              missingCount++;
            }
          }

          task.downloadedItems = existingCount;
          if (missingCount > 0) {
            task.status = DownloadStatus.error;
            task.errorMessage =
                'Missing $missingCount of ${files.length} files';
            task.progress = 0.0;
            taskChanged = true;
            _taskUpdatesController.add(task);
          }
        } else {
          final filePath = task.filename;
          if (filePath == null || !await File(filePath).exists()) {
            task.status = DownloadStatus.error;
            task.errorMessage = 'Downloaded file not found';
            task.progress = 0.0;
            taskChanged = true;
            _taskUpdatesController.add(task);
          }
        }
        return taskChanged;
      }),
    );

    if (results.contains(true)) {
      await _saveQueue();
    }
  }

  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(_tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
      _savePending = false;
    } catch (e) {
      AppLogger.error('Error saving queue', error: e);
    }
  }

  void _scheduleSave() {
    _savePending = true;
    _saveDebounceTimer ??= Timer(const Duration(seconds: 2), () async {
      if (_savePending) {
        await _saveQueue();
        _savePending = false;
      }
      _saveDebounceTimer = null;
    });
  }

  void _setupServiceListener() {
    // Cancel existing subscriptions if any
    _progressSubscription?.cancel();
    _updateSubscription?.cancel();
    _desktopProgressSubscription?.cancel();

    if (!_useBackgroundService) {
      _desktopProgressSubscription = DownloadEngineProvider
          .instance
          .progressStream
          .listen(
            (event) {
              if (event is! Map) return;
              _handleProgressEvent(Map<String, dynamic>.from(event));
            },
            onError: (Object error) {
              AppLogger.error('Desktop progress stream error', error: error);
            },
          );
      return;
    }

    final service = FlutterBackgroundService();

    _progressSubscription = service
        .on('progress')
        .listen(
          (event) {
            if (event == null) return;
            _handleProgressEvent(Map<String, dynamic>.from(event));
          },
          onError: (Object error) {
            AppLogger.error('Progress stream error', error: error);
          },
        );

    _updateSubscription = service
        .on('update')
        .listen(
          (event) {
            if (event == null) return;
            _handleUpdateEvent(Map<String, dynamic>.from(event));
          },
          onError: (Object error) {
            AppLogger.error('Update stream error', error: error);
          },
        );
  }

  void _handleProgressEvent(Map<String, dynamic> event) {
    final String taskId = event['taskId'] as String;
    final dynamic progressValue = event['progress'];
    final dynamic downloadedBytesValue = event['downloadedBytes'];
    final dynamic totalBytesValue = event['totalBytes'];
    final dynamic itemIndexValue = event['itemIndex'];
    final bool indeterminate = event['indeterminate'] == true;
    final String? speed = event['speed'] as String?;
    final String? eta = event['eta'] as String?;

    double? progress;
    if (progressValue is num) {
      progress = progressValue.toDouble();
    } else if (progressValue is String) {
      progress = double.tryParse(progressValue);
    }

    int? asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    final int? downloadedBytes = asInt(downloadedBytesValue);
    final int? totalBytes = asInt(totalBytesValue);
    final int? itemIndex = asInt(itemIndexValue);

    final task = _taskMap[taskId];
    if (task != null) {
      final now = DateTime.now();
      final previousProgress = task.progress;
      task.progress = (progress ?? 0.0).clamp(0.0, 1.0);
      task.speed = speed;
      task.eta = eta;
      task.downloadedBytes = downloadedBytes;
      task.totalBytes = totalBytes;
      task.progressIndeterminate = indeterminate;
      if (itemIndex != null && itemIndex > task.downloadedItems) {
        task.downloadedItems = itemIndex;
      }
      task.status = DownloadStatus.downloading;

      _taskUpdatesController.add(task);

      final lastNotify = task.lastProgressUpdate;
      final progressForDelta = progress ?? previousProgress;
      final progressDelta = (progressForDelta - previousProgress).abs();
      final shouldNotify =
          lastNotify == null ||
          now.difference(lastNotify).inMilliseconds > 300 ||
          progressDelta >= 0.01;

      if (shouldNotify) {
        task.lastProgressUpdate = now;
        _throttledNotify();
        _scheduleSave();
      }
    }
  }

  void _handleUpdateEvent(Map<String, dynamic> event) {
    final String taskId = event['taskId'] as String;
    final int statusIndex = event['status'] as int;
    final String? filename = event['filename'] as String?;
    final String? errorMessage = event['errorMessage'] as String?;

    final task = _taskMap[taskId];
    if (task != null) {
      task.status = DownloadStatus.values[statusIndex];
      if (filename != null) task.filename = filename;
      if (errorMessage != null) task.errorMessage = errorMessage;
      if (task.status == DownloadStatus.completed) {
        task.progress = 1.0;
        final files = task.filenames;
        final primaryFilename = task.filename;
        if (files != null && files.isNotEmpty) {
          for (final path in files) {
            FileOpenerService.scanFile(path);
          }
          if ((primaryFilename == null || primaryFilename.isEmpty)) {
            task.filename = files.first;
          }
        } else if (primaryFilename != null && primaryFilename.isNotEmpty) {
          FileOpenerService.scanFile(primaryFilename);
        }
      }

      _taskUpdatesController.add(task);
      notifyListeners();
      _scheduleSave();
    } else {
      _loadQueue();
    }
  }

  Future<void> _safeInvokeService(
    FlutterBackgroundService service,
    String method, [
    Map<String, dynamic>? payload,
  ]) async {
    if (!_useBackgroundService) return;
    if (!_serviceBridgeEnabled) return;
    try {
      if (!await service.isRunning()) return;
      service.invoke(method, payload);
    } on MissingPluginException catch (e) {
      AppLogger.warning(
        'Background service channel unavailable for $method: $e',
      );
    } catch (e) {
      AppLogger.warning('Failed to invoke background service $method: $e');
    }
  }

  @override
  Future<void> addTask(DownloadTask task) async {
    // Prevent duplicate inserts for the same task ID (common with
    // foreground/background isolate event bridging).
    final existingIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (existingIndex != -1) {
      _tasks[existingIndex] = task;
      _taskMap[task.id] = task;
      _taskUpdatesController.add(task);
      notifyListeners();
      await _saveQueue();
      return;
    }

    final shouldSkipDuplicates = SettingsService.instance.skipDuplicates;

    if (shouldSkipDuplicates) {
      final duplicate = _tasks.any(
        (existing) =>
            existing.id != task.id &&
            existing.url == task.url &&
            existing.mediaType == task.mediaType &&
            existing.formatId == task.formatId &&
            existing.status != DownloadStatus.error &&
            existing.status != DownloadStatus.cancelled,
      );

      if (duplicate) {
        throw StateError('Duplicate download already exists in queue');
      }
    }

    _tasks.add(task);
    _taskMap[task.id] = task;
    _taskUpdatesController.add(task);
    notifyListeners();
    await _saveQueue(); // Save after adding task

    if (!_useBackgroundService) {
      unawaited(_startDesktopProcessing());
      return;
    }

    final service = FlutterBackgroundService();
    // Ensure service is running
    if (!await service.isRunning()) {
      await BackgroundDownloadService.initialize();
      await service.startService();
    }

    await _safeInvokeService(service, 'addTask', task.toJson());
  }

  // Helper/Alias for IQueueRepository compatibility
  @override
  Future<void> deleteTask(String id) async {
    return removeTask(id);
  }

  Future<void> removeTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    _taskMap.remove(id);
    // Note: Can't emit deleted task easily as it's gone,
    // but listeners to the list will see it removed via notifyListeners.
    // Stream listeners might need a "deleted" event or just handling the list.
    // The IQueueRepository interface stream is Stream<DownloadTask>, which implies updates.
    // A deletion is hard to represent there unless we have a DeletedTask subclass or status.
    notifyListeners();
    await _saveQueue(); // Save after removing task

    final service = FlutterBackgroundService();
    await _safeInvokeService(service, 'removeTask', {'taskId': id});
  }

  @override
  Future<int> clearCompleted() async {
    final initialCount = _tasks.length;
    _tasks.removeWhere((t) => t.status == DownloadStatus.completed);
    // Also remove cancelled tasks when clearing
    _tasks.removeWhere((t) => t.status == DownloadStatus.cancelled);

    // Sync map
    _taskMap.removeWhere(
      (k, v) =>
          v.status == DownloadStatus.completed ||
          v.status == DownloadStatus.cancelled,
    );

    final removedCount = initialCount - _tasks.length;

    notifyListeners();
    await _saveQueue(); // Save after clearing completed

    final service = FlutterBackgroundService();
    await _safeInvokeService(service, 'clearCompleted');
    return removedCount;
  }

  Future<void> cancelTask(String id) async {
    final task = _taskMap[id];
    if (task != null) {
      task.status = DownloadStatus.cancelled;
      task.errorMessage = 'Cancelled by user';
      _taskUpdatesController.add(task);
      notifyListeners();
      await _saveQueue(); // Save after cancelling task

      final service = FlutterBackgroundService();
      await _safeInvokeService(service, 'cancelTask', {'taskId': id});
    }
  }

  Future<void> retryTask(String id) async {
    final task = _taskMap[id];
    if (task != null) {
      task.status = DownloadStatus.idle;
      task.errorMessage = null;
      task.retryCount = 0;
      task.lastRetryTime = null;
      // Keep progress if it was interrupted, reset if it was an error
      if (!task.wasInterrupted) {
        task.progress = 0.0;
        task.downloadedBytes = null;
        task.totalBytes = null;
        task.progressIndeterminate = false;
      }
      // Clear interrupted flag
      task.wasInterrupted = false;
      task.speed = null;
      task.eta = null;

      _taskUpdatesController.add(task);
      notifyListeners();
      await _saveQueue(); // Save after retrying task

      if (!_useBackgroundService) {
        unawaited(_startDesktopProcessing());
        return;
      }

      // Re-add to service to trigger processing
      final service = FlutterBackgroundService();
      if (!await service.isRunning()) {
        await BackgroundDownloadService.initialize();
        await service.startService();
      }

      // Use addTask to update/re-queue
      await _safeInvokeService(service, 'addTask', task.toJson());
    }
  }

  Future<void> retryAllErrors() async {
    final errorTasks = _tasks
        .where(
          (t) =>
              t.status == DownloadStatus.error ||
              t.status == DownloadStatus.cancelled ||
              (t.status == DownloadStatus.idle && t.wasInterrupted),
        )
        .toList();

    if (errorTasks.isEmpty) return;

    for (final task in errorTasks) {
      task.status = DownloadStatus.idle;
      task.errorMessage = null;
      task.retryCount = 0;
      task.lastRetryTime = null;
      if (!task.wasInterrupted) {
        task.progress = 0.0;
        task.downloadedBytes = null;
        task.totalBytes = null;
        task.progressIndeterminate = false;
      }
      task.wasInterrupted = false;
      task.speed = null;
      task.eta = null;
      _taskUpdatesController.add(task);
    }

    notifyListeners();
    _scheduleSave();

    if (!_useBackgroundService) {
      unawaited(_startDesktopProcessing());
      return;
    }

    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await BackgroundDownloadService.initialize();
      await service.startService();
    }

    for (final task in errorTasks) {
      await _safeInvokeService(service, 'addTask', task.toJson());
    }
  }

  Future<void> pauseQueue() async {
    await SettingsService.instance.setQueuePaused(true);
    final service = FlutterBackgroundService();
    await _safeInvokeService(service, 'pauseQueue');
    notifyListeners();
  }

  Future<void> resumeQueue() async {
    await SettingsService.instance.setQueuePaused(false);

    if (!_useBackgroundService) {
      unawaited(_startDesktopProcessing());
      notifyListeners();
      return;
    }

    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await BackgroundDownloadService.initialize();
      await service.startService();
    }
    await _safeInvokeService(service, 'resumeQueue');
    notifyListeners();
  }

  Future<void> _startDesktopProcessing() async {
    if (_useBackgroundService || _desktopProcessing) return;
    _desktopProcessing = true;

    final notificationManager = NotificationManager(null);
    final connectivityMonitor = ConnectivityMonitor(notificationManager);
    final executor = DownloadExecutor(
      notificationManager: notificationManager,
      connectivityMonitor: connectivityMonitor,
      uiCallback: (method, args) {
        if (method == 'update') {
          _handleUpdateEvent(args);
        }
      },
    );

    try {
      while (true) {
        final queuePaused = SettingsService.instance.queuePaused;
        if (queuePaused) break;

        DownloadTask? next;
        for (final task in _tasks) {
          if (task.status == DownloadStatus.idle) {
            next = task;
            break;
          }
        }
        if (next == null) break;

        next.status = DownloadStatus.downloading;
        await updateTask(next);
        await executor.execute(next);
      }
    } finally {
      _desktopProcessing = false;
    }
  }

  @override
  Future<int> clearErrors() async {
    final initialCount = _tasks.length;
    _tasks.removeWhere((t) => t.status == DownloadStatus.error);
    _taskMap.removeWhere((k, v) => v.status == DownloadStatus.error);
    final removedCount = initialCount - _tasks.length;
    notifyListeners();
    await _saveQueue();
    final service = FlutterBackgroundService();
    await _safeInvokeService(service, 'clearErrors');
    return removedCount;
  }

  // Implementation of missing IQueueRepository methods

  @override
  Future<void> updateTask(DownloadTask task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _taskMap[task.id] = task;
      _taskUpdatesController.add(task);
      notifyListeners();
      await _saveQueue();
    }
  }

  @override
  Future<DownloadTask?> getTask(String id) async {
    return _taskMap[id];
  }

  @override
  Future<List<DownloadTask>> getTasksByStatus(DownloadStatus status) async {
    return _tasks.where((t) => t.status == status).toList();
  }

  @override
  Future<int> getTaskCount(DownloadStatus status) async {
    return _tasks.where((t) => t.status == status).length;
  }

  @override
  Future<int> deleteOldCompleted({int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final initialCount = _tasks.length;

    _tasks.removeWhere(
      (t) =>
          t.status == DownloadStatus.completed &&
          t.createdDate.isBefore(cutoffDate),
    );

    _taskMap.removeWhere(
      (k, v) =>
          v.status == DownloadStatus.completed &&
          v.createdDate.isBefore(cutoffDate),
    );

    final removedCount = initialCount - _tasks.length;
    if (removedCount > 0) {
      notifyListeners();
      await _saveQueue();
    }
    return removedCount;
  }

  @override
  Stream<DownloadTask> watchTask(String taskId) {
    return _taskUpdatesController.stream.where((t) => t.id == taskId);
  }

  @override
  Future<void> reloadActiveCache() async {
    await _loadQueue();
  }

  @override
  Future<bool> isUrlQueued(String url) async {
    return _tasks.any((t) => t.url == url && !t.isCompleted && !t.hasError);
  }

  @override
  Future<void> batchUpdateTasks(List<DownloadTask> tasks) async {
    bool changed = false;
    for (final task in tasks) {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        _taskMap[task.id] = task;
        _taskUpdatesController.add(task);
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
      await _saveQueue();
    }
  }

  @override
  Future<Map<String, int>> getQueueStats() async {
    final stats = <String, int>{};
    for (final status in DownloadStatus.values) {
      stats[status.name] = _tasks.where((t) => t.status == status).length;
    }
    return stats;
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _progressSubscription?.cancel();
    _updateSubscription?.cancel();
    _desktopProgressSubscription?.cancel();
    _taskUpdatesController.close();
    super.dispose();
  }
}
