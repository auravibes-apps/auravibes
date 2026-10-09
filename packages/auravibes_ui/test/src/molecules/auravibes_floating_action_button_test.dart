import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/molecules/aura_floating_action_button.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraFloatingActionButton', () {
    testWidgets('renders regular FAB with expected style and behavior', (
      tester,
    ) async {
      const testIcon = Icons.add;
      const tooltipMessage = 'Add new item';
      const semanticLabel = 'Create item';
      var wasPressed = false;

      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            home: Scaffold(
              body: AuraFloatingActionButton(
                onPressed: () => wasPressed = true,
                icon: testIcon,
                semanticLabel: semanticLabel,
                tooltip: tooltipMessage,
              ),
            ),
            theme: ThemeData.light().copyWith(),
          ),
        ),
      );

      expect(find.byIcon(testIcon), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.backgroundColor, isNotNull);
      expect(fab.foregroundColor, isNotNull);
      expect(fab.elevation, DesignElevation.md);
      expect(fab.focusElevation, DesignElevation.lg);
      expect(fab.hoverElevation, DesignElevation.lg);
      expect(fab.highlightElevation, DesignElevation.xl);

      final icon = tester.widget<Icon>(find.byIcon(testIcon));
      expect(icon.size, 20);
      expect(icon.color, AuraTheme.light.colors.onPrimary);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, tooltipMessage);

      final semanticsWidgets = tester.widgetList<Semantics>(
        find.descendant(
          of: find.byType(AuraFloatingActionButton),
          matching: find.byType(Semantics),
        ),
      );
      final semantics = semanticsWidgets.firstWhere(
        (s) => s.properties.label == semanticLabel,
      );
      expect(semantics.properties.label, semanticLabel);
      expect(semantics.properties.button, isTrue);

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
      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(AuraText), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('applies mini and large sizes correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisSize: .min,
              children: [
                AuraFloatingActionButton(
                  onPressed: () {
                    final _ = Object();
                  },
                  icon: Icons.add,
                  key: const ValueKey('mini'),
                  size: .mini,
                  heroTag: null,
                ),
                AuraFloatingActionButton(
                  onPressed: () {
                    final _ = Object();
                  },
                  icon: Icons.remove,
                  key: const ValueKey('large'),
                  size: .large,
                  heroTag: null,
                ),
              ],
            ),
          ),
        ),
      );

      final miniFab = find.descendant(
        of: find.byKey(const ValueKey('mini')),
        matching: find.byType(FloatingActionButton),
      );
      final miniSizedBox = tester.widget<SizedBox>(
        find.ancestor(of: miniFab, matching: find.byType(SizedBox)),
      );

      expect(miniSizedBox.width, 40.0);
      expect(miniSizedBox.height, 40.0);

      final largeFab = find.descendant(
        of: find.byKey(const ValueKey('large')),
        matching: find.byType(FloatingActionButton),
      );
      final largeSizedBox = tester.widget<SizedBox>(
        find.ancestor(of: largeFab, matching: find.byType(SizedBox)),
      );

      expect(largeSizedBox.width, 72.0);
      expect(largeSizedBox.height, 72.0);

      final miniIcon = tester.widget<Icon>(find.byIcon(Icons.add));
      expect(miniIcon.size, 16);

      final largeIcon = tester.widget<Icon>(find.byIcon(Icons.remove));
      expect(largeIcon.size, 24);
    });

    testWidgets('applies custom tint and handles disabled FAB', (tester) async {
      const customColor = AuraTint.error;

      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                mainAxisSize: .min,
                children: [
                  AuraFloatingActionButton(
                    onPressed: () {
                      final _ = Object();
                    },
                    icon: Icons.add,
                    key: const ValueKey('tinted'),
                    tint: customColor,
                    heroTag: null,
                  ),
                  const AuraFloatingActionButton(
                    onPressed: null,
                    icon: Icons.remove,
                    key: ValueKey('disabled'),
                    heroTag: null,
                  ),
                ],
              ),
            ),
            theme: ThemeData.light().copyWith(),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(
        find.descendant(
          of: find.byKey(const ValueKey('tinted')),
          matching: find.byType(FloatingActionButton),
        ),
      );
      // Verify the resolved color matches the theme's error color.
      expect(fab.backgroundColor, AuraTheme.light.colors.error);
      expect(fab.foregroundColor, AuraTheme.light.colors.onError);

      final disabledFab = tester.widget<FloatingActionButton>(
        find.descendant(
          of: find.byKey(const ValueKey('disabled')),
          matching: find.byType(FloatingActionButton),
        ),
      );
      expect(disabledFab.onPressed, isNull);
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
