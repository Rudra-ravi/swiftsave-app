import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ytdlp_bridge_method_channel.dart';

abstract class YtdlpBridgePlatform extends PlatformInterface {
  /// Constructs a YtdlpBridgePlatform.
  YtdlpBridgePlatform() : super(token: _token);

  static final Object _token = Object();

  static YtdlpBridgePlatform _instance = MethodChannelYtdlpBridge();

  /// The default instance of [YtdlpBridgePlatform] to use.
  ///
  /// Defaults to [MethodChannelYtdlpBridge].
  static YtdlpBridgePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [YtdlpBridgePlatform] when
  /// they register themselves.
  static set instance(YtdlpBridgePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
