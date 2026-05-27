// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.

import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/molecules/aura_container.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraContainer', () {
    testWidgets('renders container with child correctly', (tester) async {
      const testText = 'Container Content';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text(testText),
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('applies custom padding correctly', (tester) async {
      const customPadding = AuraEdgeInsetsGeometry.all(.xl);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
              padding: customPadding,
            ),
          ),
        ),
      );

      final container = tester.widget<AuraPadding>(find.byType(AuraPadding));
      expect(container.padding, customPadding);
    });

    testWidgets('applies custom margin correctly', (tester) async {
      const customMargin = AuraEdgeInsetsGeometry.all(.xl);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
              margin: customMargin,
            ),
          ),
        ),
      );

      final container = tester.widget<AuraPadding>(find.byType(AuraPadding));
      expect(container.padding, customMargin);
    });

    testWidgets('applies custom background color correctly', (tester) async {
      const customColor = AuraColorVariant.error;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
              backgroundColor: customColor,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration =
          (container.decoration ??
                  fail('Expected container.decoration to be non-null'))
              as BoxDecoration;
      // Note: The actual color will be resolved from AuraColorVariant.error
      expect(decoration.color, isNotNull);
    });

    testWidgets('applies custom border radius correctly', (tester) async {
      const customRadius = 12.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
              borderRadius: customRadius,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration =
          (container.decoration ??
                  fail('Expected container.decoration to be non-null'))
              as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(customRadius));
    });

    testWidgets('applies custom border correctly', (tester) async {
      const customBorder = Border.fromBorderSide(
        BorderSide(color: Colors.blue, width: 2),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
              border: customBorder,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration =
          (container.decoration ??
                  fail('Expected container.decoration to be non-null'))
              as BoxDecoration;
      expect(decoration.border, customBorder);
    });

    testWidgets('applies custom width and height correctly', (tester) async {
      const customWidth = 200.0;
      const customHeight = 100.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
              width: customWidth,
              height: customHeight,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, customWidth);
      expect(container.constraints?.maxHeight, customHeight);
    });

    testWidgets('applies custom alignment correctly', (tester) async {
      const customAlignment = Alignment.topRight;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
              alignment: customAlignment,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.alignment, customAlignment);
    });

    testWidgets('applies no shadow correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration =
          (container.decoration ??
                  fail('Expected container.decoration to be non-null'))
              as BoxDecoration;
      expect(decoration.boxShadow, isEmpty);
    });

    testWidgets('applies small shadow correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
              shadow: AuraContainerShadow.sm,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration =
          (container.decoration ??
                  fail('Expected container.decoration to be non-null'))
              as BoxDecoration;
      expect(decoration.boxShadow, [DesignShadows.sm]);
    });

    testWidgets('applies medium shadow correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
              shadow: AuraContainerShadow.md,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration =
          (container.decoration ??
                  fail('Expected container.decoration to be non-null'))
              as BoxDecoration;
      expect(decoration.boxShadow, [DesignShadows.md]);
    });

    testWidgets('applies large shadow correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
              shadow: AuraContainerShadow.lg,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration =
          (container.decoration ??
                  fail('Expected container.decoration to be non-null'))
              as BoxDecoration;
      expect(decoration.boxShadow, [DesignShadows.lg]);
    });

    testWidgets('applies extra large shadow correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
              shadow: AuraContainerShadow.xl,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration =
          (container.decoration ??
                  fail('Expected container.decoration to be non-null'))
              as BoxDecoration;
      expect(decoration.boxShadow, [DesignShadows.xl]);
    });

    testWidgets('applies inner shadow correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
              shadow: AuraContainerShadow.inner,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration =
          (container.decoration ??
                  fail('Expected container.decoration to be non-null'))
              as BoxDecoration;
      expect(decoration.boxShadow, [DesignShadows.inner]);
    });

    testWidgets('applies glass shadow correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
              shadow: AuraContainerShadow.glass,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration =
          (container.decoration ??
                  fail('Expected container.decoration to be non-null'))
              as BoxDecoration;
      expect(decoration.boxShadow, [DesignShadows.glass]);
    });

    testWidgets('applies semantic label correctly', (tester) async {
      const semanticLabel = 'Content container';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              child: Text('Content'),
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(AuraContainer),
          matching: find.byType(Semantics),
        ),
      );

      expect(semantics.properties.label, semanticLabel);
    });

    group('AuraContainerShadow enum', () {
      test('has all expected values', () {
        expect(AuraContainerShadow.values, hasLength(7));
        expect(AuraContainerShadow.values, contains(AuraContainerShadow.none));
        expect(AuraContainerShadow.values, contains(AuraContainerShadow.sm));
        expect(AuraContainerShadow.values, contains(AuraContainerShadow.md));
        expect(AuraContainerShadow.values, contains(AuraContainerShadow.lg));
        expect(AuraContainerShadow.values, contains(AuraContainerShadow.xl));
        expect(AuraContainerShadow.values, contains(AuraContainerShadow.inner));
        expect(AuraContainerShadow.values, contains(AuraContainerShadow.glass));
      });
    });
  });
}
