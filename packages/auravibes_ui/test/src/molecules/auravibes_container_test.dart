import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/molecules/aura_container.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders container options and shadows', (tester) async {
    const customPadding = AuraEdgeInsetsGeometry.all(.xl);
    const customMargin = AuraEdgeInsetsGeometry.all(.xl);
    const customBorder = Border.fromBorderSide(
      .new(color: Colors.blue, width: 2),
    );
    const customWidth = 200.0;
    const customHeight = 100.0;
    const customRadius = 12.0;
    const customAlignment = Alignment.topRight;
    const semanticLabel = 'Content container';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              mainAxisSize: .min,
              children: [
                AuraContainer(
                  child: Text('Container Content'),
                  key: ValueKey('default'),
                ),
                AuraContainer(
                  child: Text('Content'),
                  key: ValueKey('padding'),
                  padding: customPadding,
                ),
                AuraContainer(
                  child: Text('Content'),
                  key: ValueKey('margin'),
                  margin: customMargin,
                ),
                AuraContainer(
                  child: Text('Content'),
                  key: ValueKey('variant'),
                  variant: .surfaceVariant,
                ),
                AuraContainer(
                  child: Text('Content'),
                  key: ValueKey('radius'),
                  borderRadius: customRadius,
                ),
                AuraContainer(
                  child: Text('Content'),
                  key: ValueKey('border'),
                  border: customBorder,
                ),
                AuraContainer(
                  child: Text('Content'),
                  key: ValueKey('dimensions'),
                  width: customWidth,
                  height: customHeight,
                ),
                AuraContainer(
                  child: Text('Content'),
                  key: ValueKey('alignment'),
                  alignment: customAlignment,
                ),
                AuraContainer(
                  child: Text('Content'),
                  key: ValueKey('small-shadow'),
                  shadow: .sm,
                ),
                AuraContainer(
                  child: Text('Content'),
                  key: ValueKey('medium-shadow'),
                  shadow: .md,
                ),
                AuraContainer(
                  child: Text('Content'),
                  key: ValueKey('large-shadow'),
                  shadow: .lg,
                ),
                AuraContainer(
                  child: Text('Content'),
                  key: ValueKey('extra-large-shadow'),
                  shadow: .xl,
                ),
                AuraContainer(
                  child: Text('Content'),
                  key: ValueKey('inner-shadow'),
                  shadow: .inner,
                ),
                AuraContainer(
                  child: Text('Content'),
                  key: ValueKey('glass-shadow'),
                  shadow: .glass,
                ),
                AuraContainer(
                  child: Text('Content'),
                  key: ValueKey('semantic'),
                  semanticLabel: semanticLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Finder containerFinder(String key) => find.descendant(
      of: find.byKey(ValueKey<String>(key)),
      matching: find.byType(Container),
    );
    Container container(String key) =>
        tester.widget<Container>(containerFinder(key));
    BoxDecoration decoration(String key) =>
        (container(key).decoration ?? fail('Expected container decoration'))
            as BoxDecoration;

    expect(find.text('Container Content'), findsOneWidget);
    expect(containerFinder('default'), findsOneWidget);
    expect(decoration('default').boxShadow, isEmpty);

    final padding = tester.widget<AuraPadding>(
      find.descendant(
        of: find.byKey(const ValueKey('padding')),
        matching: find.byType(AuraPadding),
      ),
    );
    expect(padding.padding, customPadding);

    final margin = tester.widget<AuraPadding>(
      find.descendant(
        of: find.byKey(const ValueKey('margin')),
        matching: find.byType(AuraPadding),
      ),
    );
    expect(margin.padding, customMargin);

    expect(decoration('variant').color, isNotNull);
    expect(
      decoration('radius').borderRadius,
      BorderRadius.circular(customRadius),
    );
    expect(decoration('border').border, customBorder);
    expect(container('dimensions').constraints?.maxWidth, customWidth);
    expect(container('dimensions').constraints?.maxHeight, customHeight);
    expect(container('alignment').alignment, customAlignment);

    expect(decoration('small-shadow').boxShadow, [DesignShadows.sm]);
    expect(decoration('medium-shadow').boxShadow, [DesignShadows.md]);
    expect(decoration('large-shadow').boxShadow, [DesignShadows.lg]);
    expect(decoration('extra-large-shadow').boxShadow, [DesignShadows.xl]);
    expect(decoration('inner-shadow').boxShadow, [DesignShadows.inner]);
    expect(decoration('glass-shadow').boxShadow, [DesignShadows.glass]);

    final semantics = tester.widget<Semantics>(
      find.descendant(
        of: find.byKey(const ValueKey('semantic')),
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
}
