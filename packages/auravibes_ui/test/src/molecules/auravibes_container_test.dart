import 'package:auravibes_ui/src/atoms/auravibes_padding.dart';
import 'package:auravibes_ui/src/molecules/auravibes_container.dart';
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
              padding: customPadding,
              child: Text('Content'),
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
              margin: customMargin,
              child: Text('Content'),
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
              backgroundColor: customColor,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      // Note: The actual color will be resolved from AuraColorVariant.error
      expect(decoration.color, isNotNull);
    });

    testWidgets('applies custom border radius correctly', (tester) async {
      const customRadius = 12.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              borderRadius: customRadius,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
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
              border: customBorder,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, customBorder);
    });

    testWidgets('applies custom width and height correctly', (tester) async {
      const customWidth = 200.0;
      const customHeight = 100.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              width: customWidth,
              height: customHeight,
              child: Text('Content'),
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
              alignment: customAlignment,
              child: Text('Content'),
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
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.boxShadow, isEmpty);
    });

    testWidgets('applies small shadow correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              shadow: AuraContainerShadow.sm,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.boxShadow, [DesignShadows.sm]);
    });

    testWidgets('applies medium shadow correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              shadow: AuraContainerShadow.md,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.boxShadow, [DesignShadows.md]);
    });

    testWidgets('applies large shadow correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              shadow: AuraContainerShadow.lg,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.boxShadow, [DesignShadows.lg]);
    });

    testWidgets('applies extra large shadow correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              shadow: AuraContainerShadow.xl,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.boxShadow, [DesignShadows.xl]);
    });

    testWidgets('applies inner shadow correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              shadow: AuraContainerShadow.inner,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.boxShadow, [DesignShadows.inner]);
    });

    testWidgets('applies glass shadow correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              shadow: AuraContainerShadow.glass,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.boxShadow, [DesignShadows.glass]);
    });

    testWidgets('applies semantic label correctly', (tester) async {
      const semanticLabel = 'Content container';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraContainer(
              semanticLabel: semanticLabel,
              child: Text('Content'),
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

    group('AuraContainerPadding', () {
      test('has all expected padding values', () {
        expect(AuraContainerPadding.xs, const EdgeInsets.all(DesignSpacing.xs));
        expect(AuraContainerPadding.sm, const EdgeInsets.all(DesignSpacing.sm));
        expect(AuraContainerPadding.md, const EdgeInsets.all(DesignSpacing.md));
        expect(AuraContainerPadding.lg, const EdgeInsets.all(DesignSpacing.lg));
        expect(AuraContainerPadding.xl, const EdgeInsets.all(DesignSpacing.xl));
        expect(
          AuraContainerPadding.xl2,
          const EdgeInsets.all(DesignSpacing.xl2),
        );
        expect(
          AuraContainerPadding.xl3,
          const EdgeInsets.all(DesignSpacing.xl3),
        );
      });

      test('has all expected horizontal padding values', () {
        expect(
          AuraContainerPadding.horizontalXs,
          const EdgeInsets.symmetric(horizontal: DesignSpacing.xs),
        );
        expect(
          AuraContainerPadding.horizontalSm,
          const EdgeInsets.symmetric(horizontal: DesignSpacing.sm),
        );
        expect(
          AuraContainerPadding.horizontalMd,
          const EdgeInsets.symmetric(horizontal: DesignSpacing.md),
        );
        expect(
          AuraContainerPadding.horizontalLg,
          const EdgeInsets.symmetric(horizontal: DesignSpacing.lg),
        );
        expect(
          AuraContainerPadding.horizontalXl,
          const EdgeInsets.symmetric(horizontal: DesignSpacing.xl),
        );
      });

      test('has all expected vertical padding values', () {
        expect(
          AuraContainerPadding.verticalXs,
          const EdgeInsets.symmetric(vertical: DesignSpacing.xs),
        );
        expect(
          AuraContainerPadding.verticalSm,
          const EdgeInsets.symmetric(vertical: DesignSpacing.sm),
        );
        expect(
          AuraContainerPadding.verticalMd,
          const EdgeInsets.symmetric(vertical: DesignSpacing.md),
        );
        expect(
          AuraContainerPadding.verticalLg,
          const EdgeInsets.symmetric(vertical: DesignSpacing.lg),
        );
        expect(
          AuraContainerPadding.verticalXl,
          const EdgeInsets.symmetric(vertical: DesignSpacing.xl),
        );
      });
    });

    group('AuraContainerMargin', () {
      test('has all expected margin values', () {
        expect(AuraContainerMargin.xs, const EdgeInsets.all(DesignSpacing.xs));
        expect(AuraContainerMargin.sm, const EdgeInsets.all(DesignSpacing.sm));
        expect(AuraContainerMargin.md, const EdgeInsets.all(DesignSpacing.md));
        expect(AuraContainerMargin.lg, const EdgeInsets.all(DesignSpacing.lg));
        expect(AuraContainerMargin.xl, const EdgeInsets.all(DesignSpacing.xl));
        expect(
          AuraContainerMargin.xl2,
          const EdgeInsets.all(DesignSpacing.xl2),
        );
        expect(
          AuraContainerMargin.xl3,
          const EdgeInsets.all(DesignSpacing.xl3),
        );
      });

      test('has all expected horizontal margin values', () {
        expect(
          AuraContainerMargin.horizontalXs,
          const EdgeInsets.symmetric(horizontal: DesignSpacing.xs),
        );
        expect(
          AuraContainerMargin.horizontalSm,
          const EdgeInsets.symmetric(horizontal: DesignSpacing.sm),
        );
        expect(
          AuraContainerMargin.horizontalMd,
          const EdgeInsets.symmetric(horizontal: DesignSpacing.md),
        );
        expect(
          AuraContainerMargin.horizontalLg,
          const EdgeInsets.symmetric(horizontal: DesignSpacing.lg),
        );
        expect(
          AuraContainerMargin.horizontalXl,
          const EdgeInsets.symmetric(horizontal: DesignSpacing.xl),
        );
      });

      test('has all expected vertical margin values', () {
        expect(
          AuraContainerMargin.verticalXs,
          const EdgeInsets.symmetric(vertical: DesignSpacing.xs),
        );
        expect(
          AuraContainerMargin.verticalSm,
          const EdgeInsets.symmetric(vertical: DesignSpacing.sm),
        );
        expect(
          AuraContainerMargin.verticalMd,
          const EdgeInsets.symmetric(vertical: DesignSpacing.md),
        );
        expect(
          AuraContainerMargin.verticalLg,
          const EdgeInsets.symmetric(vertical: DesignSpacing.lg),
        );
        expect(
          AuraContainerMargin.verticalXl,
          const EdgeInsets.symmetric(vertical: DesignSpacing.xl),
        );
      });
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
