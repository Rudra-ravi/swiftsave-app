import 'package:flutter_test/flutter_test.dart';
import 'package:open_filex/open_filex.dart';
import 'package:swiftsave/services/file_opener_service.dart';

void main() {
  group('FileOpenerService.openAndScan', () {
    tearDown(() {
      FileOpenerService.resetOverrides();
    });

    test('opens file even when media scan fails', () async {
      var scanAttempted = false;
      var openAttempted = false;

      FileOpenerService.scanFileOverride = (_) async {
        scanAttempted = true;
        throw Exception('scan failed');
      };
      FileOpenerService.openFileOverride = (_) async {
        openAttempted = true;
        return OpenResult(type: ResultType.done, message: 'done');
      };

      final result = await FileOpenerService.openAndScan('/tmp/media.mp4');

      expect(scanAttempted, isTrue);
      expect(openAttempted, isTrue);
      expect(FileOpenerService.isSuccess(result), isTrue);
    });
  });
}
