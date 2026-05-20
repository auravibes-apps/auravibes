import 'dart:ui';

import 'package:auravibes_app/services/app_logging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  group('AppLogBuffer', () {
    setUp(AppLogBuffer.instance.clear);

    test('stores and dumps log entries', () {
      AppLogBuffer.instance
        ..add('first')
        ..add('second');

      expect(AppLogBuffer.instance.dump(), 'first\nsecond');
    });

    test('keeps only the latest entries', () {
      for (var i = 0; i < 301; i++) {
        AppLogBuffer.instance.add('entry $i');
      }

      final dump = AppLogBuffer.instance.dump();
      expect(dump, isNot(contains('entry 0')));
      expect(dump, contains('entry 1'));
      expect(dump, contains('entry 300'));
    });
  });

  group('AppLogging', () {
    late DebugPrintCallback previousDebugPrint;
    FlutterExceptionHandler? previousFlutterError;
    ErrorCallback? previousPlatformError;

    setUp(() {
      AppLogBuffer.instance.clear();
      AppLogging.resetForTesting();
      previousDebugPrint = debugPrint;
      previousFlutterError = FlutterError.onError;
      previousPlatformError = PlatformDispatcher.instance.onError;
      debugPrint = (_, {wrapWidth}) {};
    });

    tearDown(() {
      debugPrint = previousDebugPrint;
      FlutterError.onError = previousFlutterError;
      PlatformDispatcher.instance.onError = previousPlatformError;
      AppLogBuffer.instance.clear();
    });

    test('does not configure logging when disabled', () {
      AppLogging.configure(enabled: false);
      Logger('test.disabled').info('hidden');

      expect(AppLogBuffer.instance.dump(), isEmpty);
    });

    test('records log messages with error and stack trace', () async {
      AppLogging.configure(enabled: true);

      Logger(
        'test.logger',
      ).severe('failed', StateError('bad'), StackTrace.current);
      await Future<void>.delayed(Duration.zero);

      final dump = AppLogBuffer.instance.dump();
      expect(dump, contains('[SEVERE] test.logger: failed'));
      expect(dump, contains('Error: Bad state: bad'));
      expect(dump, contains('StackTrace:'));
    });

    test('logs Flutter errors and forwards to previous handler', () async {
      var forwarded = false;
      FlutterError.onError = (_) {
        forwarded = true;
      };
      AppLogging.configure(enabled: true);

      FlutterError.onError!(
        FlutterErrorDetails(
          exception: Exception('boom'),
          stack: StackTrace.current,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(forwarded, isTrue);
      expect(
        AppLogBuffer.instance.dump(),
        contains('Flutter error: Exception: boom'),
      );
    });

    test('logs platform errors and keeps them unhandled', () async {
      AppLogging.configure(enabled: true);

      final handled = PlatformDispatcher.instance.onError!(
        Exception('platform boom'),
        StackTrace.current,
      );
      await Future<void>.delayed(Duration.zero);

      expect(handled, isFalse);
      expect(AppLogBuffer.instance.dump(), contains('Uncaught platform error'));
    });
  });
}
