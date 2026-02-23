import 'package:uuid/uuid.dart';
import '../utils/path_sanitizer.dart';
import 'download_status.dart';
import 'media_type.dart';

class DownloadTask {
  final String id;
  final String url;
  final String title;
  final String? thumbnail;
  final String formatId;
  final String outputPath;
  final DateTime createdDate;

  // NEW FIELDS for media support
  final MediaType mediaType;
  List<String>? filenames; // For gallery downloads (multiple files)
  final int? totalItems; // For galleries
  final String? cookieFile; // For authenticated downloads
  final List<int>? selectedIndices; // For gallery selection

  DownloadStatus status;
  double progress;
  String? filename;
  String? errorMessage;
  String? speed;
  String? eta;
  int? downloadedBytes;
  int? totalBytes;
  bool progressIndeterminate;
  DateTime? lastProgressUpdate; // Track when progress was last saved
  bool wasInterrupted; // Track if download was interrupted
  int downloadedItems; // Progress for galleries
  int retryCount; // Track retry attempts for exponential backoff
  DateTime? lastRetryTime; // Track when last retry was attempted

  DownloadTask({
    String? id,
    required this.url,
    required String title,
    this.thumbnail,
    required this.formatId,
    required this.outputPath,
    DateTime? createdDate,
    this.mediaType = MediaType.video, // Default to video for compatibility
    this.filenames,
    this.totalItems,
    this.cookieFile,
    this.selectedIndices,
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.filename,
    this.errorMessage,
    this.speed,
    this.eta,
    this.downloadedBytes,
    this.totalBytes,
    this.progressIndeterminate = false,
    this.lastProgressUpdate,
    this.wasInterrupted = false,
    this.downloadedItems = 0,
    this.retryCount = 0,
    this.lastRetryTime,
  }) : id = id ?? const Uuid().v4(),
       title = PathSanitizer.sanitizeFilename(
         title,
       ), // Sanitize title on creation
       createdDate = createdDate ?? DateTime.now();

  bool get isCompleted => status == DownloadStatus.completed;
  bool get hasError => status == DownloadStatus.error;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isPending =>
      status == DownloadStatus.idle || status == DownloadStatus.ready;

  // NEW getters for media type info
  bool get isGallery => mediaType == MediaType.gallery;
  bool get isImage => mediaType == MediaType.image;
  bool get isVideo => mediaType == MediaType.video;
  bool get isAudio => mediaType == MediaType.audio;
  String? get primaryFilePath {
    if (filename != null && filename!.isNotEmpty) {
      return filename;
    }
    if (filenames != null && filenames!.isNotEmpty) {
      return filenames!.first;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'thumbnail': thumbnail,
      'formatId': formatId,
      'outputPath': outputPath,
      'createdDate': createdDate.toIso8601String(),
      'mediaType': mediaType.name,
      'filenames': filenames,
      'totalItems': totalItems,
      'cookieFile': cookieFile,
      'selectedIndices': selectedIndices,
      'status': status.index,
      'progress': progress,
      'filename': filename,
      'errorMessage': errorMessage,
      'speed': speed,
      'eta': eta,
      'downloadedBytes': downloadedBytes,
      'totalBytes': totalBytes,
      'progressIndeterminate': progressIndeterminate,
      'lastProgressUpdate': lastProgressUpdate?.toIso8601String(),
      'wasInterrupted': wasInterrupted,
      'downloadedItems': downloadedItems,
      'retryCount': retryCount,
      'lastRetryTime': lastRetryTime?.toIso8601String(),
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] as String?,
      url: json['url'] as String,
      title: json['title'] as String,
      thumbnail: json['thumbnail'] as String?,
      formatId: json['formatId'] as String,
      outputPath: json['outputPath'] as String,
      createdDate: DateTime.parse(json['createdDate'] as String),
      mediaType: _parseMediaType(json['mediaType'] as String?),
      filenames: (json['filenames'] as List<dynamic>?)?.cast<String>(),
      totalItems: (json['totalItems'] as num?)?.toInt(),
      cookieFile: json['cookieFile'] as String?,
      selectedIndices: (json['selectedIndices'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      status: _parseDownloadStatus(json['status'] as int),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      filename: json['filename'] as String?,
      errorMessage: json['errorMessage'] as String?,
      speed: json['speed'] as String?,
      eta: json['eta'] as String?,
      downloadedBytes: (json['downloadedBytes'] as num?)?.toInt(),
      totalBytes: (json['totalBytes'] as num?)?.toInt(),
      progressIndeterminate: json['progressIndeterminate'] as bool? ?? false,
      lastProgressUpdate: json['lastProgressUpdate'] != null
          ? DateTime.parse(json['lastProgressUpdate'] as String)
          : null,
      wasInterrupted: json['wasInterrupted'] as bool? ?? false,
      downloadedItems: (json['downloadedItems'] as num?)?.toInt() ?? 0,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastRetryTime: json['lastRetryTime'] != null
          ? DateTime.parse(json['lastRetryTime'] as String)
          : null,
    );
  }

  static MediaType _parseMediaType(String? type) {
    switch (type?.toLowerCase()) {
      case 'video':
        return MediaType.video;
      case 'image':
        return MediaType.image;
      case 'audio':
        return MediaType.audio;
      case 'gallery':
        return MediaType.gallery;
      case 'mixed':
        return MediaType.mixed;
      case 'playlist':
        return MediaType.playlist;
      default:
        return MediaType.video; // Default for backward compatibility
    }
  }

  /// Safely parse DownloadStatus with bounds checking
  static DownloadStatus _parseDownloadStatus(int index) {
    if (index < 0 || index >= DownloadStatus.values.length) {
      // Invalid status index - return error status for safety
      return DownloadStatus.error;
    }
    return DownloadStatus.values[index];
  }
}
