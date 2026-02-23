import 'package:flutter_test/flutter_test.dart';
import 'package:swiftsave/services/engine/parsers/ytdlp_progress_parser.dart';

void main() {
  group('YtDlpProgressParser', () {
    final parser = YtDlpProgressParser();

    test('parses valid progress line', () {
      const line = 'progress:task-1|25.0%|1048576|4194304|1.0MiB/s|00:03';
      final event = parser.parse(line);

      expect(event, isNotNull);
      expect(event!.taskId, 'task-1');
      expect(event.progress, closeTo(0.25, 0.0001));
      expect(event.downloadedBytes, 1048576);
      expect(event.totalBytes, 4194304);
      expect(event.speed, '1.0MiB/s');
      expect(event.eta, '00:03');
    });

    test('returns null for unknown line', () {
      expect(parser.parse('[download]  25% ...'), isNull);
    });

    test('accepts NA fields', () {
      const line = 'progress:task-2|NA|NA|NA|NA|NA';
      final event = parser.parse(line);

      expect(event, isNotNull);
      expect(event!.taskId, 'task-2');
      expect(event.progress, isNull);
      expect(event.downloadedBytes, isNull);
      expect(event.totalBytes, isNull);
      expect(event.speed, isNull);
      expect(event.eta, isNull);
    });
  });
}
