class VideoFormat {
  final String formatId;
  final String ext;
  final String quality;
  final String resolution;
  final int? filesize;
  final int? fps;
  final String? vcodec;
  final String? acodec;

  VideoFormat({
    required this.formatId,
    required this.ext,
    required this.quality,
    required this.resolution,
    this.filesize,
    this.fps,
    this.vcodec,
    this.acodec,
  });

  factory VideoFormat.fromJson(Map<String, dynamic> json) {
    return VideoFormat(
      formatId: json['format_id'] as String,
      ext: json['ext'] as String,
      quality: json['quality'] as String,
      resolution: json['resolution'] as String,
      filesize: (json['filesize'] as num?)?.toInt(),
      fps: (json['fps'] as num?)?.toInt(),
      vcodec: json['vcodec'] as String?,
      acodec: json['acodec'] as String?,
    );
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

  bool get isVideoFormat => vcodec != null && vcodec != 'none';
  bool get isAudioFormat => acodec != null && acodec != 'none';
}

class PlaylistEntry {
  final String id;
  final String url;
  final String title;
  final int? duration;
  final String? uploader;

  PlaylistEntry({
    required this.id,
    required this.url,
    required this.title,
    this.duration,
    this.uploader,
  });

  factory PlaylistEntry.fromJson(Map<String, dynamic> json) {
    return PlaylistEntry(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      duration: (json['duration'] as num?)?.toInt(),
      uploader: json['uploader'] as String?,
    );
  }

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
}

class VideoInfo {
  final String title;
  final bool isPlaylist;
  final int? duration;
  final String? thumbnail;
  final String? uploader;
  final int? viewCount;
  final String? description;
  final List<VideoFormat> formats;
  final List<PlaylistEntry> entries;

  VideoInfo({
    required this.title,
    this.isPlaylist = false,
    this.duration,
    this.thumbnail,
    this.uploader,
    this.viewCount,
    this.description,
    this.formats = const [],
    this.entries = const [],
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      title: json['title'] as String? ?? 'Unknown Title',
      isPlaylist: json['is_playlist'] as bool? ?? false,
      duration: (json['duration'] as num?)?.toInt(),
      thumbnail: json['thumbnail'] as String?,
      uploader: json['uploader'] as String?,
      viewCount: (json['view_count'] as num?)?.toInt(),
      description: json['description'] as String?,
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
