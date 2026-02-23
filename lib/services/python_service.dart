import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import '../core/interfaces/i_python_service.dart';
import '../models/video_info.dart';
import '../models/media_info.dart';
import '../models/media_type.dart';
import '../utils/app_logger.dart';

class DownloadCancelledException implements Exception {
  final String message;
  DownloadCancelledException(this.message);

  @override
  String toString() => message;
}

class PythonService implements IPythonService {
  final MethodChannel _platform;
  final EventChannel _eventChannel;

  // Singleton instance for backward compatibility and easy access
  static PythonService? _instance;
  static PythonService get instance => _instance ??= PythonService();

  PythonService({MethodChannel? platform, EventChannel? eventChannel})
    : _platform = platform ?? const MethodChannel('ytdlp_bridge'),
      _eventChannel = eventChannel ?? const EventChannel('ytdlp_bridge/events');

  // ============================================================================
  // INSTANCE METHODS (Implementing IPythonService)
  // ============================================================================

  @override
  Future<void> initialize() async {
    try {
      AppLogger.debug(
        '[PythonService] Calling platform.invokeMethod(initialize)...',
      );
      await _platform.invokeMethod('initialize');
      AppLogger.debug(
        '[PythonService] Platform initialize() completed successfully',
      );
    } on PlatformException catch (e) {
      AppLogger.error(
        '[PythonService] FATAL: Failed to initialize Python',
        error: e.message,
      );
      AppLogger.error(
        '[PythonService] Error code: ${e.code}, details: ${e.details}',
      );
      rethrow;
    } catch (e) {
      AppLogger.error(
        '[PythonService] FATAL: Unexpected error during init',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Stream<dynamic> get progressStream => _eventChannel.receiveBroadcastStream();

  @override
  Future<VideoInfo?> getVideoInfo(String url) async {
    try {
      final result = await _platform.invokeMethod<String>('getVideoInfo', {
        'url': url,
      });
      if (result == null) {
        throw Exception('No response from platform');
      }
      final data = json.decode(result) as Map<String, dynamic>;

      if (data['success'] == true) {
        return VideoInfo.fromJson(data);
      } else {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } on PlatformException catch (e) {
      AppLogger.error("Failed to get video info", error: e.message);
      rethrow;
    } catch (e) {
      AppLogger.error("Error parsing video info", error: e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> downloadVideo({
    required String url,
    required String outputPath,
    String formatId = 'best',
    required String taskId,
  }) async {
    try {
      final result = await _platform.invokeMethod<String>('downloadVideo', {
        'url': url,
        'outputPath': outputPath,
        'formatId': formatId,
        'taskId': taskId,
      });

      if (result == null) {
        throw Exception('No response from platform');
      }
      final data = json.decode(result) as Map<String, dynamic>;

      if (data['success'] != true) {
        if (data['error_code'] == 'CANCELLED' || data['cancelled'] == true) {
          throw DownloadCancelledException(
            (data['error'] as String?) ?? 'Download cancelled',
          );
        }
        throw Exception(data['error'] ?? 'Download failed');
      }

      return data;
    } on PlatformException catch (e) {
      AppLogger.error("Failed to download video", error: e.message);
      rethrow;
    } catch (e) {
      AppLogger.error("Error during download", error: e);
      rethrow;
    }
  }

  @override
  Future<List<String>> getSupportedSites() async {
    try {
      final result = await _platform
          .invokeMethod<String>('getSupportedSites')
          .timeout(const Duration(seconds: 30));
      if (result == null) {
        throw Exception('No response from platform');
      }
      final data = json.decode(result) as Map<String, dynamic>;

      if (data['success'] == true) {
        return List<String>.from(data['sites'] as List<dynamic>);
      } else {
        throw Exception(data['error'] ?? 'Failed to get sites');
      }
    } on TimeoutException {
      AppLogger.warning('getSupportedSites timed out after 30 seconds');
      return [];
    } on PlatformException catch (e) {
      AppLogger.error("Failed to get supported sites", error: e.message);
      return [];
    } catch (e) {
      AppLogger.error("Error getting supported sites", error: e);
      return [];
    }
  }

  @override
  Future<bool> saveToMediaStore({
    required String filePath,
    required String fileName,
  }) async {
    try {
      final result = await _platform.invokeMethod<bool>('saveToMediaStore', {
        'filePath': filePath,
        'fileName': fileName,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      AppLogger.error("Failed to save to MediaStore", error: e.message);
      return false;
    } catch (e) {
      AppLogger.error("Error saving to MediaStore", error: e);
      return false;
    }
  }

  @override
  Future<MediaInfo?> getMediaInfo(String url, {String? cookieFile}) async {
    try {
      final params = <String, dynamic>{'url': url};
      if (cookieFile != null) {
        params['cookies_file'] = cookieFile;
      }

      final result = await _platform
          .invokeMethod<String>('getMediaInfo', params)
          .timeout(const Duration(seconds: 120));

      if (result == null) {
        throw Exception('No response from platform');
      }
      final data = json.decode(result) as Map<String, dynamic>;

      if (data['success'] == true) {
        return MediaInfo.fromJson(data);
      } else {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Check your internet connection.');
    } on PlatformException catch (e) {
      AppLogger.error("Failed to get media info", error: e.message);
      rethrow;
    } catch (e) {
      AppLogger.error("Error parsing media info", error: e);
      rethrow;
    }
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
    try {
      final params = <String, dynamic>{
        'url': url,
        'outputPath': outputPath,
        'formatId': formatId,
        'taskId': taskId,
        'mediaType': mediaType.name,
        'downloadAllGallery': downloadAllGallery,
      };

      if (cookieFile != null) {
        params['cookiesFile'] = cookieFile;
      }

      if (selectedIndices != null) {
        params['selectedIndices'] = selectedIndices;
      }

      if (ffmpegPath != null) {
        params['ffmpegPath'] = ffmpegPath;
      }

      if (maxQuality != null) {
        params['maxQuality'] = maxQuality;
      }

      if (sleepInterval != null) {
        params['sleepInterval'] = sleepInterval;
      }

      if (concurrentFragments != null) {
        params['concurrentFragments'] = concurrentFragments;
      }

      if (customUserAgent != null && customUserAgent.isNotEmpty) {
        params['customUserAgent'] = customUserAgent;
      }

      if (proxyUrl != null && proxyUrl.isNotEmpty) {
        params['proxyUrl'] = proxyUrl;
      }

      params['embedSubtitles'] = embedSubtitles;

      if (subtitleLanguage != null && subtitleLanguage.isNotEmpty) {
        params['subtitleLanguage'] = subtitleLanguage;
      }

      final result = await _platform
          .invokeMethod<String>('downloadMedia', params)
          .timeout(const Duration(hours: 6));

      if (result == null) {
        throw Exception('No response from platform');
      }
      final data = json.decode(result) as Map<String, dynamic>;

      if (data['success'] != true) {
        if (data['error_code'] == 'CANCELLED' || data['cancelled'] == true) {
          throw DownloadCancelledException(
            (data['error'] as String?) ?? 'Download cancelled',
          );
        }
        throw Exception(data['error'] ?? 'Download failed');
      }

      return data;
    } on PlatformException catch (e) {
      AppLogger.error("Failed to download media", error: e.message);
      rethrow;
    } catch (e) {
      AppLogger.error("Error during media download", error: e);
      rethrow;
    }
  }

  @override
  Future<String?> extractCookiesFromBrowser(String browser) async {
    try {
      final result = await _platform
          .invokeMethod<String>('extractCookiesFromBrowser', {
            'browser': browser,
          })
          .timeout(const Duration(seconds: 30));

      if (result == null) {
        return null;
      }
      final data = json.decode(result) as Map<String, dynamic>;

      if (data['success'] == true) {
        return data['cookie_file'] as String?;
      }
      return null;
    } catch (e) {
      AppLogger.error("Failed to extract cookies", error: e);
      return null;
    }
  }

  @override
  Future<void> cancelDownload(String taskId) async {
    try {
      await _platform.invokeMethod<void>('cancelDownload', {'taskId': taskId});
    } on PlatformException catch (e) {
      AppLogger.error("Failed to cancel download", error: e.message);
    } catch (e) {
      AppLogger.error("Error cancelling download", error: e);
    }
  }

  // ============================================================================
  // STATIC FORWARDERS (For Backward Compatibility)
  // These will be deprecated and removed in future phases
  // ============================================================================

  static Future<void> initializeStatic() => instance.initialize();
  static Stream<dynamic> get progressStreamStatic => instance.progressStream;
  static Future<VideoInfo?> getVideoInfoStatic(String url) =>
      instance.getVideoInfo(url);
  static Future<Map<String, dynamic>> downloadVideoStatic({
    required String url,
    required String outputPath,
    String formatId = 'best',
    required String taskId,
  }) => instance.downloadVideo(
    url: url,
    outputPath: outputPath,
    formatId: formatId,
    taskId: taskId,
  );
  static Future<List<String>> getSupportedSitesStatic() =>
      instance.getSupportedSites();
  static Future<bool> saveToMediaStoreStatic({
    required String filePath,
    required String fileName,
  }) => instance.saveToMediaStore(filePath: filePath, fileName: fileName);
  static Future<MediaInfo?> getMediaInfoStatic(
    String url, {
    String? cookieFile,
  }) => instance.getMediaInfo(url, cookieFile: cookieFile);
  static Future<Map<String, dynamic>> downloadMediaStatic({
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
  }) => instance.downloadMedia(
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
  static Future<String?> extractCookiesFromBrowserStatic(String browser) =>
      instance.extractCookiesFromBrowser(browser);
  static Future<void> cancelDownloadStatic(String taskId) =>
      instance.cancelDownload(taskId);
}
