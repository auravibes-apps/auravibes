import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final expected = Platform.environment['CI'] == 'true'
      ? const Duration(seconds: 30)
      : const Duration(minutes: 10);

  test('widget-test binding uses CI timeout only in CI', () {
    expect(
      TestWidgetsFlutterBinding.ensureInitialized().defaultTestTimeout.duration,
      expected,
    );
  });

  testWidgets(
    'accepts an explicit per-test timeout',
    (tester) async {
      await tester.pump();
      expect(tester.binding.defaultTestTimeout.duration, expected);
    },
    // Explicit test timeout must take precedence over binding default.
    timeout: const .new(.new(seconds: 45)),
  );
}
