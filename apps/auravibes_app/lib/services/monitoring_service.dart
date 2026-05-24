import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';

class MonitoringService {
  MonitoringService({
    DebugPrintCallback? debugLogger,
    bool enableConsoleLogging = kDebugMode,
  }) : _debugLogger = debugLogger ?? debugPrint,
       _enableConsoleLogging = enableConsoleLogging;

  final DebugPrintCallback _debugLogger;
  final bool _enableConsoleLogging;

  void trackError(
    String concept, {
    required Object? error,
    required StackTrace stackTrace,
  }) {
    if (!_enableConsoleLogging) {
      return;
    }

    _debugLogger('Monitoring error [$concept]');
    _debugLogger('Error: ${_sanitize(error)}');
    _debugLogger('StackTrace: ${_sanitize(stackTrace)}');
    // Implement error tracking logic here, e.g. send to Sentry.
  }

  static const _maxLogFieldLength = 500;

  String _sanitize(Object? value) {
    final normalized = '$value'.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (normalized.length <= _maxLogFieldLength) {
      return normalized;
    }

    return '${normalized.substring(0, _maxLogFieldLength)}...';
  }
}

final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  return MonitoringService();
});
