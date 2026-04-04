import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';

class MonitoringService {
  void trackError(
    String concept, {
    required Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('Concept: $concept');
    debugPrint('Error: $error');
    debugPrint('StackTrace: $stackTrace');
    // Implement error tracking logic here, e.g. send to Sentry.
  }
}

final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  return MonitoringService();
});
