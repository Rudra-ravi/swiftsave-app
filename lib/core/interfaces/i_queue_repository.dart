import '../../models/download_task.dart';
import '../../models/download_status.dart';

/// Interface for download queue management
abstract class IQueueRepository {
  /// Stream of task updates for UI reactivity
  Stream<DownloadTask> get taskUpdates;

  /// Add a new task to the queue
  Future<void> addTask(DownloadTask task);

  /// Update an existing task
  Future<void> updateTask(DownloadTask task);

  /// Delete a task
  Future<void> deleteTask(String id);

  /// Get a specific task by ID
  Future<DownloadTask?> getTask(String id);

  /// Get all tasks
  Future<List<DownloadTask>> getAllTasks();

  /// Get active tasks (idle or downloading)
  Future<List<DownloadTask>> getActiveTasks();

  /// Get completed tasks with pagination
  Future<List<DownloadTask>> getCompletedTasks({
    int limit = 50,
    int offset = 0,
  });

  /// Get tasks by status
  Future<List<DownloadTask>> getTasksByStatus(DownloadStatus status);

  /// Get count of tasks by status
  Future<int> getTaskCount(DownloadStatus status);

  /// Clear all completed tasks
  Future<int> clearCompleted();

  /// Clear all error tasks
  Future<int> clearErrors();

  /// Delete old completed tasks
  Future<int> deleteOldCompleted({int daysOld = 30});

  /// Watch a specific task for updates
  Stream<DownloadTask> watchTask(String taskId);

  /// Reload active tasks cache from database
  Future<void> reloadActiveCache();

  /// Check if a URL is already queued
  Future<bool> isUrlQueued(String url);

  /// Batch update multiple tasks
  Future<void> batchUpdateTasks(List<DownloadTask> tasks);

  /// Get statistics about the queue
  Future<Map<String, int>> getQueueStats();

  /// Cleanup resources
  void dispose();
}
