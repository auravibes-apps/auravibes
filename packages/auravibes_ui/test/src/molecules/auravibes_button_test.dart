import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/molecules/aura_button.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraButton', () {
    testWidgets('renders button with text correctly', (tester) async {
      const buttonText = 'Click me';
      var wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraButton(
              onPressed: () => wasPressed = true,
              child: const Text(buttonText),
            ),
          ),
        ),
      );

      expect(find.text(buttonText), findsOneWidget);
      // Check for the actual widget structure: Material -> InkWell ->.
      // AnimatedContainer.

      await tester.tap(find.byType(AuraButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('applies ghost variant styling correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraButton(
              onPressed: () {
                final _ = Object();
              },
              child: const Text('Ghost'),
              variant: AuraButtonVariant.ghost,
            ),
          ),
        ),
      );

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      final decoration =
          (animatedContainer.decoration ??
                  fail('Expected animatedContainer.decoration to be non-null'))
              as BoxDecoration;
      expect(decoration.color, Colors.transparent);
      expect(decoration.border, isNull);
    });

    testWidgets('shows loading spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraButton(
              onPressed: () {
                final _ = Object();
              },
              child: const Text('Loading'),
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(AuraLoadingCircle), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('disables button when isLoading is true', (tester) async {
      var wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraButton(
              onPressed: () => wasPressed = true,
              child: const Text('Loading'),
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuraButton));
      expect(wasPressed, isFalse);
    });

    testWidgets('applies full width when isFullWidth is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraButton(
              onPressed: () {
                final _ = Object();
              },
              child: const Text('Full Width'),
              isFullWidth: true,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(AnimatedContainer),
              matching: find.byType(SizedBox),
            )
            .first,
      );

      expect(sizedBox.width, double.infinity);
    });

    testWidgets('applies correct text styling based on size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraButton(
              onPressed: () {
                final _ = Object();
              },
              child: const Text('Large Button'),
              size: AuraButtonSize.large,
            ),
          ),
        ),
      );

      final defaultTextStyle = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Large Button'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );

      expect(
        defaultTextStyle.style.fontSize,
        AuraTheme.light.typography.fontSizeLg,
      );
      expect(
        defaultTextStyle.style.fontWeight,
        AuraTheme.light.typography.fontWeightSemibold,
      );
    });

    group('AuraButtonVariant enum', () {
      test('has all expected values', () {
        expect(AuraButtonVariant.values, hasLength(6));
        expect(AuraButtonVariant.values, contains(AuraButtonVariant.primary));
        expect(AuraButtonVariant.values, contains(AuraButtonVariant.secondary));
        expect(AuraButtonVariant.values, contains(AuraButtonVariant.outlined));
        expect(AuraButtonVariant.values, contains(AuraButtonVariant.ghost));
        expect(AuraButtonVariant.values, contains(AuraButtonVariant.elevated));
        expect(AuraButtonVariant.values, contains(AuraButtonVariant.text));
      });
    });

    group('AuraButtonSize enum', () {
      test('has all expected values', () {
        expect(AuraButtonSize.values, hasLength(3));
        expect(AuraButtonSize.values, contains(AuraButtonSize.small));
        expect(AuraButtonSize.values, contains(AuraButtonSize.medium));
        expect(AuraButtonSize.values, contains(AuraButtonSize.large));
      });
    });
  });
}
