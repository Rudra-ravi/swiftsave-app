import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:media_scanner/media_scanner.dart';

/// Service for opening downloaded files and making them visible in gallery
class FileOpenerService {
  /// Open a file with the system's default app
  static Future<OpenResult> openFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return OpenResult(
        type: ResultType.fileNotFound,
        message: 'File not found: $filePath',
      );
    }

    return await OpenFilex.open(filePath);
  }

  /// Scan a file to make it visible in the device's media gallery.
  ///
  /// On Android 10+ files inside /Android/data/ are app-private and cannot be
  /// indexed by MediaScanner (the scanner returns a null URI).  These files
  /// should instead be saved through MediaStore, which the download executor
  /// already handles.  We skip the scan for those paths to avoid the harmless
  /// but noisy "Scanned ... to null" log.
  static Future<void> scanFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) return;

    // App-private paths on Android 10+ cannot be scanned by MediaScanner.
    // The MediaStore save in DownloadExecutor already makes these visible.
    if (Platform.isAndroid && filePath.contains('/Android/data/')) {
      return;
    }

    // MediaScanner.loadMedia will make the file visible in gallery apps
    await MediaScanner.loadMedia(path: filePath);
  }

  /// Open a file and also ensure it's visible in gallery
  static Future<OpenResult> openAndScan(String filePath) async {
    // Scan first to ensure it's in gallery
    await scanFile(filePath);

    // Then open with default app
    return await openFile(filePath);
  }

  /// Get a user-friendly error message from OpenResult
  static String getErrorMessage(OpenResult result) {
    switch (result.type) {
      case ResultType.done:
        return 'File opened successfully';
      case ResultType.fileNotFound:
        return 'File not found. It may have been moved or deleted.';
      case ResultType.noAppToOpen:
        return 'No app found to open this file type.';
      case ResultType.permissionDenied:
        return 'Permission denied. Please grant storage access.';
      case ResultType.error:
        return result.message;
    }
  }

  /// Check if result indicates success
  static bool isSuccess(OpenResult result) {
    return result.type == ResultType.done;
  }
}
