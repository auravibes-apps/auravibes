import 'dart:ui';

import 'package:auravibes_app/services/app_logging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  group('AppLogging', () {
    final logs = <String>[];
    var previousDebugPrint = debugPrint;
    FlutterExceptionHandler? previousFlutterError;
    ErrorCallback? previousPlatformError;

    setUp(() {
      logs.clear();
      AppLogging.resetForTesting();
      previousDebugPrint = debugPrint;
      previousFlutterError = FlutterError.onError;
      previousPlatformError = PlatformDispatcher.instance.onError;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) logs.add(message);
      };
    });

    tearDown(() {
      debugPrint = previousDebugPrint;
      FlutterError.onError = previousFlutterError;
      PlatformDispatcher.instance.onError = previousPlatformError;
    });

    test('does not configure logging when disabled', () {
      AppLogging.configure(enabled: false);
      Logger('test.disabled').info('hidden');

      expect(logs, isEmpty);
    });

    test('records log messages with error and stack trace', () async {
      AppLogging.configure(enabled: true);

      Logger(
        'test.logger',
      ).severe('failed', StateError('bad'), StackTrace.current);
      await Future<void>.delayed(Duration.zero);

      expect(logs, anyElement(contains('[SEVERE] test.logger: failed')));
      expect(logs, anyElement(contains('Error: Bad state: bad')));
      expect(logs, anyElement(contains('StackTrace:')));
    });

    test('redacts credential-like values', () async {
      AppLogging.configure(enabled: true);

      Logger('test.logger').warning(
        'Authorization: Bearer secret-token api_key=abc123',
      );
      await Future<void>.delayed(Duration.zero);

      expect(logs.join('\n'), isNot(contains('secret-token')));
      expect(logs.join('\n'), isNot(contains('abc123')));
      expect(logs.join('\n'), contains('[REDACTED]'));
    });

    test('logs Flutter errors and forwards to previous handler', () async {
      var forwarded = false;
      FlutterError.onError = (_) {
        forwarded = true;
      };
      AppLogging.configure(enabled: true);

      final flutterErrorHandler = FlutterError.onError;
      if (flutterErrorHandler == null) {
        fail('Expected Flutter error handler');
      }

      flutterErrorHandler(
        FlutterErrorDetails(
          exception: Exception('boom'),
          stack: StackTrace.current,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(forwarded, isTrue);
      expect(logs, anyElement(contains('Flutter error: Exception: boom')));
    });

    test('logs platform errors and keeps them unhandled', () async {
      AppLogging.configure(enabled: true);

      final platformErrorHandler = PlatformDispatcher.instance.onError;
      if (platformErrorHandler == null) {
        fail('Expected platform error handler');
      }

      final handled = platformErrorHandler(
        Exception('platform boom'),
        StackTrace.current,
      );
      await Future<void>.delayed(Duration.zero);

      expect(handled, isFalse);
      expect(logs, anyElement(contains('Uncaught platform error')));
    });
  });
}
