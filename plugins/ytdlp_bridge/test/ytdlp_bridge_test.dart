import 'package:flutter_test/flutter_test.dart';
import 'package:ytdlp_bridge/ytdlp_bridge.dart';
import 'package:ytdlp_bridge/ytdlp_bridge_platform_interface.dart';
import 'package:ytdlp_bridge/ytdlp_bridge_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockYtdlpBridgePlatform
    with MockPlatformInterfaceMixin
    implements YtdlpBridgePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final YtdlpBridgePlatform initialPlatform = YtdlpBridgePlatform.instance;

  test('$MethodChannelYtdlpBridge is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelYtdlpBridge>());
  });

  test('getPlatformVersion', () async {
    YtdlpBridge ytdlpBridgePlugin = YtdlpBridge();
    MockYtdlpBridgePlatform fakePlatform = MockYtdlpBridgePlatform();
    YtdlpBridgePlatform.instance = fakePlatform;

    expect(await ytdlpBridgePlugin.getPlatformVersion(), '42');
  });
}
