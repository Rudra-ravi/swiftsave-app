import '../../models/media_info.dart';
import '../../models/media_type.dart';

abstract class IDownloadEngine {
  Future<void> initialize();

  Stream<dynamic> get progressStream;

  Future<MediaInfo?> getMediaInfo(String url, {String? cookieFile});

  Future<Map<String, dynamic>> downloadMedia({
    required String url,
    required String outputPath,
    String formatId,
    required String taskId,
    required MediaType mediaType,
    String? cookieFile,
    bool downloadAllGallery,
    List<int>? selectedIndices,
    String? ffmpegPath,
    int? maxQuality,
    int? sleepInterval,
    int? concurrentFragments,
    String? customUserAgent,
    String? proxyUrl,
    bool embedSubtitles,
    String? subtitleLanguage,
  });

  Future<void> cancelDownload(String taskId);

  Future<List<String>> getSupportedSites();

  Future<String?> extractCookiesFromBrowser(String browser);

  Future<bool> saveToMediaStore({
    required String filePath,
    required String fileName,
  });
}
