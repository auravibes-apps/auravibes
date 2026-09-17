// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:auravibes_app/services/log_redaction.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final _logger = Logger('app_logging');

class AppLogging._() {
  static bool _configured = false;
  static StreamSubscription<LogRecord>? _subscription;

  static void configure({
    required bool enabled,
    void Function(String log)? onLog,
  }) {
    if (_configured || !enabled) return;
    _configured = true;

    Logger.root.level = .ALL;
    _subscription = Logger.root.onRecord.listen(
      (record) => _handleRecord(record, onLog),
    );
    _configureFlutterErrorHandler();
    _configurePlatformErrorHandler();
  }

  @visibleForTesting
  static void resetForTesting() {
    _configured = false;
    _subscription?.cancel();
    _subscription = null;
  }

  static void _configureFlutterErrorHandler() {
    final previousFlutterError = FlutterError.onError;
    FlutterError.onError = (details) =>
        _handleFlutterError(details, previousFlutterError);
  }

  static void _handleFlutterError(
    FlutterErrorDetails details,
    FlutterExceptionHandler? previousHandler,
  ) {
    _logger.severe('Flutter error', details.exception, details.stack);
    (previousHandler ?? FlutterError.presentError)(details);
  }

  static void _configurePlatformErrorHandler() {
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      _logger.severe('Uncaught platform error', error, stackTrace);

      return false;
    };
  }

  static void _handleRecord(
    LogRecord record,
    void Function(String log)? onLog,
  ) {
    final logLine = _logLine(record);
    debugPrint(logLine);
    onLog?.call(logLine);
    _printRecordValue('Error', record.error, onLog);
    _printRecordValue('StackTrace', record.stackTrace, onLog);
  }

  static String _logLine(LogRecord record) =>
      '[${record.time.toIso8601String()}] [${record.level.name}] '
      '${record.loggerName}: ${LogRedaction.redact(record.message)}';

  static void _printRecordValue(
    String label,
    Object? value,
    void Function(String log)? onLog,
  ) {
    if (value == null) return;
    final line = '$label: ${LogRedaction.redact(value)}';
    debugPrint(line);
    onLog?.call(line);
  }
}
