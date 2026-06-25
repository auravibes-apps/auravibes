import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraIcon', () {
    testWidgets('renders icon correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraIcon(Icons.star),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('applies custom color correctly', (tester) async {
      const customColor = AuraTint.error;

      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: AuraIcon(
              Icons.star,
              tint: customColor,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      // Verify the resolved color matches the theme's error color.
      expect(iconWidget.color, AuraTheme.light.colors.error);
    });

    testWidgets('applies medium size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraIcon(
              Icons.star,
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(iconWidget.size, 20.0);
    });

    testWidgets('applies large size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraIcon(
              Icons.star,
              size: AuraIconSize.large,
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(iconWidget.size, 24.0);
    });

    testWidgets('applies semantic label correctly', (tester) async {
      const semanticLabel = 'Favorite star';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraIcon(
              Icons.star,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(semanticLabel), findsOneWidget);
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
    testWidgets('renders icon button correctly', (tester) async {
      var wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);

      await tester.tap(find.byType(AuraIconButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('applies ghost variant styling correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () {
                final _ = Object();
              },
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(
        iconButton.style?.backgroundColor?.resolve({}),
        Colors.transparent,
      );
    });

    testWidgets('applies filled variant styling correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () {
                final _ = Object();
              },
              variant: AuraIconButtonVariant.filled,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(
        iconButton.style?.backgroundColor?.resolve({}),
        DesignColors.primaryBase,
      );
    });

    testWidgets('applies outlined variant styling correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () {
                final _ = Object();
              },
              variant: AuraIconButtonVariant.outlined,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(
        iconButton.style?.backgroundColor?.resolve({}),
        Colors.transparent,
      );
    });

    testWidgets('applies elevated variant styling correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () {
                final _ = Object();
              },
              variant: AuraIconButtonVariant.elevated,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(
        iconButton.style?.backgroundColor?.resolve({}),
        DesignColors.primaryBase,
      );
      expect(iconButton.style?.elevation?.resolve({}), 2);
    });

    testWidgets('applies custom color correctly', (tester) async {
      const customColor = AuraTint.error;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () {
                final _ = Object();
              },
              tint: customColor,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.color, AuraTheme.light.colors.error);
    });

    testWidgets('applies custom tint to filled background', (tester) async {
      const customTint = AuraTint.error;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () {
                final _ = Object();
              },
              tint: customTint,
              variant: AuraIconButtonVariant.filled,
            ),
          ),
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final resolvedColor = iconButton.style?.backgroundColor?.resolve({});
      expect(resolvedColor, isNotNull);
      expect(resolvedColor, AuraTheme.light.colors.error);

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.color, AuraTheme.light.colors.onError);
    });

    testWidgets('shows tooltip when provided', (tester) async {
      const tooltipMessage = 'Star button';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () {
                final _ = Object();
              },
              tooltip: tooltipMessage,
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, tooltipMessage);
    });

    testWidgets('applies semantic label correctly', (tester) async {
      const semanticLabel = 'Favorite button';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () {
                final _ = Object();
              },
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.semanticLabel, semanticLabel);
    });

    testWidgets('disables button when disabled is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () {
                final _ = Object();
              },
              disabled: true,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('custom constructor renders child and handles tap', (
      tester,
    ) async {
      var wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton.custom(
              child: const AnimatedRotation(
                child: AuraIcon(Icons.keyboard_arrow_down),
                turns: 0.5,
                duration: Duration(milliseconds: 200),
              ),
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedRotation), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

      await tester.tap(find.byType(AuraIconButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('custom constructor shows tooltip when provided', (
      tester,
    ) async {
      const tooltipMessage = 'Expand';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton.custom(
              child: const AuraIcon(Icons.keyboard_arrow_down),
              onPressed: () {
                final _ = Object();
              },
              tooltip: tooltipMessage,
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, tooltipMessage);
    });

    testWidgets('custom constructor disables inner icon button', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton.custom(
              child: const AuraIcon(Icons.keyboard_arrow_down),
              onPressed: () {
                final _ = Object();
              },
              disabled: true,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull);
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
