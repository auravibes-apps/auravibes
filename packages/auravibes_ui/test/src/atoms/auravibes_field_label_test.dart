import 'package:auravibes_ui/src/atoms/aura_field_label.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraFieldLabel', () {
    testWidgets('renders child, required, semantic and style variants', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              crossAxisAlignment: .start,
              children: [
                KeyedSubtree(
                  key: ValueKey('default'),
                  child: AuraFieldLabel(child: Text('Field Name')),
                ),
                KeyedSubtree(
                  key: ValueKey('required'),
                  child: AuraFieldLabel(
                    child: Text('Required Field'),
                    isRequired: true,
                  ),
                ),
                KeyedSubtree(
                  key: ValueKey('optional'),
                  child: AuraFieldLabel(child: Text('Optional Field')),
                ),
                KeyedSubtree(
                  key: ValueKey('semantic'),
                  child: AuraFieldLabel(
                    child: Text('Username'),
                    semanticLabel: 'Username field',
                  ),
                ),
                KeyedSubtree(
                  key: ValueKey('styled'),
                  child: AuraFieldLabel(
                    child: Text('Styled Label'),
                    style: .heading1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final defaultLabel = find.byKey(const ValueKey('default'));
      expect(
        find.descendant(of: defaultLabel, matching: find.text('Field Name')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: defaultLabel, matching: find.byType(AuraText)),
        findsOneWidget,
      );

      final requiredLabel = find.byKey(const ValueKey('required'));
      expect(
        find.descendant(
          of: requiredLabel,
          matching: find.text('Required Field'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: requiredLabel, matching: find.text('*')),
        findsOneWidget,
      );

      final optionalLabel = find.byKey(const ValueKey('optional'));
      expect(
        find.descendant(
          of: optionalLabel,
          matching: find.text('Optional Field'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: optionalLabel, matching: find.text('*')),
        findsNothing,
      );

      final semanticLabel = find.byKey(const ValueKey('semantic'));
      final semanticsFinder = find.descendant(
        of: semanticLabel,
        matching: find.byType(Semantics),
      );
      expect(semanticsFinder, findsOneWidget);
      final semantics = tester.widget<Semantics>(semanticsFinder);
      expect(semantics.properties.label, 'Username field');

      final styledLabel = find.byKey(const ValueKey('styled'));
      expect(
        find.descendant(of: styledLabel, matching: find.text('Styled Label')),
        findsOneWidget,
      );
      final auraText = tester.widget<AuraText>(
        find.descendant(of: styledLabel, matching: find.byType(AuraText)),
      );
      expect(auraText.style, AuraTextStyle.heading1);

      final row = tester.widget<Row>(
        find.descendant(of: defaultLabel, matching: find.byType(Row)),
      );
      expect(row.mainAxisSize, MainAxisSize.min);
    });
  });
}
