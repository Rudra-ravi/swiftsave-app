import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ytdlp_bridge_platform_interface.dart';

/// An implementation of [YtdlpBridgePlatform] that uses method channels.
class MethodChannelYtdlpBridge extends YtdlpBridgePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ytdlp_bridge');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
