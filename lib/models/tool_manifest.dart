class ToolBinaryManifest {
  final String name;
  final String fileName;
  final String url;
  final String sha256;
  final bool executable;

  const ToolBinaryManifest({
    required this.name,
    required this.fileName,
    required this.url,
    required this.sha256,
    required this.executable,
  });

  factory ToolBinaryManifest.fromJson(String name, Map<String, dynamic> json) {
    return ToolBinaryManifest(
      name: name,
      fileName: json['fileName'] as String,
      url: json['url'] as String,
      sha256: (json['sha256'] as String).toLowerCase(),
      executable: json['executable'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'url': url,
      'sha256': sha256,
      'executable': executable,
    };
  }
}

class PlatformToolManifest {
  final String version;
  final Map<String, ToolBinaryManifest> tools;

  const PlatformToolManifest({required this.version, required this.tools});

  factory PlatformToolManifest.fromJson(Map<String, dynamic> json) {
    final rawTools = (json['tools'] as Map<String, dynamic>? ?? {});
    final parsed = <String, ToolBinaryManifest>{};
    for (final entry in rawTools.entries) {
      parsed[entry.key] = ToolBinaryManifest.fromJson(
        entry.key,
        entry.value as Map<String, dynamic>,
      );
    }

    return PlatformToolManifest(
      version: json['version'] as String,
      tools: parsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'tools': tools.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

class ToolManifest {
  final String generatedAt;
  final String minimumAppVersion;
  final Map<String, PlatformToolManifest> platforms;

  const ToolManifest({
    required this.generatedAt,
    required this.minimumAppVersion,
    required this.platforms,
  });

  factory ToolManifest.fromJson(Map<String, dynamic> json) {
    final rawPlatforms = (json['platforms'] as Map<String, dynamic>? ?? {});
    final parsed = <String, PlatformToolManifest>{};

    for (final entry in rawPlatforms.entries) {
      parsed[entry.key] = PlatformToolManifest.fromJson(
        entry.value as Map<String, dynamic>,
      );
    }

    return ToolManifest(
      generatedAt: json['generatedAt'] as String? ?? '',
      minimumAppVersion: json['minimumAppVersion'] as String? ?? '0.0.0',
      platforms: parsed,
    );
  }

  PlatformToolManifest? forPlatform(String platform) => platforms[platform];

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt,
      'minimumAppVersion': minimumAppVersion,
      'platforms': platforms.map((k, v) => MapEntry(k, v.toJson())),
    };
  }
}
