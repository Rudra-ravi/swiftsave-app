import 'package:flutter_test/flutter_test.dart';
import 'package:swiftsave/utils/path_sanitizer.dart';

void main() {
  group('PathSanitizer', () {
    test('should keep safe filenames unchanged', () {
      expect(PathSanitizer.sanitizeFilename('my_video.mp4'), 'my_video.mp4');
      expect(
        PathSanitizer.sanitizeFilename('document-final.pdf'),
        'document-final.pdf',
      );
    });

    test('should replace illegal characters with underscores', () {
      // Windows illegal chars: < > : " / \ | ? *
      expect(
        PathSanitizer.sanitizeFilename('video:title?.mp4'),
        'video_title_.mp4',
      );
      expect(
        PathSanitizer.sanitizeFilename('cool<video>.mkv'),
        'cool_video_.mkv',
      );
      expect(PathSanitizer.sanitizeFilename('pipe|test.mp4'), 'pipe_test.mp4');
      expect(
        PathSanitizer.sanitizeFilename('quote"test.mp4'),
        'quote_test.mp4',
      );
    });

    test('should prevent directory traversal attacks', () {
      // Classic traversal
      expect(PathSanitizer.sanitizeFilename('../../etc/passwd'), '_etc_passwd');

      // Windows style
      expect(PathSanitizer.sanitizeFilename('..\\..\\windows'), '_windows');

      // Just dots collapse to underscore
      expect(PathSanitizer.sanitizeFilename('..'), '_');
    });

    test('should handle empty or whitespace strings', () {
      final result = PathSanitizer.sanitizeFilename('');
      expect(result, startsWith('untitled_'));

      final resultSpace = PathSanitizer.sanitizeFilename('   ');
      expect(resultSpace, startsWith('download_'));
    });

    test('should truncate overly long filenames', () {
      final longName = 'a' * 300 + '.mp4';
      final sanitized = PathSanitizer.sanitizeFilename(longName);
      expect(sanitized.length, lessThanOrEqualTo(200));
    });

    test('should remove leading/trailing dots and spaces', () {
      expect(PathSanitizer.sanitizeFilename(' .hidden. '), '.hidden.');
      expect(PathSanitizer.sanitizeFilename('file. '), 'file.');
    });

    test('should collapse multiple underscores', () {
      expect(PathSanitizer.sanitizeFilename('bad___name.mp4'), 'bad_name.mp4');
    });
  });
}
