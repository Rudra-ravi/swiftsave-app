import 'package:flutter_test/flutter_test.dart';
import 'package:swiftsave/models/download_task.dart';

void main() {
  group('DownloadTask.primaryFilePath', () {
    DownloadTask buildTask({String? filename, List<String>? filenames}) {
      return DownloadTask(
        url: 'https://example.com/video',
        title: 'Test title',
        formatId: 'best',
        outputPath: '/tmp',
        filename: filename,
        filenames: filenames,
      );
    }

    test('returns filename when present', () {
      final task = buildTask(
        filename: '/downloads/video.mp4',
        filenames: ['/downloads/fallback.mp4'],
      );

      expect(task.primaryFilePath, '/downloads/video.mp4');
    });

    test('falls back to first filenames entry when filename is missing', () {
      final task = buildTask(filenames: ['/downloads/gallery_1.jpg']);

      expect(task.primaryFilePath, '/downloads/gallery_1.jpg');
    });

    test('returns null when no path is available', () {
      final task = buildTask();

      expect(task.primaryFilePath, isNull);
    });
  });
}
