import 'dart:async';
import 'dart:io';

import '../../models/download_status.dart';
import '../../models/download_task.dart';
import 'connectivity_monitor.dart';
import 'notification_manager.dart';
import '../download_path_service.dart';
import '../engine/download_engine_provider.dart';
import '../ffmpeg_service.dart';
import '../flutter_ffmpeg_service.dart';
import '../python_service.dart';
import '../queue_service.dart';
import '../settings_service.dart';
import '../../utils/app_logger.dart';

class DownloadExecutor {
  final NotificationManager _notificationManager;
  final ConnectivityMonitor _connectivityMonitor;
  final void Function(String method, Map<String, dynamic> args)? _uiCallback;

  DownloadExecutor({
    required NotificationManager notificationManager,
    required ConnectivityMonitor connectivityMonitor,
    void Function(String method, Map<String, dynamic> args)? uiCallback,
  }) : _notificationManager = notificationManager,
       _connectivityMonitor = connectivityMonitor,
       _uiCallback = uiCallback;

  /// Execute a single download task
  Future<void> execute(DownloadTask task) async {
    final String taskId = task.id;

    // Check network availability before starting
    if (!_connectivityMonitor.isNetworkAvailable) {
      AppLogger.debug('[DownloadExecutor] No network, deferring task: $taskId');
      task.status = DownloadStatus.idle;
      task.errorMessage = 'Waiting for network connection';
      await QueueService.instance.updateTask(task);
      _notifyUi(
        taskId,
        DownloadStatus.idle,
        errorMessage: 'Waiting for network connection',
      );
      return;
    }

    // Update notification
    await _notificationManager.show(
      'Downloading ${task.title}',
      'Starting download...',
    );

    final settings = SettingsService(); // Singleton

    try {
      AppLogger.section(
        'Starting download for task: $taskId',
        tag: 'DownloadExecutor',
      );
      AppLogger.debug('URL: ${task.url}');
      AppLogger.debug('Format: ${task.formatId}');
      AppLogger.debug('Output: ${task.outputPath}');

      // Get FFmpeg configuration and quality settings
      final ffmpeg = FFmpegService.instance;

      // Determine max quality based on network type
      final isOnWifi = await _connectivityMonitor.isPreferredNetworkAvailable();
      final maxQuality = settings.getMaxQualityForNetwork(isOnWifi);

      // Execute download (supports all media types)
      final result = await DownloadEngineProvider.instance.downloadMedia(
        url: task.url,
        outputPath: task.outputPath,
        formatId: task.formatId,
        taskId: task.id,
        mediaType: task.mediaType,
        cookieFile: task.cookieFile,
        downloadAllGallery: task.selectedIndices == null,
        selectedIndices: task.selectedIndices,
        ffmpegPath: ffmpeg.ffmpegPath,
        maxQuality: maxQuality,
        sleepInterval: settings.sleepInterval,
        concurrentFragments: settings.concurrentFragments,
        customUserAgent: settings.customUserAgent,
        proxyUrl: settings.proxyUrl,
        embedSubtitles: settings.embedSubtitles,
        subtitleLanguage: settings.subtitleLanguage,
      );

      AppLogger.debug('[DownloadExecutor] Download SUCCESS for task: $taskId');

      // Check if we need to merge video+audio on Android using FFmpegKit
      String? mergedFilename;
      if (Platform.isAndroid && FFmpegService.instance.useFlutterFFmpeg) {
        mergedFilename = await _tryMergeVideoAudio(result, task);
      }

      // Update success
      task.status = DownloadStatus.completed;

      // Use merged filename if available (from FFmpegKit merge)
      if (mergedFilename != null) {
        task.filename = mergedFilename;
        task.filenames = [mergedFilename];
        task.downloadedItems = 1;
      } else if (result['filenames'] is List) {
        task.filenames = (result['filenames'] as List)
            .map((e) => e.toString())
            .toList();
        task.downloadedItems = task.filenames?.length ?? 0;
        task.filename = task.filenames?.isNotEmpty == true
            ? task.filenames!.first
            : null;
      } else {
        task.filename = result['filename'] as String?;
      }
      task.progress = 1.0;
      await QueueService.instance.updateTask(task);

      // Save to MediaStore if Android 10+ so file is user-accessible
      if (settings.saveToGallery) {
        try {
          final requiresMediaStore =
              await DownloadPathService.requiresMediaStore();
          if (requiresMediaStore) {
            final filesToSave =
                task.filenames != null && task.filenames!.isNotEmpty
                ? task.filenames!
                : task.filename != null
                ? [task.filename!]
                : <String>[];

            for (final filePath in filesToSave) {
              final fileName = filePath.split('/').last;
              AppLogger.debug('Saving to MediaStore: $fileName');
              final success = await DownloadEngineProvider.instance
                  .saveToMediaStore(filePath: filePath, fileName: fileName);
              if (!success) {
                AppLogger.error('Failed to save file to MediaStore: $fileName');
              }
            }
          }
        } catch (e) {
          AppLogger.error('MediaStore save error', error: e);
          // Don't fail the download if MediaStore save fails
        }
      }

      final completedFilePath = task.primaryFilePath;
      if (completedFilePath != null && completedFilePath.isNotEmpty) {
        await NotificationManager.showCompletionNotification(
          title: 'Download complete',
          body: task.title,
          filePath: completedFilePath,
        );
      }

      await _notificationManager.show('Download Complete', task.title);
    } catch (e, stackTrace) {
      AppLogger.section(
        'Download FAILED for task: $taskId',
        tag: 'DownloadExecutor',
      );
      AppLogger.error(
        'Error during download',
        error: e,
        stackTrace: stackTrace,
      );

      if (e is DownloadCancelledException) {
        task.status = DownloadStatus.cancelled;
        task.errorMessage = 'Cancelled by user';
        await QueueService.instance.updateTask(task);

        await _notificationManager.show('Download Cancelled', task.title);
        return;
      }

      // Check if error is retryable (network/timeout errors)
      final errorStr = e.toString().toLowerCase();
      final isRetryable =
          errorStr.contains('timeout') ||
          errorStr.contains('connection') ||
          errorStr.contains('network') ||
          errorStr.contains('socket') ||
          errorStr.contains('failed to connect');

      const maxRetries = 5;

      if (isRetryable &&
          settings.autoRetryFailed &&
          task.retryCount < maxRetries) {
        // Calculate exponential backoff: 2^retryCount * 5 seconds (max 300s)
        final backoffSeconds = (1 << task.retryCount) * 5; // 5, 10, 20, 40, 80
        final cappedBackoff = backoffSeconds > 300 ? 300 : backoffSeconds;

        AppLogger.debug(
          '[DownloadExecutor] Retry attempt ${task.retryCount + 1}/$maxRetries after ${cappedBackoff}s',
        );

        // Update retry tracking
        task.retryCount++;
        task.lastRetryTime = DateTime.now();
        // Keep task out of idle queue until backoff completes.
        task.status = DownloadStatus.fetching;
        task.errorMessage =
            'Retrying in ${cappedBackoff}s (${task.retryCount}/$maxRetries)...';
        await QueueService.instance.updateTask(task);

        // Schedule retry after backoff delay without blocking the executor slot.
        unawaited(
          Future<void>.delayed(Duration(seconds: cappedBackoff), () async {
            final t = await QueueService.instance.getTask(taskId);
            // Only transition tasks that are still waiting for retry.
            if (t != null && t.status == DownloadStatus.fetching) {
              t.status = DownloadStatus.idle;
              t.errorMessage = null;
              await QueueService.instance.updateTask(t);
              // This update will trigger QueueService listeners, which Orchestrator should listen to.
            }
          }),
        );

        await _notificationManager.show(
          'Download Failed - Retrying',
          '${task.title} (${task.retryCount}/$maxRetries)',
        );
      } else {
        // Max retries exceeded or non-retryable error
        task.status = DownloadStatus.error;
        task.errorMessage = isRetryable
            ? 'Max retries exceeded: ${e.toString()}'
            : e.toString();
        task.retryCount = 0; // Reset for storage errors
        await QueueService.instance.updateTask(task);

        await _notificationManager.show('Download Failed', task.title);
      }
    } finally {
      // Notify UI of final state (or current state)
      _notifyUi(
        taskId,
        task.status,
        filename: task.filename,
        errorMessage: task.errorMessage,
      );
    }
  }

  void _notifyUi(
    String taskId,
    DownloadStatus status, {
    String? filename,
    String? errorMessage,
  }) {
    _uiCallback?.call('update', {
      'taskId': taskId,
      'status': status.index,
      'filename': ?filename,
      'errorMessage': ?errorMessage,
    });
  }

  /// Try to merge separate video and audio files using FFmpegKit
  Future<String?> _tryMergeVideoAudio(
    Map<String, dynamic> result,
    DownloadTask task,
  ) async {
    try {
      final flutterFFmpeg = FlutterFFmpegService.instance;
      if (!flutterFFmpeg.isAvailable) {
        AppLogger.debug(
          '[DownloadExecutor] FlutterFFmpeg not available for merge',
        );
        return null;
      }

      final String? videoFile = result['video_file'] as String?;
      final String? audioFile = result['audio_file'] as String?;

      if (videoFile == null || audioFile == null) {
        return null;
      }

      if (!File(videoFile).existsSync() || !File(audioFile).existsSync()) {
        AppLogger.warning(
          '[DownloadExecutor] Video or audio file missing, skipping merge',
        );
        return null;
      }

      AppLogger.debug(
        '[DownloadExecutor] Merging video and audio with FFmpegKit',
      );

      await _notificationManager.show('Merging video and audio...', task.title);

      final videoFileName = videoFile.split('/').last;
      final baseName = videoFileName.replaceAll(RegExp(r'\.[^.]+$'), '');
      final outputPath = '${task.outputPath}/${baseName}_merged.mp4';

      final mergedPath = await flutterFFmpeg.mergeVideoAudio(
        videoPath: videoFile,
        audioPath: audioFile,
        outputPath: outputPath,
        onProgress: (progress) {
          _notificationManager.show(
            'Merging... ${(progress * 100).toStringAsFixed(0)}%',
            task.title,
          );
        },
      );

      AppLogger.debug('[DownloadExecutor] Merge successful: $mergedPath');
      await flutterFFmpeg.cleanupTempFiles(videoFile, audioFile);

      return mergedPath;
    } catch (e) {
      AppLogger.error('[DownloadExecutor] FFmpegKit merge failed', error: e);
      return null;
    }
  }
}
