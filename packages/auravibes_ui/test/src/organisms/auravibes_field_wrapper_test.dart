// Required: Tests use fixed widget dimensions.

import 'package:auravibes_ui/src/organisms/aura_field_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraFieldWrapper', () {
    testWidgets('renders label, hint, and child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFieldWrapper(
              child: SizedBox(width: 20, height: 20),
              label: Text('Field label'),
              hint: Text('Helpful hint'),
            ),
          ),
        ),
      );

      expect(find.text('Field label'), findsOneWidget);
      expect(find.text('Helpful hint'), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders error state and handles tap', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraFieldWrapper(
              child: const SizedBox(
                key: Key('field-child'),
                width: 20,
                height: 20,
              ),
              error: const Text('Required'),
              state: AuraFieldState.error,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const Key('field-child')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
      expect(taps, 1);
    });

    testWidgets('does not call tap when disabled', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraFieldWrapper(
              child: const SizedBox(
                key: Key('field-child'),
                width: 20,
                height: 20,
              ),
              isEnabled: false,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const Key('field-child')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(taps, 0);
    });
  });
}
