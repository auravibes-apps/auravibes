import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraIcon', () {
    testWidgets('renders icons at medium and large sizes with a label', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AuraIcon(Icons.star),
                AuraIcon(
                  Icons.star,
                  size: .large,
                  semanticLabel: 'Favorite star',
                ),
              ],
            ),
          ),
        ),
      );

      final icons = tester.widgetList<Icon>(find.byIcon(Icons.star));
      expect(icons.map((icon) => icon.size), [20.0, 24.0]);
      expect(find.bySemanticsLabel('Favorite star'), findsOneWidget);
    });

    group('AuraIconSize enum', () {
      test('has all expected values', () {
        expect(AuraIconSize.values, hasLength(6));
        expect(AuraIconSize.values, contains(AuraIconSize.extraSmall));
        expect(AuraIconSize.values, contains(AuraIconSize.small));
        expect(AuraIconSize.values, contains(AuraIconSize.medium));
        expect(AuraIconSize.values, contains(AuraIconSize.large));
        expect(AuraIconSize.values, contains(AuraIconSize.extraLarge));
        expect(AuraIconSize.values, contains(AuraIconSize.huge));
      });
    });
  });

  group('AuraIconButton', () {
    testWidgets('renders and activates default button with tooltip and label', (
      tester,
    ) async {
      var wasPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () => wasPressed = true,
              semanticLabel: 'Favorite button',
              tooltip: 'Star button',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byType(IconButton))
            .style
            ?.backgroundColor
            ?.resolve({}),
        Colors.transparent,
      );
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message,
        'Star button',
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.star)).semanticLabel,
        'Favorite button',
      );

      await tester.tap(find.byType(AuraIconButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('applies variant styles and disables button', (tester) async {
      void noOp() {
        final _ = Object();
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AuraIconButton(
                  icon: Icons.star,
                  onPressed: noOp,
                  variant: .filled,
                ),
                AuraIconButton(
                  icon: Icons.star,
                  onPressed: noOp,
                  variant: .outlined,
                ),
                AuraIconButton(
                  icon: Icons.star,
                  onPressed: noOp,
                  variant: .elevated,
                ),
                AuraIconButton(
                  icon: Icons.star,
                  onPressed: noOp,
                  disabled: true,
                ),
              ],
            ),
          ),
        ),
      );

      final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
      expect(
        buttons.map((button) => button.style?.backgroundColor?.resolve({})),
        [
          DesignColors.primaryBase,
          Colors.transparent,
          DesignColors.primaryBase,
          Colors.transparent,
        ],
      );
      expect(buttons.elementAt(2).style?.elevation?.resolve({}), 2);
      expect(buttons.last.onPressed, isNull);
    });

    testWidgets('applies tint to icons and button variants', (tester) async {
      const customTint = AuraTint.error;
      void noOp() {
        final _ = Object();
      }

      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const AuraIcon(Icons.favorite, tint: customTint),
                  AuraIconButton(
                    icon: Icons.star,
                    onPressed: noOp,
                    tint: customTint,
                  ),
                  AuraIconButton(
                    icon: Icons.star_border,
                    onPressed: noOp,
                    tint: customTint,
                    variant: .filled,
                  ),
                ],
              ),
            ),
            theme: ThemeData.light().copyWith(),
          ),
        ),
      );

      expect(
        tester.widget<Icon>(find.byIcon(Icons.favorite)).color,
        AuraTheme.light.colors.error,
      );
      final buttons = find.byType(AuraIconButton);
      final ghostIcon = tester.widget<Icon>(
        find.descendant(of: buttons.at(0), matching: find.byType(Icon)),
      );
      expect(ghostIcon.color, AuraTheme.light.colors.error);

      final filledControl = tester.widget<IconButton>(
        find.descendant(of: buttons.at(1), matching: find.byType(IconButton)),
      );
      expect(
        filledControl.style?.backgroundColor?.resolve({}),
        AuraTheme.light.colors.error,
      );
      final filledIcon = tester.widget<Icon>(
        find.descendant(of: buttons.at(1), matching: find.byType(Icon)),
      );
      expect(filledIcon.color, AuraTheme.light.colors.onError);
    });

    testWidgets('custom buttons render, show tooltip, and honor disabled', (
      tester,
    ) async {
      var wasPressed = false;
      const tooltipMessage = 'Expand';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AuraIconButton.custom(
                  child: const AnimatedRotation(
                    child: AuraIcon(Icons.keyboard_arrow_down),
                    turns: 0.5,
                    duration: .new(milliseconds: 200),
                  ),
                  onPressed: () => wasPressed = true,
                  tooltip: tooltipMessage,
                ),
                AuraIconButton.custom(
                  child: const AuraIcon(Icons.keyboard_arrow_up),
                  onPressed: () {
                    final _ = Object();
                  },
                  disabled: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedRotation), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message,
        tooltipMessage,
      );
      final controls = tester.widgetList<IconButton>(find.byType(IconButton));
      expect(controls.firstOrNull?.onPressed, isNotNull);
      expect(controls.last.onPressed, isNull);

      await tester.tap(find.byType(AuraIconButton).first);
      expect(wasPressed, isTrue);
    });

    group('AuraIconButtonVariant enum', () {
      test('has all expected values', () {
        expect(AuraIconButtonVariant.values, hasLength(4));
        expect(
          AuraIconButtonVariant.values,
          contains(AuraIconButtonVariant.ghost),
        );
        expect(
          AuraIconButtonVariant.values,
          contains(AuraIconButtonVariant.filled),
        );
        expect(
          AuraIconButtonVariant.values,
          contains(AuraIconButtonVariant.outlined),
        );
        expect(
          AuraIconButtonVariant.values,
          contains(AuraIconButtonVariant.elevated),
        );
      });
    });
  });
}
