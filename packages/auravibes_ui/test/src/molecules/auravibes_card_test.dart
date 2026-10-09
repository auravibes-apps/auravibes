import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/molecules/aura_card.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraCard', () {
    testWidgets('renders card styles and interactions', (tester) async {
      var wasTapped = false;
      const semanticLabel = 'Product card';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                mainAxisSize: .min,
                children: [
                  const AuraCard(
                    child: Text('Card Content'),
                    key: ValueKey('default'),
                  ),
                  AuraCard(
                    child: const Text('Tappable Card'),
                    key: const ValueKey('tappable'),
                    onTap: () => wasTapped = true,
                  ),
                  const AuraCard(
                    child: Text('Non-tappable Card'),
                    key: ValueKey('non-tappable'),
                  ),
                  const AuraCard(
                    child: Text('Content'),
                    key: ValueKey('semantic'),
                    semanticLabel: semanticLabel,
                  ),
                  const AuraCard(
                    child: Text('Border Card'),
                    key: ValueKey('border'),
                    style: .border,
                  ),
                  const AuraCard(
                    child: Text('Glass Card'),
                    key: ValueKey('glass'),
                    style: .glass,
                  ),
                  const AuraCard(
                    child: Text('Tinted Card'),
                    key: ValueKey('tinted'),
                    tint: .success,
                  ),
                  const AuraCard(
                    child: Text('Small Padded Card'),
                    key: ValueKey('padded'),
                    padding: .small,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      Finder within(String key, Finder matching) => find.descendant(
        of: find.byKey(ValueKey<String>(key)),
        matching: matching,
      );
      AuraPressable pressable(String key) =>
          tester.widget<AuraPressable>(within(key, find.byType(AuraPressable)));

      expect(find.text('Card Content'), findsOneWidget);
      expect(within('tappable', find.byType(AuraPressable)), findsOneWidget);
      expect(within('non-tappable', find.byType(InkWell)), findsNothing);
      await tester.tap(within('tappable', find.byType(AuraPressable)));
      expect(wasTapped, isTrue);
      expect(find.text('Border Card'), findsOneWidget);
      expect(within('border', find.byType(AuraPressable)), findsOneWidget);
      expect(find.text('Glass Card'), findsOneWidget);
      expect(within('glass', find.byType(BackdropFilter)), findsOneWidget);
      expect(within('glass', find.byType(ClipRRect)), findsOneWidget);

      expect(pressable('default').decoration, isNotNull);

      final semantics = tester
          .widgetList<Semantics>(within('semantic', find.byType(Semantics)))
          .firstWhere(
            (semantics) => semantics.properties.label == semanticLabel,
          );
      expect(semantics.properties.label, semanticLabel);

      final decoration = pressable('tinted').decoration;
      if (decoration is! BoxDecoration) fail('Expected a card decoration.');
      expect(decoration.color, isNot(AuraTheme.light.colors.surface));

      expect(find.text('Small Padded Card'), findsOneWidget);
      final auraPadding = tester.widget<AuraPadding>(
        within('padded', find.byType(AuraPadding)),
      );
      expect(auraPadding.padding, AuraEdgeInsetsGeometry.small);
    });

    test('AuraCardStyle enum has all values', () {
      expect(AuraCardStyle.values, hasLength(3));
      expect(AuraCardStyle.values, contains(AuraCardStyle.elevated));
      expect(AuraCardStyle.values, contains(AuraCardStyle.border));
      expect(AuraCardStyle.values, contains(AuraCardStyle.glass));
    });
  });
}
