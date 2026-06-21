import 'package:flutter/foundation.dart';

// TODO(sentry): replace debugPrint with real error reporting sink.
void trackError(
  String concept, {
  required Object? error,
  required StackTrace stackTrace,
}) {
  debugPrint('Monitoring error [$concept]');
  debugPrint('Error: $error');
  debugPrint('StackTrace: $stackTrace');
}
