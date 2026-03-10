import 'package:auravibes_ui/src/atoms/auravibes_icon.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
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
      const customColor = AuraColorVariant.error;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraIcon(
              Icons.star,
              color: customColor,
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      // Note: The actual color will be resolved from AuraColorVariant.error
      expect(iconWidget.color, isNotNull);
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
              onPressed: () {},
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
              onPressed: () {},
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
              onPressed: () {},
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
              onPressed: () {},
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
      const customColor = AuraColorVariant.error;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () {},
              color: customColor,
            ),
          ),
        ),
      );

      final auraIcon = tester.widget<AuraIcon>(find.byType(AuraIcon));
      expect(auraIcon.color, customColor);
    });

    testWidgets('applies custom background color correctly', (tester) async {
      const customBackgroundColor = AuraColorVariant.primary;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () {},
              backgroundColor: customBackgroundColor,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final resolvedColor = iconButton.style?.backgroundColor?.resolve({});
      // In const-first design, backgroundColor is resolved to the theme color
      expect(resolvedColor, isNotNull);
      expect(resolvedColor, AuraTheme.light.colors.primary);
    });

    testWidgets('shows tooltip when provided', (tester) async {
      const tooltipMessage = 'Star button';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () {},
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
              onPressed: () {},
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      final auraIcon = tester.widget<AuraIcon>(find.byType(AuraIcon));
      expect(auraIcon.semanticLabel, semanticLabel);
    });

    testWidgets('disables button when disabled is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraIconButton(
              icon: Icons.star,
              onPressed: () {},
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
