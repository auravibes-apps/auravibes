import 'package:auravibes_app/utils/monitoring.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trackError logs concept, error and stack trace', () {
    final lines = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      lines.add(message ?? '');
    };
    addTearDown(() => debugPrint = original);

    trackError(
      'test-concept',
      error: StateError('boom'),
      stackTrace: StackTrace.current,
    );

    expect(lines, [
      'Monitoring error [test-concept]',
      'Error: Bad state: boom',
      contains('StackTrace:'),
    ]);
  });
}
