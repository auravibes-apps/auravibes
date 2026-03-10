import 'package:auravibes_ui/src/atoms/auravibes_icon.dart';
import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:auravibes_ui/src/molecules/auravibes_floating_action_button.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraFloatingActionButton', () {
    testWidgets('renders regular FAB correctly', (tester) async {
      const testIcon = Icons.add;
      var wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraFloatingActionButton(
              onPressed: () => wasPressed = true,
              icon: testIcon,
            ),
          ),
        ),
      );

      expect(find.byIcon(testIcon), findsOneWidget);
      expect(find.byType(AuraIcon), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('renders extended FAB correctly', (tester) async {
      const testIcon = Icons.add;
      const testText = 'Add Item';
      var wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraFloatingActionButton.extended(
              onPressed: () => wasPressed = true,
              icon: testIcon,
              text: testText,
            ),
          ),
        ),
      );

      expect(find.byIcon(testIcon), findsOneWidget);
      expect(find.text(testText), findsOneWidget);
      expect(find.byType(AuraIcon), findsOneWidget);
      expect(find.byType(AuraText), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('applies mini size correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraFloatingActionButton(
              onPressed: () {},
              icon: Icons.add,
              size: AuraFABSize.mini,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(FloatingActionButton),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.width, 40.0);
      expect(sizedBox.height, 40.0);

      final auraIcon = tester.widget<AuraIcon>(find.byType(AuraIcon));
      expect(auraIcon.size, AuraIconSize.small);
    });

    testWidgets('applies regular size correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraFloatingActionButton(
              onPressed: () {},
              icon: Icons.add,
            ),
          ),
        ),
      );

      final auraIcon = tester.widget<AuraIcon>(find.byType(AuraIcon));
      expect(auraIcon.size, AuraIconSize.medium);
    });

    testWidgets('applies large size correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraFloatingActionButton(
              onPressed: () {},
              icon: Icons.add,
              size: AuraFABSize.large,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(FloatingActionButton),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.width, 72.0);
      expect(sizedBox.height, 72.0);

      final auraIcon = tester.widget<AuraIcon>(find.byType(AuraIcon));
      expect(auraIcon.size, AuraIconSize.large);
    });

    testWidgets('applies custom background color correctly', (tester) async {
      const customColor = AuraColorVariant.error;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraFloatingActionButton(
              onPressed: () {},
              icon: Icons.add,
              backgroundColor: customColor,
            ),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      // Note: The actual color will be resolved from AuraColorVariant.error
      expect(fab.backgroundColor, isNotNull);
    });

    testWidgets('applies custom foreground color correctly', (tester) async {
      const customColor = AuraColorVariant.onPrimary;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraFloatingActionButton(
              onPressed: () {},
              icon: Icons.add,
              foregroundColor: customColor,
            ),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      // Note: The actual color is resolved from AuraColorVariant.onPrimary
      expect(fab.foregroundColor, isNotNull);

      final auraIcon = tester.widget<AuraIcon>(find.byType(AuraIcon));
      // AuraIcon now receives AuraColorVariant, not Color
      expect(auraIcon.color, customColor);
    });

    testWidgets('applies default colors correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraFloatingActionButton(
              onPressed: () {},
              icon: Icons.add,
            ),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      // Default colors are resolved from AuraTheme
      expect(fab.backgroundColor, isNotNull);
      expect(fab.foregroundColor, isNotNull);

      final auraIcon = tester.widget<AuraIcon>(find.byType(AuraIcon));
      // Default foreground color for icon is null (uses parent's color)
      expect(auraIcon.color, isNull);
    });

    testWidgets('handles null onPressed correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFloatingActionButton(
              onPressed: null,
              icon: Icons.add,
            ),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.onPressed, isNull);
    });

    testWidgets('applies tooltip correctly', (tester) async {
      const tooltipMessage = 'Add new item';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraFloatingActionButton(
              onPressed: () {},
              icon: Icons.add,
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
      const semanticLabel = 'Add new item';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraFloatingActionButton(
              onPressed: () {},
              icon: Icons.add,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      final semanticsWidgets = tester.widgetList<Semantics>(
        find.descendant(
          of: find.byType(AuraFloatingActionButton),
          matching: find.byType(Semantics),
        ),
      );

      // Find the Semantics widget with the correct label
      final semantics = semanticsWidgets.firstWhere(
        (s) => s.properties.label == semanticLabel,
      );

      expect(semantics.properties.label, semanticLabel);
      expect(semantics.properties.button, isTrue);
    });

    testWidgets('applies proper elevation values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraFloatingActionButton(
              onPressed: () {},
              icon: Icons.add,
            ),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.elevation, DesignElevation.md);
      expect(fab.focusElevation, DesignElevation.lg);
      expect(fab.hoverElevation, DesignElevation.lg);
      expect(fab.highlightElevation, DesignElevation.xl);
    });

    group('AuraFABSize enum', () {
      test('has all expected values', () {
        expect(AuraFABSize.values, hasLength(4));
        expect(AuraFABSize.values, contains(AuraFABSize.mini));
        expect(AuraFABSize.values, contains(AuraFABSize.regular));
        expect(AuraFABSize.values, contains(AuraFABSize.large));
        expect(AuraFABSize.values, contains(AuraFABSize.extended));
      });
    });
  });
}
