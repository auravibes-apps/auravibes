import 'package:auravibes_ui/src/atoms/auravibes_padding.dart';
import 'package:auravibes_ui/src/atoms/auravibes_pressable.dart';
import 'package:auravibes_ui/src/molecules/auravibes_card.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
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
              onTap: () => wasTapped = true,
              child: const Text('Tappable Card'),
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
              semanticLabel: semanticLabel,
              child: Text('Content'),
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
              style: AuraCardStyle.border,
              child: Text('Border Card'),
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
              style: AuraCardStyle.glass,
              child: Text('Glass Card'),
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
              padding: AuraEdgeInsetsGeometry.all(AuraSpacing.sm),
              child: Text('Small Padded Card'),
            ),
          ),
        ),
      );

      expect(find.text('Small Padded Card'), findsOneWidget);
    });

    test('AuraCardStyle enum has all values', () {
      expect(AuraCardStyle.values, hasLength(3));
      expect(AuraCardStyle.values, contains(AuraCardStyle.elevated));
      expect(AuraCardStyle.values, contains(AuraCardStyle.border));
      expect(AuraCardStyle.values, contains(AuraCardStyle.glass));
    });
  });
}
