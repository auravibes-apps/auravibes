import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonitoringService', () {
    test('trackError does not throw', () {
      final service = MonitoringService();

      expect(
        () => service.trackError(
          'test_concept',
          error: Exception('test error'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('trackError handles null error', () {
      final service = MonitoringService();

      expect(
        () => service.trackError(
          'test_concept',
          error: null,
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('trackError handles stackTrace', () {
      final service = MonitoringService();

      expect(
        () => service.trackError(
          'test_concept',
          error: Exception('test'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('trackError does not log when console logging disabled', () {
      final messages = <String>[];
      MonitoringService(
        debugLogger: messages.add,
        enableConsoleLogging: false,
      ).trackError(
        'test_concept',
        error: Exception('secret token'),
        stackTrace: StackTrace.current,
      );

      expect(messages, isEmpty);
    });

    test('trackError sanitizes multiline payloads', () {
      final messages = <String>[];
      MonitoringService(
        debugLogger: messages.add,
      ).trackError(
        'stream_failure',
        error: Exception('line 1\nline 2'),
        stackTrace: StackTrace.fromString('frame 1\nframe 2'),
      );

      expect(
        messages,
        equals([
          'Monitoring error [stream_failure]',
          'Error: Exception: line 1 line 2',
          'StackTrace: frame 1 frame 2',
        ]),
      );
    });
  });
}
