// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final _logger = Logger('app_logging');

class AppLogBuffer {
  AppLogBuffer._();

  static final AppLogBuffer instance = AppLogBuffer._();

  static const _maxEntries = 300;

  final List<String> _entries = [];

  void add(String entry) {
    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
  }

  String dump() => _entries.join('\n');

  @visibleForTesting
  void clear() => _entries.clear();
}

class AppLogging {
  AppLogging._();

  static bool _configured = false;
  static StreamSubscription<LogRecord>? _subscription;

  static void configure({required bool enabled}) {
    if (_configured || !enabled) return;
    _configured = true;

    Logger.root.level = Level.ALL;
    _subscription = Logger.root.onRecord.listen(_handleRecord);

    final previousFlutterError = FlutterError.onError;
    FlutterError.onError = (details) {
      _logger.severe(
        'Flutter error: ${details.exceptionAsString()}',
        details.exception,
        details.stack,
      );
      if (previousFlutterError != null) {
        previousFlutterError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      _logger.severe('Uncaught platform error', error, stackTrace);

      return false;
    };
  }

  static void _handleRecord(LogRecord record) {
    final timestamp = record.time.toIso8601String();
    final line =
        '[$timestamp] [${record.level.name}] ${record.loggerName}: '
        '${record.message}';
    AppLogBuffer.instance.add(line);
    debugPrint(line);

    if (record.error != null) {
      final errorLine = 'Error: ${record.error}';
      AppLogBuffer.instance.add(errorLine);
      debugPrint(errorLine);
    }

    if (record.stackTrace != null) {
      final stackLine = 'StackTrace: ${record.stackTrace}';
      AppLogBuffer.instance.add(stackLine);
      debugPrint(stackLine);
    }
  }

  @visibleForTesting
  static void resetForTesting() {
    _configured = false;
    _subscription?.cancel();
    _subscription = null;
  }
}
