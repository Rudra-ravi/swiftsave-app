import 'media_type.dart';
import 'video_info.dart';

class MediaItem {
  final String id;
  final String? url;
  final String title;
  final String? thumbnail;
  final String ext;
  final int? width;
  final int? height;
  final int? filesize;
  final MediaType mediaType;
  bool isSelected; // For gallery selection

  MediaItem({
    required this.id,
    this.url,
    required this.title,
    this.thumbnail,
    required this.ext,
    this.width,
    this.height,
    this.filesize,
    this.mediaType = MediaType.unknown,
    this.isSelected = true,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      url: json['url'] as String?,
      title: json['title'] as String? ?? 'Untitled',
      thumbnail: json['thumbnail'] as String?,
      ext: json['ext'] as String? ?? 'unknown',
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      filesize: (json['filesize'] as num?)?.toInt(),
      mediaType: _parseMediaType(json['media_type'] as String?),
    );
  }

  static MediaType _parseMediaType(String? type) {
    switch (type?.toLowerCase()) {
      case 'image':
        return MediaType.image;
      case 'video':
        return MediaType.video;
      case 'audio':
        return MediaType.audio;
      default:
        return MediaType.unknown;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'thumbnail': thumbnail,
      'ext': ext,
      'width': width,
      'height': height,
      'filesize': filesize,
      'media_type': mediaType.name,
    };
  }

  String get filesizeFormatted {
    if (filesize == null) return 'Unknown size';
    final mb = filesize! / (1024 * 1024);
    if (mb < 1) {
      final kb = filesize! / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get resolution {
    if (width != null && height != null) {
      return '${width}x$height';
    }
    return 'Unknown';
  }
}

class MediaInfo {
  final String title;
  final MediaType mediaType;
  final String? thumbnail;
  final String? uploader;
  final int? viewCount;
  final String? description;
  final int? duration;

  // For galleries
  final int? itemCount;
  final List<MediaItem> items;

  // For videos (existing)
  final List<VideoFormat> formats;

  // For playlists (existing)
  final List<PlaylistEntry> entries;

  MediaInfo({
    required this.title,
    required this.mediaType,
    this.thumbnail,
    this.uploader,
    this.viewCount,
    this.description,
    this.duration,
    this.itemCount,
    this.items = const [],
    this.formats = const [],
    this.entries = const [],
  });

  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    final mediaType = _parseMediaType(json['media_type'] as String?);

    return MediaInfo(
      title: json['title'] as String? ?? 'Unknown Title',
      mediaType: mediaType,
      thumbnail: json['thumbnail'] as String?,
      uploader: json['uploader'] as String?,
      viewCount: (json['view_count'] as num?)?.toInt(),
      description: json['description'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      itemCount: (json['item_count'] as num?)?.toInt(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => MediaItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      formats:
          (json['formats'] as List<dynamic>?)
              ?.map((f) => VideoFormat.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      entries:
          (json['entries'] as List<dynamic>?)
              ?.map((e) => PlaylistEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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

  bool get isGallery => mediaType == MediaType.gallery;
  bool get isPlaylist => mediaType == MediaType.playlist;
  bool get isImage => mediaType == MediaType.image;
  bool get isVideo => mediaType == MediaType.video;
  bool get isAudio => mediaType == MediaType.audio;

  String get durationFormatted {
    if (duration == null) return 'Unknown';
    final hours = duration! ~/ 3600;
    final minutes = (duration! % 3600) ~/ 60;
    final seconds = duration! % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get viewCountFormatted {
    if (viewCount == null) return 'Unknown views';
    if (viewCount! >= 1000000) {
      return '${(viewCount! / 1000000).toStringAsFixed(1)}M views';
    } else if (viewCount! >= 1000) {
      return '${(viewCount! / 1000).toStringAsFixed(1)}K views';
    }
    return '$viewCount views';
  }

  List<VideoFormat> get videoFormats =>
      formats.where((f) => f.isVideoFormat).toList();

  List<VideoFormat> get audioFormats =>
      formats.where((f) => f.isAudioFormat && !f.isVideoFormat).toList();
}
