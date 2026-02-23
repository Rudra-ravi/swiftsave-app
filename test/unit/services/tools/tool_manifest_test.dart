import 'package:flutter_test/flutter_test.dart';
import 'package:swiftsave/models/tool_manifest.dart';

void main() {
  group('ToolManifest', () {
    test('parses manifest with platforms and tools', () {
      final manifest = ToolManifest.fromJson({
        'generatedAt': '2026-02-23T10:00:00Z',
        'minimumAppVersion': '1.0.0',
        'platforms': {
          'linux': {
            'version': '2026.02.23',
            'tools': {
              'ytDlp': {
                'fileName': 'yt-dlp',
                'url': 'https://example.com/yt-dlp',
                'sha256': 'abc123',
                'executable': true,
              },
            },
          },
        },
      });

      final linux = manifest.forPlatform('linux');
      expect(linux, isNotNull);
      expect(linux!.version, '2026.02.23');
      expect(linux.tools['ytDlp']?.fileName, 'yt-dlp');
      expect(linux.tools['ytDlp']?.executable, isTrue);
    });
  });
}
