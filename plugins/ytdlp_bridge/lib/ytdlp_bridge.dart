
import 'ytdlp_bridge_platform_interface.dart';

class YtdlpBridge {
  Future<String?> getPlatformVersion() {
    return YtdlpBridgePlatform.instance.getPlatformVersion();
  }
}
