import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/di/service_locator.dart';
import '../core/interfaces/i_download_engine.dart';
import '../core/interfaces/i_queue_repository.dart';
import '../services/cookie_service.dart';
import '../services/download_path_service.dart';
import '../services/settings_service.dart';
import '../services/url_validator_service.dart';
import '../services/file_opener_service.dart';
import '../models/download_task.dart';
import '../models/download_status.dart';
import '../models/media_info.dart';
import '../models/media_type.dart';
import '../widgets/simple_download_button.dart';

class DownloadDecision {
  final bool handledExternally;
  final String formatId;
  final MediaType mediaType;
  final bool downloadAllGallery;
  final List<int>? selectedIndices;

  const DownloadDecision({
    this.handledExternally = false,
    required this.formatId,
    required this.mediaType,
    this.downloadAllGallery = true,
    this.selectedIndices,
  });
}

class HomeViewModel extends ChangeNotifier {
  final IQueueRepository _queueRepository;
  final IDownloadEngine _downloadEngine;

  // Stream subscription for progress updates
  StreamSubscription<DownloadTask>? _progressSubscription;

  HomeViewModel({
    IQueueRepository? queueRepository,
    IDownloadEngine? downloadEngine,
  }) : _queueRepository = queueRepository ?? getIt<IQueueRepository>(),
       _downloadEngine = downloadEngine ?? getIt<IDownloadEngine>();

  // State
  DownloadButtonState _buttonState = DownloadButtonState.empty;
  DownloadButtonState get buttonState => _buttonState;

  String? _fetchedTitle;
  String? get fetchedTitle => _fetchedTitle;

  String? _fetchedThumbnail;
  String? get fetchedThumbnail => _fetchedThumbnail;

  String? _errorHint;
  String? get errorHint => _errorHint;

  double _progress = 0.0;
  double get progress => _progress;

  String? _lastTaskId;
  String? get lastTaskId => _lastTaskId;

  // Track the current URL to manage button state
  String _currentUrl = '';

  void onUrlChanged(String url) {
    final trimmed = url.trim();
    if (_currentUrl == trimmed) return;

    _currentUrl = trimmed;
    if (_currentUrl.isEmpty) {
      _buttonState = DownloadButtonState.empty;
      _fetchedTitle = null;
      _fetchedThumbnail = null;
      _errorHint = null;
    } else if (_buttonState == DownloadButtonState.empty ||
        _buttonState == DownloadButtonState.error ||
        _buttonState == DownloadButtonState.complete) {
      // Only reset to ready if we're not currently busy
      if (_buttonState != DownloadButtonState.fetching &&
          _buttonState != DownloadButtonState.downloading) {
        _buttonState = DownloadButtonState.ready;
        _errorHint = null;
      }
    }
    notifyListeners();
  }

  void resetState() {
    _currentUrl = '';
    _buttonState = DownloadButtonState.empty;
    _fetchedTitle = null;
    _fetchedThumbnail = null;
    _lastTaskId = null;
    _progress = 0.0;
    _errorHint = null;
    notifyListeners();
  }

  Future<void> startDownload(
    String url, {
    required Future<DownloadDecision?> Function(MediaInfo) onChooseOption,
  }) async {
    final validation = UrlValidatorService.validate(url);
    if (!validation.isValid) {
      _buttonState = DownloadButtonState.error;
      _errorHint = validation.errorMessage ?? 'Paste a valid link';
      notifyListeners();
      return;
    }

    _buttonState = DownloadButtonState.fetching;
    _errorHint = null;
    notifyListeners();

    try {
      final cookieFile = await CookieService.getCookieFile();
      final mediaInfo = await _downloadEngine.getMediaInfo(
        url,
        cookieFile: cookieFile,
      );

      if (mediaInfo == null) {
        _buttonState = DownloadButtonState.error;
        _errorHint = 'Could not find video';
        notifyListeners();
        return;
      }

      _fetchedTitle = mediaInfo.title;
      _fetchedThumbnail = mediaInfo.thumbnail;
      notifyListeners();

      final decision = await onChooseOption(mediaInfo);
      if (decision == null) {
        _buttonState = DownloadButtonState.ready;
        notifyListeners();
        return;
      }

      if (decision.handledExternally) {
        _buttonState = DownloadButtonState.ready;
        notifyListeners();
        return;
      }

      final preferredPath = await SettingsService.instance.getDownloadPath();
      final downloadPath =
          await DownloadPathService.resolvePreferredDownloadPath(preferredPath);

      final task = DownloadTask(
        url: url,
        title: mediaInfo.title,
        thumbnail: mediaInfo.thumbnail,
        formatId: decision.formatId,
        outputPath: downloadPath,
        status: DownloadStatus.idle,
        mediaType: decision.mediaType,
        selectedIndices: decision.downloadAllGallery
            ? null
            : decision.selectedIndices,
        totalItems: mediaInfo.itemCount,
        cookieFile: cookieFile,
      );

      await _queueRepository.addTask(task);

      _buttonState = DownloadButtonState.downloading;
      _progress = 0.0;
      _lastTaskId = task.id;
      notifyListeners();

      _listenToProgress(task.id);
    } catch (e) {
      _buttonState = DownloadButtonState.error;
      _errorHint = _getSimpleErrorMessage(e.toString());
      notifyListeners();
    }
  }

  void _listenToProgress(String taskId) {
    // Cancel any existing subscription
    _progressSubscription?.cancel();

    // Use the stream from QueueRepository instead of polling
    _progressSubscription = _queueRepository
        .watchTask(taskId)
        .listen(
          (task) {
            // Check if this VM instance is still tracking this task
            if (_lastTaskId != taskId) {
              _progressSubscription?.cancel();
              return;
            }

            _progress = task.progress;

            if (task.status == DownloadStatus.completed) {
              _buttonState = DownloadButtonState.complete;
              _progressSubscription?.cancel();
              notifyListeners();
              return;
            }

            if (task.status == DownloadStatus.error ||
                task.status == DownloadStatus.cancelled) {
              _buttonState = DownloadButtonState.error;
              _errorHint = task.errorMessage ?? 'Download failed';
              _progressSubscription?.cancel();
              notifyListeners();
              return;
            }

            // Update UI with progress
            notifyListeners();
          },
          onError: (error) {
            _buttonState = DownloadButtonState.error;
            _errorHint = 'Connection lost';
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  void openDownloadedFile() {
    final taskId = _lastTaskId;
    if (taskId == null) return;

    // Use a fire-and-forget approach or return Future.
    // Since we need to show UI messages (Snackbars), maybe we should return the result/error string?
    // Or better, let the View handle the "how" of showing the error, VM just provides the logic.
    // But FileOpenerService is UI-agnostic mostly.

    // We need to find the task first.
    _queueRepository.getAllTasks().then((tasks) {
      final task = tasks.cast<DownloadTask?>().firstWhere(
        (t) => t?.id == taskId,
        orElse: () => null,
      );

      final filePath = task?.primaryFilePath;

      if (filePath == null || filePath.isEmpty) {
        // We can't show snackbar from here easily without context.
        // We could expose an error stream or callback.
        // For now, let's assume the view handles success/failure if we return a status.
        return;
      }

      FileOpenerService.openAndScan(filePath).then((result) {
        if (!FileOpenerService.isSuccess(result)) {
          // Should notify view of error
        }
      });

      // Reset state for next download
      resetState();
    });
  }

  // Helper to open file and return error message if any
  Future<String?> openLastFile() async {
    final taskId = _lastTaskId;
    if (taskId == null) return 'Download not found';

    final tasks = await _queueRepository.getAllTasks();
    final task = tasks.cast<DownloadTask?>().firstWhere(
      (t) => t?.id == taskId,
      orElse: () => null,
    );

    final filePath = task?.primaryFilePath;

    if (filePath == null || filePath.isEmpty) {
      return 'File location unknown';
    }

    final result = await FileOpenerService.openAndScan(filePath);
    if (!FileOpenerService.isSuccess(result)) {
      return FileOpenerService.getErrorMessage(result);
    }

    // Success - reset state
    resetState();
    return null;
  }

  String _getSimpleErrorMessage(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('duplicate download') ||
        lower.contains('already exists in queue')) {
      return 'Already in queue';
    }
    if (lower.contains('login') || lower.contains('sign in')) {
      return 'Login required';
    }
    if (lower.contains('private')) {
      return 'Video is private';
    }
    if (lower.contains('not found') || lower.contains('404')) {
      return 'Video not found';
    }
    if (lower.contains('region') || lower.contains('geo')) {
      return 'Not available here';
    }
    if (lower.contains('live')) {
      return 'Live streams not supported';
    }
    return 'Something went wrong';
  }
}
