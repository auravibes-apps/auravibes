import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/molecules/aura_button.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraButton', () {
    testWidgets('renders, sizes, centers, and activates button', (
      tester,
    ) async {
      const buttonText = 'Click me';
      var wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: Center(
                child: AuraButton(
                  onPressed: () => wasPressed = true,
                  child: const Text(buttonText),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text(buttonText), findsOneWidget);
      final buttonSize = tester.getSize(find.byType(AuraButton));
      expect(buttonSize.width, lessThan(200));
      expect(buttonSize.height, lessThan(100));
      expect(
        tester.getRect(find.text(buttonText)).center.dx,
        closeTo(tester.getRect(find.byType(AuraButton)).center.dx, 0.5),
      );

      await tester.tap(find.byType(AuraButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('keeps enabled and disabled buttons the same size', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                AuraButton(
                  onPressed: () {
                    final _ = Object();
                  },
                  child: const Text('Select all visible'),
                  key: const ValueKey('enabled-button'),
                  size: .small,
                ),
                AuraButton(
                  onPressed: () {
                    final _ = Object();
                  },
                  child: const Text('Select all visible'),
                  key: const ValueKey('disabled-button'),
                  size: .small,
                  disabled: true,
                ),
              ],
            ),
          ),
        ),
      );

      final enabledSize = tester.getSize(
        find.byKey(const ValueKey('enabled-button')),
      );
      final disabledSize = tester.getSize(
        find.byKey(const ValueKey('disabled-button')),
      );

      expect(disabledSize, enabledSize);
      expect(disabledSize.height, greaterThanOrEqualTo(48));
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
              variant: .ghost,
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
      expect(decoration.color?.a, 0);
      expect(decoration.border, isNull);
    });

    testWidgets('shows spinner and blocks taps while loading', (tester) async {
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

      expect(find.byType(AuraLoadingCircle), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
      await tester.tap(find.byType(AuraButton));
      expect(wasPressed, isFalse);
    });

    testWidgets('shows focus ring and activates with enter and space', (
      tester,
    ) async {
      var pressCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraButton(
              onPressed: () => pressCount++,
              child: const Text('Keyboard'),
            ),
          ),
        ),
      );

      final focusRing = find.descendant(
        of: find.byType(AuraButton),
        matching: find.byType(CustomPaint),
      );
      final beforeFocus = tester.widget<CustomPaint>(focusRing);
      expect(beforeFocus.foregroundPainter, isNull);

      expect(await tester.sendKeyEvent(.tab), isTrue);
      await tester.pump();
      expect(pressCount, 0);
      final afterFocus = tester.widget<CustomPaint>(focusRing);
      expect(afterFocus.foregroundPainter, isNotNull);

      expect(await tester.sendKeyEvent(.enter), isTrue);
      await tester.pump();
      expect(pressCount, 1);

      expect(await tester.sendKeyEvent(.space), isTrue);
      await tester.pump();
      expect(pressCount, 2);
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
              size: .large,
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
