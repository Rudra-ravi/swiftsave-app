import 'dart:io';

import '../../core/interfaces/i_download_engine.dart';
import 'android_download_engine.dart';
import 'desktop_process_download_engine.dart';

class DownloadEngineProvider {
  DownloadEngineProvider._();

  static IDownloadEngine? _instance;

  static IDownloadEngine get instance {
    _instance ??= _create();
    return _instance!;
  }

  static void resetForTests(IDownloadEngine? engine) {
    _instance = engine;
  }

  static IDownloadEngine _create() {
    if (Platform.isAndroid) {
      return AndroidDownloadEngine();
    }
    return DesktopProcessDownloadEngine();
  }
}
