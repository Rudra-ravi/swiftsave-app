import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class StorageCheckResult {
  final bool canCheck;
  final bool hasEnoughSpace;
  final int? availableBytes;
  final int? requiredBytes;

  StorageCheckResult({
    required this.canCheck,
    required this.hasEnoughSpace,
    this.availableBytes,
    this.requiredBytes,
  });

  int? get shortfallBytes {
    if (!canCheck || availableBytes == null || requiredBytes == null) {
      return null;
    }
    if (availableBytes! >= requiredBytes!) return 0;
    return requiredBytes! - availableBytes!;
  }
}

class DownloadPathService {
  static const MethodChannel _platform = MethodChannel('ytdlp_bridge');
  static const int _minFreeBytes = 200 * 1024 * 1024; // 200MB
  static const int _minBufferBytes = 50 * 1024 * 1024; // 50MB buffer

  /// Get the appropriate download path based on Android version
  static Future<String> getDownloadPath() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt >= 29) {
          // Android 10+ (API 29+) - Use scoped storage
          // Files go to app-specific directory first, then copied to MediaStore
          final directory = await getExternalStorageDirectory();
          final downloadDir = Directory('${directory!.path}/Downloads');

          // Create directory if it doesn't exist
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }

          return downloadDir.path;
        } else {
          // Android 9 and below - Use public Downloads folder
          return '/storage/emulated/0/Download';
        }
      } catch (e) {
        debugPrint('Error getting download path: $e');
        // Fallback to app directory
        final directory = await getExternalStorageDirectory();
        return '${directory!.path}/Downloads';
      }
    } else {
      // iOS or other platforms
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
  }

  /// Resolve a user-preferred path when valid, otherwise fallback to default.
  static Future<String> resolvePreferredDownloadPath(String? preferredPath) async {
    final candidate = preferredPath?.trim();
    if (candidate != null && candidate.isNotEmpty) {
      try {
        final dir = Directory(candidate);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final testFile = File('${dir.path}/.write_test_${DateTime.now().millisecondsSinceEpoch}');
        await testFile.writeAsString('ok', flush: true);
        await testFile.delete();
        return dir.path;
      } catch (_) {
        // Fall back to platform default path.
      }
    }
    return getDownloadPath();
  }

  /// Check if we need to use MediaStore for this Android version
  static Future<bool> requiresMediaStore() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 29;
    }
    return false;
  }

  /// Get a user-friendly description of where files are saved
  static Future<String> getDownloadLocationDescription() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 29) {
        return 'Downloads folder (accessible via Files app)';
      } else {
        return '/storage/emulated/0/Download';
      }
    }
    return 'App documents folder';
  }

  static int _addBuffer(int bytes) {
    final buffer = (bytes * 0.1).round();
    return bytes + (buffer < _minBufferBytes ? _minBufferBytes : buffer);
  }

  /// Get available storage space in bytes (null if unable to determine)
  static Future<int?> getAvailableSpaceBytes({String? path}) async {
    if (!Platform.isAndroid) return null;
    try {
      final targetPath = path ?? await getDownloadPath();
      final result = await _platform.invokeMethod('getAvailableStorageBytes', {
        'path': targetPath,
      });
      if (result is int) return result;
      if (result is num) return result.toInt();
      return null;
    } catch (e) {
      debugPrint('Error getting available space: $e');
      return null;
    }
  }

  /// Check if there's enough storage space available
  /// Returns true if available space > requiredBytes
  static Future<bool> hasEnoughSpace({int requiredBytes = 524288000}) async {
    final result = await checkStorage(estimatedBytes: requiredBytes);
    return result.hasEnoughSpace;
  }

  /// Check storage with optional estimate (includes safety buffer)
  static Future<StorageCheckResult> checkStorage({int? estimatedBytes}) async {
    final available = await getAvailableSpaceBytes();
    if (available == null || available <= 0) {
      return StorageCheckResult(
        canCheck: false,
        hasEnoughSpace: true,
        availableBytes: available,
        requiredBytes: estimatedBytes,
      );
    }

    final required = estimatedBytes != null
        ? _addBuffer(estimatedBytes)
        : _minFreeBytes;
    final hasEnough = available >= required;

    return StorageCheckResult(
      canCheck: true,
      hasEnoughSpace: hasEnough,
      availableBytes: available,
      requiredBytes: required,
    );
  }

  /// Get available storage space in bytes (returns -1 if unable to determine)
  static Future<int> getAvailableSpace() async {
    final bytes = await getAvailableSpaceBytes();
    return bytes ?? -1;
  }
}
