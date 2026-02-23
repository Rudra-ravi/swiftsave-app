import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/interfaces/i_download_engine.dart';
import '../../models/media_info.dart';
import '../../models/media_type.dart';
import '../../models/video_info.dart';
import '../python_service.dart';
import '../tools/tool_manager_service.dart';
import 'parsers/ytdlp_progress_parser.dart';

class DesktopProcessDownloadEngine implements IDownloadEngine {
  DesktopProcessDownloadEngine({ToolManagerService? toolManager})
    : _toolManager = toolManager ?? ToolManagerService();

  final ToolManagerService _toolManager;
  final YtDlpProgressParser _progressParser = YtDlpProgressParser();
  final StreamController<Map<String, dynamic>> _progressController =
      StreamController<Map<String, dynamic>>.broadcast();
  final Map<String, Process> _activeProcesses = <String, Process>{};
  final Set<String> _cancelledTasks = <String>{};

  String? _ytDlpPath;
  String? _ffmpegPath;

  @override
  Stream<dynamic> get progressStream => _progressController.stream;

  @override
  Future<void> initialize() async {
    _ytDlpPath =
        await _toolManager.getExecutablePath('ytDlp') ??
        await _toolManager.getExecutablePath('yt-dlp') ??
        (Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp');

    _ffmpegPath =
        await _toolManager.getExecutablePath('ffmpeg') ??
        (Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg');
  }

  @override
  Future<MediaInfo?> getMediaInfo(String url, {String? cookieFile}) async {
    await initialize();
    final args = <String>['-J', '--no-warnings', url];
    if (cookieFile != null && cookieFile.trim().isNotEmpty) {
      args.insertAll(0, <String>['--cookies', cookieFile]);
    }

    final result = await Process.run(_ytDlpPath!, args);
    if (result.exitCode != 0) {
      throw Exception(result.stderr.toString().trim());
    }

    final decoded =
        jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
    return _mapToMediaInfo(decoded);
  }

  @override
  Future<Map<String, dynamic>> downloadMedia({
    required String url,
    required String outputPath,
    String formatId = 'best',
    required String taskId,
    required MediaType mediaType,
    String? cookieFile,
    bool downloadAllGallery = true,
    List<int>? selectedIndices,
    String? ffmpegPath,
    int? maxQuality,
    int? sleepInterval,
    int? concurrentFragments,
    String? customUserAgent,
    String? proxyUrl,
    bool embedSubtitles = false,
    String? subtitleLanguage,
  }) async {
    await initialize();
    final executable = _ytDlpPath!;

    final args = <String>[
      '--newline',
      '--no-warnings',
      '--print',
      'after_move:__FILE__:%(filepath)s',
      '--progress-template',
      'download:progress:$taskId|%(progress._percent_str)s|%(progress.downloaded_bytes)s|%(progress.total_bytes)s|%(progress._speed_str)s|%(progress._eta_str)s',
      '-o',
      '$outputPath/%(title)s [%(id)s].%(ext)s',
    ];

    if (ffmpegPath != null && ffmpegPath.trim().isNotEmpty) {
      args.addAll(<String>['--ffmpeg-location', ffmpegPath]);
    } else if (_ffmpegPath != null && _ffmpegPath!.trim().isNotEmpty) {
      args.addAll(<String>['--ffmpeg-location', _ffmpegPath!]);
    }

    if (cookieFile != null && cookieFile.trim().isNotEmpty) {
      args.addAll(<String>['--cookies', cookieFile]);
    }

    if (sleepInterval != null && sleepInterval > 0) {
      args.addAll(<String>['--sleep-interval', '$sleepInterval']);
    }

    if (concurrentFragments != null && concurrentFragments > 0) {
      args.addAll(<String>['--concurrent-fragments', '$concurrentFragments']);
    }

    if (customUserAgent != null && customUserAgent.trim().isNotEmpty) {
      args.addAll(<String>['--user-agent', customUserAgent]);
    }

    if (proxyUrl != null && proxyUrl.trim().isNotEmpty) {
      args.addAll(<String>['--proxy', proxyUrl]);
    }

    if (!downloadAllGallery &&
        selectedIndices != null &&
        selectedIndices.isNotEmpty) {
      final oneBased = selectedIndices.map((e) => e + 1).join(',');
      args.addAll(<String>['--playlist-items', oneBased]);
    }

    if (embedSubtitles) {
      args.addAll(<String>['--write-subs', '--embed-subs']);
      if (subtitleLanguage != null && subtitleLanguage.trim().isNotEmpty) {
        args.addAll(<String>['--sub-langs', subtitleLanguage]);
      }
    }

    if (formatId == 'audio_only') {
      args.addAll(<String>[
        '-f',
        'bestaudio/best',
        '-x',
        '--audio-format',
        'mp3',
      ]);
    } else if (formatId != 'best') {
      args.addAll(<String>['-f', formatId]);
    } else {
      final quality = maxQuality ?? 2160;
      args.addAll(<String>[
        '-f',
        'bestvideo[height<=$quality]+bestaudio/best[height<=$quality]/best',
      ]);
    }

    args.add(url);

    final process = await Process.start(executable, args);
    _activeProcesses[taskId] = process;

    final files = <String>[];
    final stderrBuffer = StringBuffer();

    Future<void> handleStream(Stream<List<int>> stream) async {
      await for (final chunk
          in stream.transform(utf8.decoder).transform(const LineSplitter())) {
        final line = chunk.trim();
        if (line.isEmpty) continue;

        final progress = _progressParser.parse(line);
        if (progress != null) {
          _progressController.add(progress.toMap());
          continue;
        }

        final filePrefix = '__FILE__:';
        final markerIndex = line.indexOf(filePrefix);
        if (markerIndex != -1) {
          final path = line.substring(markerIndex + filePrefix.length).trim();
          if (path.isNotEmpty) {
            files.add(path);
          }
        }

        if (_cancelledTasks.contains(taskId)) {
          process.kill(ProcessSignal.sigterm);
        }
      }
    }

    final stdoutFuture = handleStream(process.stdout);
    final stderrFuture = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            stderrBuffer.writeln(trimmed);
          }
          final progress = _progressParser.parse(trimmed);
          if (progress != null) {
            _progressController.add(progress.toMap());
          }
          if (_cancelledTasks.contains(taskId)) {
            process.kill(ProcessSignal.sigterm);
          }
        });

    final exitCode = await process.exitCode;
    await Future.wait(<Future<void>>[stdoutFuture, stderrFuture]);

    _activeProcesses.remove(taskId);

    if (_cancelledTasks.remove(taskId)) {
      throw DownloadCancelledException('Download cancelled');
    }

    if (exitCode != 0) {
      throw Exception(
        stderrBuffer.toString().trim().isEmpty
            ? 'yt-dlp exited with code $exitCode'
            : stderrBuffer.toString().trim(),
      );
    }

    if (files.isEmpty) {
      return <String, dynamic>{'success': true};
    }

    return <String, dynamic>{
      'success': true,
      'filename': files.first,
      'filenames': files,
    };
  }

  @override
  Future<void> cancelDownload(String taskId) async {
    _cancelledTasks.add(taskId);
    final process = _activeProcesses[taskId];
    process?.kill(ProcessSignal.sigterm);
  }

  @override
  Future<List<String>> getSupportedSites() async {
    await initialize();
    final result = await Process.run(_ytDlpPath!, <String>[
      '--list-extractors',
    ]);
    if (result.exitCode != 0) return <String>[];
    return result.stdout
        .toString()
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Future<String?> extractCookiesFromBrowser(String browser) async {
    // Desktop flow uses explicit cookie file import in this phase.
    return null;
  }

  @override
  Future<bool> saveToMediaStore({
    required String filePath,
    required String fileName,
  }) async {
    return true;
  }

  MediaInfo _mapToMediaInfo(Map<String, dynamic> raw) {
    final formats = <VideoFormat>[];
    final rawFormats = raw['formats'] as List<dynamic>? ?? const <dynamic>[];
    for (final item in rawFormats) {
      final f = item as Map<String, dynamic>;
      formats.add(
        VideoFormat(
          formatId: (f['format_id'] ?? '').toString(),
          ext: (f['ext'] ?? 'unknown').toString(),
          quality: (f['format_note'] ?? f['quality'] ?? 'unknown').toString(),
          resolution: (f['resolution'] ?? 'unknown').toString(),
          filesize: (f['filesize'] as num?)?.toInt(),
          fps: (f['fps'] as num?)?.toInt(),
          vcodec: f['vcodec']?.toString(),
          acodec: f['acodec']?.toString(),
        ),
      );
    }

    final entries = <PlaylistEntry>[];
    final rawEntries = raw['entries'] as List<dynamic>?;
    if (rawEntries != null) {
      for (final item in rawEntries) {
        if (item is! Map<String, dynamic>) continue;
        entries.add(
          PlaylistEntry(
            id: (item['id'] ?? '').toString(),
            url: (item['url'] ?? item['webpage_url'] ?? '').toString(),
            title: (item['title'] ?? 'Untitled').toString(),
            duration: (item['duration'] as num?)?.toInt(),
            uploader: item['uploader']?.toString(),
          ),
        );
      }
    }

    final mediaType = _inferMediaType(raw, entries, formats);

    return MediaInfo(
      title: (raw['title'] ?? 'Unknown Title').toString(),
      mediaType: mediaType,
      thumbnail: raw['thumbnail']?.toString(),
      uploader: raw['uploader']?.toString(),
      viewCount: (raw['view_count'] as num?)?.toInt(),
      description: raw['description']?.toString(),
      duration: (raw['duration'] as num?)?.toInt(),
      itemCount: entries.isNotEmpty ? entries.length : null,
      formats: formats,
      entries: entries,
      items: const <MediaItem>[],
    );
  }

  MediaType _inferMediaType(
    Map<String, dynamic> raw,
    List<PlaylistEntry> entries,
    List<VideoFormat> formats,
  ) {
    if ((raw['_type'] ?? '').toString() == 'playlist' && entries.isNotEmpty) {
      return MediaType.playlist;
    }

    final hasVideo = formats.any((f) => f.isVideoFormat);
    final hasAudio = formats.any((f) => f.isAudioFormat);

    if (hasAudio && !hasVideo) return MediaType.audio;
    return MediaType.video;
  }
}
