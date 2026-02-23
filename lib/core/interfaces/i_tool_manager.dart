import '../../models/tool_install_state.dart';

abstract class IToolManager {
  Future<ToolInstallState> checkInstalled();

  Future<ToolInstallState> installOrUpdate({
    void Function(double progress, String message)? onProgress,
    bool force = false,
  });

  Future<Map<String, String>> currentVersions();

  Future<bool> verifyIntegrity();

  Future<String?> getExecutablePath(String toolName);
}
