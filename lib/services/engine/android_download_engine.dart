import '../../core/interfaces/i_download_engine.dart';
import '../../models/media_info.dart';
import '../../models/media_type.dart';
import '../python_service.dart';

class AndroidDownloadEngine implements IDownloadEngine {
  AndroidDownloadEngine({PythonService? pythonService})
    : _pythonService = pythonService ?? PythonService.instance;

  final PythonService _pythonService;

  @override
  Future<void> initialize() => _pythonService.initialize();

  @override
  Stream<dynamic> get progressStream => _pythonService.progressStream;

  @override
  Future<MediaInfo?> getMediaInfo(String url, {String? cookieFile}) {
    return _pythonService.getMediaInfo(url, cookieFile: cookieFile);
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
  }) {
    return _pythonService.downloadMedia(
      url: url,
      outputPath: outputPath,
      formatId: formatId,
      taskId: taskId,
      mediaType: mediaType,
      cookieFile: cookieFile,
      downloadAllGallery: downloadAllGallery,
      selectedIndices: selectedIndices,
      ffmpegPath: ffmpegPath,
      maxQuality: maxQuality,
      sleepInterval: sleepInterval,
      concurrentFragments: concurrentFragments,
      customUserAgent: customUserAgent,
      proxyUrl: proxyUrl,
      embedSubtitles: embedSubtitles,
      subtitleLanguage: subtitleLanguage,
    );
  }

  @override
  Future<void> cancelDownload(String taskId) {
    return _pythonService.cancelDownload(taskId);
  }

  @override
  Future<List<String>> getSupportedSites() =>
      _pythonService.getSupportedSites();

  @override
  Future<String?> extractCookiesFromBrowser(String browser) {
    return _pythonService.extractCookiesFromBrowser(browser);
  }

  @override
  Future<bool> saveToMediaStore({
    required String filePath,
    required String fileName,
  }) {
    return _pythonService.saveToMediaStore(
      filePath: filePath,
      fileName: fileName,
    );
  }
}
