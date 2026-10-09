import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/molecules/aura_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraDivider', () {
    testWidgets('renders orientations and divider options', (tester) async {
      const customThickness = 32.0;
      const labelThickness = 48.0;
      const indent = 16.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              crossAxisAlignment: .stretch,
              children: [
                AuraDivider(key: ValueKey('horizontal')),
                AuraDivider(
                  key: ValueKey('horizontal-thickness'),
                  thickness: customThickness,
                ),
                AuraDivider(key: ValueKey('horizontal-color'), color: .error),
                AuraDivider(key: ValueKey('horizontal-indent'), indent: indent),
                AuraDivider(
                  key: ValueKey('horizontal-end-indent'),
                  endIndent: indent,
                ),
                SizedBox(
                  height: 32,
                  child: AuraDivider.vertical(key: ValueKey('vertical')),
                ),
                SizedBox(
                  height: 32,
                  child: AuraDivider.vertical(
                    key: ValueKey('vertical-thickness'),
                    thickness: customThickness,
                  ),
                ),
                SizedBox(
                  height: 32,
                  child: AuraDivider.vertical(
                    key: ValueKey('vertical-indent'),
                    indent: indent,
                  ),
                ),
                AuraDivider.withLabel(
                  label: Text('OR'),
                  key: ValueKey('label'),
                ),
                AuraDivider.withLabel(
                  label: Text('SECTION'),
                  key: ValueKey('label-thickness'),
                  thickness: labelThickness,
                ),
              ],
            ),
          ),
        ),
      );

      Finder within(String key, Finder matching) => find.descendant(
        of: find.byKey(ValueKey<String>(key)),
        matching: matching,
      );
      List<Container> containers(String key) => tester
          .widgetList<Container>(within(key, find.byType(Container)))
          .toList();

      expect(containers('horizontal'), hasLength(2));
      final horizontalThickness = containers('horizontal-thickness');
      final firstThickness = horizontalThickness.firstOrNull?.constraints;
      expect(firstThickness?.minHeight, customThickness);
      expect(firstThickness?.maxHeight, customThickness);
      expect(horizontalThickness.last.constraints?.maxHeight, customThickness);
      expect(containers('horizontal-color').last.color, isNotNull);
      expect(
        containers('horizontal-indent').first.margin,
        const EdgeInsetsDirectional.only(start: indent),
      );
      expect(
        containers('horizontal-end-indent').first.margin,
        const EdgeInsetsDirectional.only(end: indent),
      );

      expect(containers('vertical'), hasLength(2));
      final verticalThickness = containers('vertical-thickness').first;
      expect(verticalThickness.constraints?.minWidth, customThickness);
      expect(verticalThickness.constraints?.maxWidth, customThickness);
      expect(
        containers('vertical-indent').first.margin,
        const EdgeInsets.only(top: indent),
      );

      expect(within('label', find.text('OR')), findsOneWidget);
      expect(within('label', find.byType(AuraText)), findsOneWidget);
      expect(within('label', find.byType(Row)), findsOneWidget);
      expect(within('label', find.byType(Expanded)), findsNWidgets(2));
      expect(
        containers('label-thickness').first.constraints?.minHeight,
        labelThickness,
      );
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
