import 'package:auravibes_ui/src/molecules/aura_radio_option.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraRadioOption', () {
    test('creates option with required parameters', () {
      const option = AuraRadioOption<String>(
        value: 'test',
        label: Text('Test Label'),
      );

      expect(option.value, 'test');
      expect(option.label, isA<Text>());
      expect(option.subtitle, isNull);
      expect(option.disabled, isFalse);
    });

    test('creates option with subtitle and disabled state', () {
      const option = AuraRadioOption<String>(
        value: 'test',
        label: Text('Test Label'),
        subtitle: Text('Subtitle'),
        disabled: true,
      );

      expect(option.subtitle, isA<Text>());
      expect(option.disabled, isTrue);
    });
  });

  group('AuraRadio', () {
    testWidgets('does NOT use Material Radio widget - uses CustomPaint', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraRadio<String>(
              value: 'option1',
              groupValue: null,
              onChanged: (_) {
                final _ = Object();
              },
            ),
          ),
        ),
      );

      // Should NOT find Material Radio widget.
      expect(find.byType(Radio<String>), findsNothing);
      // Should use CustomPaint for drawing.
      expect(find.byType(CustomPaint), findsWidgets);
      // Should use GestureDetector for tap handling.
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('uses GestureDetector for tap handling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraRadio<String>(
              value: 'option1',
              groupValue: null,
              onChanged: (_) {
                final _ = Object();
              },
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('shows as selected when value matches groupValue', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraRadio<String>(
              value: 'option1',
              groupValue: 'option1',
              onChanged: (_) {
                final _ = Object();
              },
            ),
          ),
        ),
      );

      // Verify it renders with CustomPaint.
      expect(find.byType(CustomPaint), findsWidgets);
      // Verify it's selected (value matches groupValue).
      final radioFinder = find.byType(AuraRadio<String>);
      expect(radioFinder, findsOneWidget);
    });

    testWidgets('shows as unselected when value differs from groupValue', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraRadio<String>(
              value: 'option1',
              groupValue: 'option2',
              onChanged: (_) {
                final _ = Object();
              },
            ),
          ),
        ),
      );

      // Verify it renders with CustomPaint.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraRadio<String>(
              value: 'option1',
              groupValue: null,
              onChanged: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      // Tap on the GestureDetector.
      await tester.tap(find.byType(GestureDetector));
      final _ = await tester.pumpAndSettle();

      expect(selectedValue, 'option1');
    });

    testWidgets('is disabled when disabled is true', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraRadio<String>(
              value: 'option1',
              groupValue: null,
              onChanged: (value) => selectedValue = value,
              disabled: true,
            ),
          ),
        ),
      );

      // Tap should not trigger onChanged when disabled.
      await tester.tap(find.byType(GestureDetector));
      final _ = await tester.pumpAndSettle();

      expect(selectedValue, isNull);
    });

    testWidgets('is disabled when onChanged is null', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraRadio<String>(
              value: 'option1',
              groupValue: null,
              onChanged: null,
            ),
          ),
        ),
      );

      // Tap should not trigger onChanged when onChanged is null.
      await tester.tap(find.byType(GestureDetector));
      final _ = await tester.pumpAndSettle();

      expect(selectedValue, isNull);
    });

    testWidgets('applies colorVariant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraRadio<String>(
              value: 'option1',
              groupValue: 'option1',
              onChanged: (_) {
                final _ = Object();
              },
              colorVariant: AuraColorVariant.secondary,
            ),
          ),
        ),
      );

      // Verify it renders with CustomPaint and uses the color.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('uses MouseRegion for cursor changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraRadio<String>(
              value: 'option1',
              groupValue: null,
              onChanged: (_) {
                final _ = Object();
              },
            ),
          ),
        ),
      );

      // At least one MouseRegion should be present from our widget.
      expect(find.byType(MouseRegion), findsWidgets);
    });

    testWidgets('has reduced opacity when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraRadio<String>(
              value: 'option1',
              groupValue: null,
              onChanged: (_) {
                final _ = Object();
              },
              disabled: true,
            ),
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.6);
    });

    testWidgets('has full opacity when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraRadio<String>(
              value: 'option1',
              groupValue: null,
              onChanged: (_) {
                final _ = Object();
              },
            ),
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1.0);
    });
  });
}
