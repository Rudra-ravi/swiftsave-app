class DownloadProgressEvent {
  final String taskId;
  final double? progress;
  final String? speed;
  final String? eta;
  final int? downloadedBytes;
  final int? totalBytes;
  final int? itemIndex;
  final int? itemCount;

  const DownloadProgressEvent({
    required this.taskId,
    required this.progress,
    this.speed,
    this.eta,
    this.downloadedBytes,
    this.totalBytes,
    this.itemIndex,
    this.itemCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      if (progress != null) 'progress': progress,
      if (speed != null) 'speed': speed,
      if (eta != null) 'eta': eta,
      if (downloadedBytes != null) 'downloadedBytes': downloadedBytes,
      if (totalBytes != null) 'totalBytes': totalBytes,
      if (itemIndex != null) 'itemIndex': itemIndex,
      if (itemCount != null) 'itemCount': itemCount,
    };
  }
}
