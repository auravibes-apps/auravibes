import 'dart:ui' as ui;

import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraChoicePicker', () {
    testWidgets('renders labeled options and changes one selection', (
      tester,
    ) async {
      List<String>? changedValues;

      await tester.pumpWidget(
        _buildApp(
          AuraChoicePicker<String>(
            options: const [
              AuraChoiceOption(value: 'first', label: Text('First')),
              AuraChoiceOption(value: 'second', label: Text('Second')),
            ],
            value: const ['first'],
            onChanged: (value) => changedValues = value,
          ),
        ),
      );

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.byType(AuraRadio<String>), findsNWidgets(2));

      await tester.tap(find.text('Second'));

      expect(changedValues, ['second']);
    });

    testWidgets('uses only the first value in mutually exclusive mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildApp(
          const AuraChoicePicker<String>(
            options: [
              AuraChoiceOption(
                value: 'first',
                label: Text('First'),
                semanticLabel: 'First choice',
              ),
              AuraChoiceOption(
                value: 'second',
                label: Text('Second'),
                semanticLabel: 'Second choice',
              ),
            ],
            value: ['first', 'second'],
            onChanged: _noopChanged,
          ),
        ),
      );

      final radios = find.byType(AuraRadio<String>);
      expect(
        tester.widget<AuraRadio<String>>(radios.at(0)).groupValue,
        'first',
      );
      expect(
        tester.widget<AuraRadio<String>>(radios.at(1)).groupValue,
        'first',
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('First choice'))
            .flagsCollection
            .isChecked,
        ui.CheckedState.isTrue,
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Second choice'))
            .flagsCollection
            .isChecked,
        ui.CheckedState.isFalse,
      );

      semantics.dispose();
    });

    testWidgets('supports controlled multiple selections', (tester) async {
      var selectedValues = <String>['first'];

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _buildApp(
            AuraChoicePicker<String>(
              options: const [
                AuraChoiceOption(value: 'first', label: Text('First')),
                AuraChoiceOption(value: 'second', label: Text('Second')),
              ],
              value: selectedValues,
              onChanged: (value) => setState(() => selectedValues = value),
              variant: AuraChoicePickerVariant.multipleSelection,
            ),
          ),
        ),
      );

      expect(find.byType(AuraCheckbox), findsNWidgets(2));

      await tester.tap(find.text('Second'));
      await tester.pump();
      expect(selectedValues, ['first', 'second']);

      await tester.tap(find.text('First'));
      await tester.pump();
      expect(selectedValues, ['second']);
    });

    testWidgets('enforces maxAllowedSelections when adding values', (
      tester,
    ) async {
      List<String>? changedValues;

      await tester.pumpWidget(
        _buildApp(
          AuraChoicePicker<String>(
            options: const [
              AuraChoiceOption(value: 'first', label: Text('First')),
              AuraChoiceOption(value: 'second', label: Text('Second')),
            ],
            value: const ['first'],
            onChanged: (value) => changedValues = value,
            variant: AuraChoicePickerVariant.multipleSelection,
            maxAllowedSelections: 1,
          ),
        ),
      );

      await tester.tap(find.text('Second'));

      expect(changedValues, isNull);

      await tester.tap(find.text('First'));

      expect(changedValues, isEmpty);
    });

    testWidgets('ignores maxAllowedSelections for single selection', (
      tester,
    ) async {
      List<String>? changedValues;

      await tester.pumpWidget(
        _buildApp(
          AuraChoicePicker<String>(
            options: const [
              AuraChoiceOption(value: 'first', label: Text('First')),
              AuraChoiceOption(value: 'second', label: Text('Second')),
            ],
            value: const ['first'],
            onChanged: (value) => changedValues = value,
            maxAllowedSelections: 0,
          ),
        ),
      );

      await tester.tap(find.text('Second'));

      expect(changedValues, ['second']);
    });

    testWidgets('does not change a disabled option', (tester) async {
      List<String>? changedValues;

      await tester.pumpWidget(
        _buildApp(
          AuraChoicePicker<String>(
            options: const [
              AuraChoiceOption(
                value: 'unavailable',
                label: Text('Unavailable'),
                disabled: true,
              ),
            ],
            value: const [],
            onChanged: (value) => changedValues = value,
          ),
        ),
      );

      await tester.tap(find.text('Unavailable'));

      final radio = tester.widget<AuraRadio<String>>(
        find.byType(AuraRadio<String>),
      );
      expect(radio.disabled, isTrue);
      final disabledLabel = find.ancestor(
        of: find.text('Unavailable'),
        matching: find.byType(Opacity),
      );
      expect(disabledLabel, findsOneWidget);
      expect(tester.widget<Opacity>(disabledLabel).opacity, 0.6);
      expect(changedValues, isNull);
    });

    testWidgets('renders no controls for empty options', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const AuraChoicePicker<String>(
            options: [],
            value: [],
            onChanged: null,
          ),
        ),
      );

      expect(find.byType(AuraRadio<String>), findsNothing);
      expect(find.byType(AuraCheckbox), findsNothing);
    });

    testWidgets('allows multiline option labels to expand', (tester) async {
      const label = 'First\nSecond\nThird\nFourth';

      await tester.pumpWidget(
        _buildApp(
          const AuraChoicePicker<String>(
            options: [AuraChoiceOption(value: 'first', label: Text(label))],
            value: [],
            onChanged: _noopChanged,
          ),
        ),
      );

      expect(tester.getSize(find.text(label)).height, greaterThan(44));
    });

    testWidgets('exposes group and option accessibility semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildApp(
          const AuraChoicePicker<String>(
            options: [
              AuraChoiceOption(
                value: 'first',
                label: Text('First'),
                semanticLabel: 'First choice',
              ),
            ],
            value: ['first'],
            onChanged: _noopChanged,
            semanticLabel: 'Choices',
          ),
        ),
      );

      expect(find.bySemanticsLabel('Choices'), findsOneWidget);

      final optionFinder = find.bySemanticsLabel('First choice');
      final optionNode = tester.getSemantics(optionFinder);
      expect(optionNode.label, contains('First choice'));
      expect(optionNode.flagsCollection.isChecked, ui.CheckedState.isTrue);
      expect(optionNode.flagsCollection.isEnabled, ui.Tristate.isTrue);
      expect(tester.getSize(optionFinder).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(optionFinder).height, greaterThanOrEqualTo(44));

      semantics.dispose();
    });
  });
}

Widget _buildApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
    theme: ThemeData(extensions: [AuraTheme.light]),
  );
}

void _noopChanged(List<String> values) {
  if (values.isEmpty) return;
}
