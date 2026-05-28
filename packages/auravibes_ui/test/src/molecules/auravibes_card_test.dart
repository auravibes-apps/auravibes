// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/molecules/aura_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraCard', () {
    testWidgets('renders card with child correctly', (tester) async {
      const testText = 'Card Content';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraCard(
              child: Text(testText),
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('handles tap correctly', (tester) async {
      var wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraCard(
              child: const Text('Tappable Card'),
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(AuraPressable), findsOneWidget);

      await tester.tap(find.byType(AuraCard));
      expect(wasTapped, isTrue);
    });

    testWidgets('does not show InkWell when onTap is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraCard(
              child: Text('Non-tappable Card'),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('applies semantic label correctly', (tester) async {
      const semanticLabel = 'Product card';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraCard(
              child: Text('Content'),
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(AuraCard),
          matching: find.byType(Semantics),
        ),
      );

      expect(semantics.properties.label, semanticLabel);
    });

    testWidgets('renders border style card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraCard(
              child: Text('Border Card'),
              style: AuraCardStyle.border,
            ),
          ),
        ),
      );

      expect(find.text('Border Card'), findsOneWidget);
      expect(find.byType(AuraPressable), findsOneWidget);
    });

    testWidgets('renders glass style card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraCard(
              child: Text('Glass Card'),
              style: AuraCardStyle.glass,
            ),
          ),
        ),
      );

      expect(find.text('Glass Card'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('renders elevated style by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraCard(
              child: Text('Elevated Card'),
            ),
          ),
        ),
      );

      expect(find.text('Elevated Card'), findsOneWidget);
      final pressable = tester.widget<AuraPressable>(
        find.byType(AuraPressable),
      );
      expect(pressable.decoration, isNotNull);
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraCard(
              child: Text('Small Padded Card'),
              padding: AuraEdgeInsetsGeometry.small,
            ),
          ),
        ),
      );

      expect(find.text('Small Padded Card'), findsOneWidget);
      final auraPadding = tester.widget<AuraPadding>(
        find.descendant(
          of: find.byType(AuraCard),
          matching: find.byType(AuraPadding),
        ),
      );
      expect(
        auraPadding.padding,
        AuraEdgeInsetsGeometry.small,
      );
    });

    test('AuraCardStyle enum has all values', () {
      expect(AuraCardStyle.values, hasLength(3));
      expect(AuraCardStyle.values, contains(AuraCardStyle.elevated));
      expect(AuraCardStyle.values, contains(AuraCardStyle.border));
      expect(AuraCardStyle.values, contains(AuraCardStyle.glass));
    });
  });
}
