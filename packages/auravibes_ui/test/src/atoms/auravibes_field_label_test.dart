import 'package:auravibes_ui/src/atoms/auravibes_field_label.dart';
import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraFieldLabel', () {
    testWidgets('renders child text correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFieldLabel(
              child: Text('Field Name'),
            ),
          ),
        ),
      );

      expect(find.text('Field Name'), findsOneWidget);
      expect(find.byType(AuraText), findsOneWidget);
    });

    testWidgets('shows required asterisk when isRequired is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFieldLabel(
              isRequired: true,
              child: Text('Required Field'),
            ),
          ),
        ),
      );

      expect(find.text('Required Field'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('does not show asterisk when isRequired is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFieldLabel(
              child: Text('Optional Field'),
            ),
          ),
        ),
      );

      expect(find.text('Optional Field'), findsOneWidget);
      expect(find.text('*'), findsNothing);
    });

    testWidgets('applies semantic label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFieldLabel(
              semanticLabel: 'Username field',
              child: Text('Username'),
            ),
          ),
        ),
      );

      final semanticsFinder = find.descendant(
        of: find.byType(AuraFieldLabel),
        matching: find.byType(Semantics),
      );
      expect(semanticsFinder, findsOneWidget);
      final semantics = tester.widget<Semantics>(semanticsFinder);
      expect(semantics.properties.label, 'Username field');
    });

    testWidgets('applies custom style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFieldLabel(
              style: AuraTextStyle.heading1,
              child: Text('Styled Label'),
            ),
          ),
        ),
      );

      expect(find.text('Styled Label'), findsOneWidget);
    });

    testWidgets('renders in a Row with mainAxisSize min', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraFieldLabel(
              child: Text('Label'),
            ),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisSize, MainAxisSize.min);
    });
  });
}
