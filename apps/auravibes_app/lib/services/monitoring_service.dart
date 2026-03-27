import 'package:riverpod/riverpod.dart';

class MonitoringService {
  void trackError(
    String concept, {
    required Object error,
    StackTrace? stackTrace,
  }) {
    print('Concept: $concept');
    print('Error: $error');
    print('StackTrace: $stackTrace');
    // Implement error tracking logic here, e.g., send to Sentry or Firebase Crashlytics
  }
}

final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  return MonitoringService();
});
