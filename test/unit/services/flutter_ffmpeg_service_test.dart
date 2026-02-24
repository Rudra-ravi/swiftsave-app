import 'package:flutter_test/flutter_test.dart';
import 'package:swiftsave/services/flutter_ffmpeg_service.dart';

void main() {
  group('FlutterFFmpegService statistics gating', () {
    test('disables statistics when duration is missing', () {
      final enabled = FlutterFFmpegService.shouldEnableStatistics(
        onProgress: (_) {},
        totalDurationMs: null,
      );

      expect(enabled, isFalse);
    });

    test('enables statistics when callback and duration are present', () {
      final enabled = FlutterFFmpegService.shouldEnableStatistics(
        onProgress: (_) {},
        totalDurationMs: 10_000,
      );

      expect(enabled, isTrue);
    });
  });

  group('FlutterFFmpegService.cancelTask', () {
    final service = FlutterFFmpegService.instance;

    tearDown(() {
      service.resetTestingHooks();
    });

    test('cancels task-scoped session id', () async {
      int? cancelledSessionId;
      service.trackSessionForTest('task-1', 42);
      service.cancelRunner = ([int? sessionId]) async {
        cancelledSessionId = sessionId;
      };

      await service.cancelTask('task-1');

      expect(cancelledSessionId, 42);
      expect(service.hasActiveSessionForTest('task-1'), isFalse);
    });

    test('is a no-op when task has no active session', () async {
      var cancelled = false;
      service.cancelRunner = ([int? sessionId]) async {
        cancelled = true;
      };

      await service.cancelTask('missing-task');

      expect(cancelled, isFalse);
    });
  });
}
