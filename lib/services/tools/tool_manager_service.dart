import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/interfaces/i_tool_manager.dart';
import '../../models/tool_install_state.dart';
import 'tool_registry_service.dart';

class ToolManagerService implements IToolManager {
  ToolManagerService({ToolRegistryService? registry})
    : _registry = registry ?? ToolRegistryService();

  final ToolRegistryService _registry;

  @override
  Future<ToolInstallState> checkInstalled() async {
    if (_isMobilePlatform()) {
      return const ToolInstallState(
        installed: true,
        healthy: true,
        statusMessage: 'Bundled runtime available on mobile',
        installedPaths: {},
        installedVersions: {},
      );
    }

    final state = await _readState();
    if (state == null) return ToolInstallState.missing();

    for (final path in state.paths.values) {
      if (!await File(path).exists()) {
        return ToolInstallState.missing('Tool files are missing');
      }
    }

    final healthy = await verifyIntegrity();
    return ToolInstallState(
      installed: true,
      healthy: healthy,
      statusMessage: healthy
          ? 'Tools are installed and verified'
          : 'Tool checksum verification failed',
      installedPaths: state.paths,
      installedVersions: state.versions,
      lastUpdated: state.lastUpdated,
    );
  }

  @override
  Future<ToolInstallState> installOrUpdate({
    void Function(double progress, String message)? onProgress,
    bool force = false,
  }) async {
    if (_isMobilePlatform()) {
      return checkInstalled();
    }

    onProgress?.call(0.05, 'Fetching manifest');
    final manifest = await _registry.fetchManifest();
    if (manifest == null) {
      return ToolInstallState.missing('No manifest available');
    }

    final platformManifest = manifest.forPlatform(_platformId());
    if (platformManifest == null || platformManifest.tools.isEmpty) {
      return ToolInstallState.missing(
        'No tool bundle configured for this platform',
      );
    }

    final existingState = await _readState();
    if (!force &&
        existingState != null &&
        existingState.version == platformManifest.version &&
        await verifyIntegrity()) {
      return checkInstalled();
    }

    final rootDir = await _toolsRootDir();
    final platformDir = Directory(p.join(rootDir.path, _platformId()));
    final currentDir = Directory(p.join(platformDir.path, 'current'));
    final stagingDir = Directory(
      p.join(
        platformDir.path,
        '.staging-${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    await stagingDir.create(recursive: true);

    final total = platformManifest.tools.length;
    var index = 0;
    final installedPaths = <String, String>{};

    try {
      for (final entry in platformManifest.tools.entries) {
        index += 1;
        final tool = entry.value;
        onProgress?.call(
          0.1 + (index - 1) / total * 0.7,
          'Downloading ${tool.name}',
        );

        final targetPath = p.join(stagingDir.path, tool.fileName);
        await _downloadFile(tool.url, targetPath);

        final file = File(targetPath);
        final digest = sha256.convert(await file.readAsBytes()).toString();
        if (digest.toLowerCase() != tool.sha256.toLowerCase()) {
          throw StateError('Checksum mismatch for ${tool.name}');
        }

        if (tool.executable && !Platform.isWindows) {
          await Process.run('chmod', ['755', targetPath]);
        }

        installedPaths[tool.name] = targetPath;
      }

      final backupDir = Directory(p.join(platformDir.path, '.backup'));
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }

      if (await currentDir.exists()) {
        await currentDir.rename(backupDir.path);
      }
      await stagingDir.rename(currentDir.path);

      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }

      final currentPaths = <String, String>{};
      for (final entry in platformManifest.tools.entries) {
        currentPaths[entry.key] = p.join(currentDir.path, entry.value.fileName);
      }

      final newState = _LocalToolState(
        version: platformManifest.version,
        versions: {
          for (final key in currentPaths.keys) key: platformManifest.version,
        },
        paths: currentPaths,
        lastUpdated: DateTime.now(),
      );
      await _writeState(newState);

      onProgress?.call(1.0, 'Tools installed');
      return ToolInstallState(
        installed: true,
        healthy: true,
        statusMessage: 'Tools installed successfully',
        installedPaths: currentPaths,
        installedVersions: newState.versions,
        lastUpdated: newState.lastUpdated,
      );
    } catch (e) {
      if (await stagingDir.exists()) {
        await stagingDir.delete(recursive: true);
      }
      return ToolInstallState.missing('Install failed: $e');
    }
  }

  @override
  Future<Map<String, String>> currentVersions() async {
    final state = await _readState();
    return state?.versions ?? const {};
  }

  @override
  Future<bool> verifyIntegrity() async {
    if (_isMobilePlatform()) return true;

    final state = await _readState();
    if (state == null) return false;

    final manifest = await _registry.fetchManifest();
    final platformManifest = manifest?.forPlatform(_platformId());
    if (platformManifest == null) return false;

    for (final entry in platformManifest.tools.entries) {
      final installedPath = state.paths[entry.key];
      if (installedPath == null) return false;
      final file = File(installedPath);
      if (!await file.exists()) return false;
      final digest = sha256.convert(await file.readAsBytes()).toString();
      if (digest.toLowerCase() != entry.value.sha256.toLowerCase()) {
        return false;
      }
    }

    return true;
  }

  @override
  Future<String?> getExecutablePath(String toolName) async {
    final state = await _readState();
    final path = state?.paths[toolName];
    if (path != null && await File(path).exists()) {
      return path;
    }
    return null;
  }

  Future<File> _stateFile() async {
    final root = await _toolsRootDir();
    return File(p.join(root.path, _platformId(), 'install_state.json'));
  }

  Future<Directory> _toolsRootDir() async {
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appSupport.path, 'tools'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<void> _downloadFile(String url, String outputPath) async {
    final uri = Uri.parse(url);
    final client = HttpClient();
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Failed to download $url (${response.statusCode})');
    }

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await response.pipe(file.openWrite());
  }

  Future<_LocalToolState?> _readState() async {
    try {
      final file = await _stateFile();
      if (!await file.exists()) return null;
      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _LocalToolState.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeState(_LocalToolState state) async {
    final file = await _stateFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(state.toJson()));
  }

  bool _isMobilePlatform() => Platform.isAndroid || Platform.isIOS;

  String _platformId() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}

class _LocalToolState {
  const _LocalToolState({
    required this.version,
    required this.versions,
    required this.paths,
    required this.lastUpdated,
  });

  final String version;
  final Map<String, String> versions;
  final Map<String, String> paths;
  final DateTime lastUpdated;

  factory _LocalToolState.fromJson(Map<String, dynamic> json) {
    return _LocalToolState(
      version: json['version'] as String? ?? '',
      versions: Map<String, String>.from(json['versions'] as Map? ?? const {}),
      paths: Map<String, String>.from(json['paths'] as Map? ?? const {}),
      lastUpdated:
          DateTime.tryParse(json['lastUpdated'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'versions': versions,
      'paths': paths,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
