import '../../models/video_info.dart';
import '../../models/media_info.dart';
import '../../models/media_type.dart';

/// Interface for Python/yt-dlp bridge service
abstract class IPythonService {
  /// Initialize the Python environment
  Future<void> initialize();

  /// Get stream of progress events
  Stream<dynamic> get progressStream;

  /// Get video information without downloading (Legacy)
  Future<VideoInfo?> getVideoInfo(String url);

  /// Get comprehensive media information (images, videos, audio, galleries)
  Future<MediaInfo?> getMediaInfo(String url, {String? cookieFile});

  /// Download any media type
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
  });

  /// Download video with specified format (Legacy)
  Future<Map<String, dynamic>> downloadVideo({
    required String url,
    required String outputPath,
    String formatId = 'best',
    required String taskId,
  });

  /// Cancel an active download by taskId
  Future<void> cancelDownload(String taskId);

  /// Extract cookies from browser for authenticated access
  Future<String?> extractCookiesFromBrowser(String browser);

  /// Get list of supported websites
  Future<List<String>> getSupportedSites();

  /// Save file to MediaStore (Android 10+ Downloads folder)
  Future<bool> saveToMediaStore({
    required String filePath,
    required String fileName,
  });
}
