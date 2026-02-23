enum DownloadStatus {
  idle,
  fetching,
  ready,
  downloading,
  completed,
  error,
  cancelled, // Added for cancel functionality
}

class DownloadState {
  final DownloadStatus status;
  final String? errorMessage;
  final double progress;
  final String? filename;

  DownloadState({
    required this.status,
    this.errorMessage,
    this.progress = 0.0,
    this.filename,
  });

  DownloadState copyWith({
    DownloadStatus? status,
    String? errorMessage,
    double? progress,
    String? filename,
  }) {
    return DownloadState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      progress: progress ?? this.progress,
      filename: filename ?? this.filename,
    );
  }

  bool get isLoading =>
      status == DownloadStatus.fetching || status == DownloadStatus.downloading;
  bool get hasError => status == DownloadStatus.error;
  bool get isCompleted => status == DownloadStatus.completed;
}
