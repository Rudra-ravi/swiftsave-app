import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/tool_manifest.dart';

class ToolRegistryService {
  static const String _defaultManifestUrl = String.fromEnvironment(
    'TOOLS_MANIFEST_URL',
    defaultValue: '',
  );

  Future<ToolManifest?> fetchManifest({Uri? uri}) async {
    final targetUri = uri ?? _resolveDefaultUri();
    if (targetUri == null) {
      return readCachedManifest();
    }

    try {
      final client = HttpClient();
      final request = await client.getUrl(targetUri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return readCachedManifest();
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final manifest = ToolManifest.fromJson(decoded);
      await cacheManifest(manifest);
      return manifest;
    } catch (_) {
      return readCachedManifest();
    }
  }

  Future<ToolManifest?> readCachedManifest() async {
    try {
      final file = await _manifestCacheFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      return ToolManifest.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheManifest(ToolManifest manifest) async {
    final file = await _manifestCacheFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(manifest.toJson()));
  }

  Uri? _resolveDefaultUri() {
    if (_defaultManifestUrl.isEmpty) return null;
    return Uri.tryParse(_defaultManifestUrl);
  }

  Future<File> _manifestCacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'tools', 'tools-manifest.json'));
  }
}
