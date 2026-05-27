// ignore_for_file: avoid-substring
// Required: Existing parsing uses code-unit substring offsets.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';

class MonitoringService {
  MonitoringService({
    ValueSetter<String>? debugLogger,
    this.enableConsoleLogging = kDebugMode,
  }) : _debugLogger = debugLogger ?? _defaultDebugLogger;

  final ValueSetter<String> _debugLogger;
  final bool enableConsoleLogging;

  void trackError(
    String concept, {
    required Object? error,
    required StackTrace stackTrace,
  }) {
    if (!enableConsoleLogging) {
      return;
    }

    _debugLogger('Monitoring error [$concept]');
    _debugLogger('Error: ${_sanitize(error)}');
    _debugLogger('StackTrace: ${_sanitize(stackTrace)}');
    // Implement error tracking logic here, e.g. send to Sentry.
  }

  String _sanitize(Object? value) {
    final normalized = '$value'.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (normalized.length <= _maxLogFieldLength) {
      return normalized;
    }

    return '${normalized.substring(0, _maxLogFieldLength)}...';
  }

  static const _maxLogFieldLength = 500;

  static void _defaultDebugLogger(String message) {
    debugPrint(message);
  }
}

final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  return MonitoringService();
});
