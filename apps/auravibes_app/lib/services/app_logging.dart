// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final _logger = Logger('app_logging');

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
    debugPrint(line);

    if (record.error != null) {
      debugPrint('Error: ${record.error}');
    }

    if (record.stackTrace != null) {
      debugPrint('StackTrace: ${record.stackTrace}');
    }
  }

  @visibleForTesting
  static void resetForTesting() {
    _configured = false;
    _subscription?.cancel();
    _subscription = null;
  }
}
