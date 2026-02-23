import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/download_status.dart';
import '../models/download_task.dart';
import '../services/queue_service.dart';
import '../services/file_opener_service.dart';
import '../services/settings_service.dart';

enum QueueFilter { all, active, completed, errors }

enum QueueSort { newest, oldest, status }

class QueueViewModel extends ChangeNotifier {
  final QueueService _queueService;
  final SettingsService _settingsService;

  String _searchQuery = '';
  QueueFilter _filter = QueueFilter.all;
  QueueSort _sort = QueueSort.status;

  QueueViewModel({
    QueueService? queueService,
    SettingsService? settingsService,
  }) : _queueService = queueService ?? QueueService.instance,
       _settingsService = settingsService ?? SettingsService.instance {
    _queueService.addListener(_onQueueChanged);
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _queueService.removeListener(_onQueueChanged);
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onQueueChanged() {
    notifyListeners();
  }

  void _onSettingsChanged() {
    notifyListeners();
  }

  String get searchQuery => _searchQuery;
  QueueFilter get filter => _filter;
  QueueSort get sort => _sort;

  bool get queuePaused => _settingsService.queuePaused;

  /// Get sorted and filtered tasks for the queue screen.
  List<DownloadTask> get filteredTasks {
    final query = _searchQuery.trim().toLowerCase();

    bool matchesFilter(DownloadTask task) {
      switch (_filter) {
        case QueueFilter.all:
          return true;
        case QueueFilter.active:
          return task.status == DownloadStatus.downloading ||
              task.status == DownloadStatus.fetching ||
              task.status == DownloadStatus.idle ||
              task.status == DownloadStatus.ready;
        case QueueFilter.completed:
          return task.status == DownloadStatus.completed;
        case QueueFilter.errors:
          return task.status == DownloadStatus.error ||
              task.status == DownloadStatus.cancelled;
      }
    }

    bool matchesQuery(DownloadTask task) {
      if (query.isEmpty) return true;
      return task.title.toLowerCase().contains(query) ||
          task.url.toLowerCase().contains(query);
    }

    final tasks = _queueService.tasks
        .where((t) => matchesFilter(t) && matchesQuery(t))
        .toList();

    int statusOrder(DownloadStatus status) {
      switch (status) {
        case DownloadStatus.downloading:
          return 0;
        case DownloadStatus.fetching:
          return 1;
        case DownloadStatus.ready:
          return 2;
        case DownloadStatus.idle:
          return 3;
        case DownloadStatus.completed:
          return 4;
        case DownloadStatus.error:
          return 5;
        case DownloadStatus.cancelled:
          return 6;
      }
    }

    tasks.sort((a, b) {
      switch (_sort) {
        case QueueSort.newest:
          return b.createdDate.compareTo(a.createdDate);
        case QueueSort.oldest:
          return a.createdDate.compareTo(b.createdDate);
        case QueueSort.status:
          final statusCompare = statusOrder(a.status).compareTo(
            statusOrder(b.status),
          );
          if (statusCompare != 0) return statusCompare;
          return b.createdDate.compareTo(a.createdDate);
      }
    });

    return tasks;
  }

  int get totalTasks => _queueService.tasks.length;

  int get activeCount => _queueService.tasks
      .where(
        (t) =>
            t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.fetching,
      )
      .length;

  int get completedCount => _queueService.tasks
      .where((t) => t.status == DownloadStatus.completed)
      .length;

  int get errorCount => _queueService.tasks
      .where(
        (t) =>
            t.status == DownloadStatus.error ||
            t.status == DownloadStatus.cancelled,
      )
      .length;

  bool get hasCompleted =>
      _queueService.tasks.any((t) => t.status == DownloadStatus.completed);
  bool get hasErrors => errorCount > 0;

  /// Force refresh (for pull-to-refresh)
  void refresh() {
    notifyListeners();
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  void setFilter(QueueFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  void setSort(QueueSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  Future<void> pauseQueue() async {
    await _queueService.pauseQueue();
    notifyListeners();
  }

  Future<void> resumeQueue() async {
    await _queueService.resumeQueue();
    notifyListeners();
  }

  Future<void> cancelTask(String taskId) async {
    await _queueService.cancelTask(taskId);
  }

  Future<void> retryTask(String taskId) async {
    await _queueService.retryTask(taskId);
  }

  Future<void> retryAllErrors() async {
    await _queueService.retryAllErrors();
    notifyListeners();
  }

  Future<int> clearCompleted() async {
    return await _queueService.clearCompleted();
  }

  Future<int> clearErrors() async {
    final removed = await _queueService.clearErrors();
    notifyListeners();
    return removed;
  }

  /// Opens the file. Returns an error message if failed, or null if success.
  Future<String?> openFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      return 'File location unknown';
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return 'File not found. Check your Downloads folder.';
    }

    final result = await FileOpenerService.openAndScan(filePath);
    if (!FileOpenerService.isSuccess(result)) {
      return FileOpenerService.getErrorMessage(result);
    }

    return null;
  }
}
