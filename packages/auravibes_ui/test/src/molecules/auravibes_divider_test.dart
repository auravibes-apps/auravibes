import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:auravibes_ui/src/molecules/auravibes_divider.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraDivider', () {
    testWidgets('renders horizontal divider correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDivider(),
          ),
        ),
      );

      expect(
        find.byType(Container),
        findsNWidgets(2),
      ); // Outer and inner container
    });

    testWidgets('applies custom height correctly', (tester) async {
      const customHeight = 32.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDivider(
              height: customHeight,
            ),
          ),
        ),
      );

      final outerContainer = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(outerContainer.constraints?.maxHeight, customHeight);
    });

    testWidgets('applies custom thickness correctly', (tester) async {
      const customThickness = 4.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDivider(
              thickness: customThickness,
            ),
          ),
        ),
      );

      final innerContainer = tester.widget<Container>(
        find.byType(Container).last,
      );
      expect(innerContainer.constraints?.maxHeight, customThickness);
    });

    testWidgets('applies custom color correctly', (tester) async {
      const customColor = AuraColorVariant.error;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDivider(
              color: customColor,
            ),
          ),
        ),
      );

      final innerContainer = tester.widget<Container>(
        find.byType(Container).last,
      );
      // Note: The actual color will be resolved from AuraColorVariant.error
      expect(innerContainer.color, isNotNull);
    });

    testWidgets('applies indent correctly', (tester) async {
      const indent = 16.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDivider(
              indent: indent,
            ),
          ),
        ),
      );

      final outerContainer = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(outerContainer.margin, const EdgeInsets.only(left: indent));
    });

    testWidgets('applies endIndent correctly', (tester) async {
      const endIndent = 16.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDivider(
              endIndent: endIndent,
            ),
          ),
        ),
      );

      final outerContainer = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(outerContainer.margin, const EdgeInsets.only(right: endIndent));
    });

    group('AuraDivider.vertical', () {
      testWidgets('renders vertical divider correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraDivider.vertical(),
            ),
          ),
        );

        expect(find.byType(Container), findsNWidgets(2));
      });

      testWidgets('applies custom width correctly', (tester) async {
        const customWidth = 32.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraDivider.vertical(
                width: customWidth,
              ),
            ),
          ),
        );

        final outerContainer = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(outerContainer.constraints?.maxWidth, customWidth);
      });

      testWidgets('applies vertical indent correctly', (tester) async {
        const indent = 16.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraDivider.vertical(
                indent: indent,
              ),
            ),
          ),
        );

        final outerContainer = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(outerContainer.margin, const EdgeInsets.only(top: indent));
      });
    });

    group('AuraDivider.withLabel', () {
      testWidgets('renders labeled divider correctly', (tester) async {
        const labelText = 'OR';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraDivider.withLabel(
                label: Text(labelText),
              ),
            ),
          ),
        );

        expect(find.text(labelText), findsOneWidget);
        expect(find.byType(AuraText), findsOneWidget);
        expect(find.byType(Row), findsOneWidget);
        expect(find.byType(Expanded), findsNWidgets(2)); // Two line segments
      });

      testWidgets('applies custom height to labeled divider', (tester) async {
        const customHeight = 48.0;
        const labelText = 'SECTION';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraDivider.withLabel(
                label: Text(labelText),
                height: customHeight,
              ),
            ),
          ),
        );

        final outerContainer = tester.widget<Container>(
          find.ancestor(
            of: find.byType(Row),
            matching: find.byType(Container),
          ),
        );
        expect(outerContainer.constraints?.maxHeight, customHeight);
      });
    });

    group('AuraDividerOrientation enum', () {
      test('has all expected values', () {
        expect(AuraDividerOrientation.values, hasLength(2));
        expect(
          AuraDividerOrientation.values,
          contains(AuraDividerOrientation.horizontal),
        );
        expect(
          AuraDividerOrientation.values,
          contains(AuraDividerOrientation.vertical),
        );
      });
    });
  });
}
