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
  });
}
