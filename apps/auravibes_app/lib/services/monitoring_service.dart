import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';

class MonitoringService {
  MonitoringService({
    DebugPrintCallback? debugLogger,
    this.enableConsoleLogging = kDebugMode,
  }) : _debugLogger = debugLogger ?? debugPrint;

  final DebugPrintCallback _debugLogger;
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
}

final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  return MonitoringService();
});
