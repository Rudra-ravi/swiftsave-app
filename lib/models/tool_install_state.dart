class ToolInstallState {
  final bool installed;
  final bool healthy;
  final String statusMessage;
  final DateTime? lastUpdated;
  final Map<String, String> installedPaths;
  final Map<String, String> installedVersions;

  const ToolInstallState({
    required this.installed,
    required this.healthy,
    required this.statusMessage,
    required this.installedPaths,
    required this.installedVersions,
    this.lastUpdated,
  });

  factory ToolInstallState.missing([String message = 'Tools not installed']) {
    return ToolInstallState(
      installed: false,
      healthy: false,
      statusMessage: message,
      installedPaths: const {},
      installedVersions: const {},
    );
  }
}
