import 'package:auravibes_ui/src/atoms/auravibes_field_label.dart';
import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpFieldLabel(
  WidgetTester tester, {
  required Widget child,
  bool isRequired = false,
  AuraTextStyle? style,
  String? semanticLabel,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AuraFieldLabel(
          isRequired: isRequired,
          style: style,
          semanticLabel: semanticLabel,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('AuraFieldLabel', () {
    testWidgets('renders child text correctly', (tester) async {
      await _pumpFieldLabel(tester, child: const Text('Field Name'));

      expect(find.text('Field Name'), findsOneWidget);
      expect(find.byType(AuraText), findsOneWidget);
    });

    testWidgets('shows required asterisk when isRequired is true', (
      tester,
    ) async {
      await _pumpFieldLabel(
        tester,
        isRequired: true,
        child: const Text('Required Field'),
      );

      expect(find.text('Required Field'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('does not show asterisk when isRequired is false', (
      tester,
    ) async {
      await _pumpFieldLabel(tester, child: const Text('Optional Field'));

      expect(find.text('Optional Field'), findsOneWidget);
      expect(find.text('*'), findsNothing);
    });

    testWidgets('applies semantic label', (tester) async {
      await _pumpFieldLabel(
        tester,
        semanticLabel: 'Username field',
        child: const Text('Username'),
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
      await _pumpFieldLabel(
        tester,
        style: AuraTextStyle.heading1,
        child: const Text('Styled Label'),
      );

      expect(find.text('Styled Label'), findsOneWidget);
      final auraText = tester.widget<AuraText>(
        find.descendant(
          of: find.byType(AuraFieldLabel),
          matching: find.byType(AuraText),
        ),
      );
      expect(auraText.style, AuraTextStyle.heading1);
    });

    testWidgets('renders in a Row with mainAxisSize min', (tester) async {
      await _pumpFieldLabel(tester, child: const Text('Label'));

      final row = tester.widget<Row>(
        find.descendant(
          of: find.byType(AuraFieldLabel),
          matching: find.byType(Row),
        ),
      );
      expect(row.mainAxisSize, MainAxisSize.min);
    });
  });
}
