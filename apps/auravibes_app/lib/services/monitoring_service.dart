// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/services/log_redaction.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
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
    final normalized = redactLogValue(
      value,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();

    if (normalized.length <= _maxLogFieldLength) {
      return normalized;
    }

    return '${normalized.firstCharacters(_maxLogFieldLength)}...';
  }

  static const _maxLogFieldLength = 500;

  static void _defaultDebugLogger(String message) {
    debugPrint(message);
  }
}

final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  return MonitoringService();
});
