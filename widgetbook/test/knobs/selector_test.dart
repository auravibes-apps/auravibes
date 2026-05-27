// ignore_for_file: no-magic-number
// Required: Tests use small numeric selector fixtures.
// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures top-level.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/knobs/selector.dart';

const List<KnobSelector<int>> _selectors = [
  KnobSelector(label: 'One', value: 1),
  KnobSelector(label: 'Two', value: 2),
];

void main() {
  group('SelectorField', () {
    test('uses first selector as default value', () {
      final field = SelectorField<int>(
        name: 'number',
        selectors: _selectors,
      );

      expect(field.defaultValue, 1);
    });

    test('uses initial value as default value', () {
      final field = SelectorField<int>(
        name: 'number',
        initialValue: 2,
        selectors: _selectors,
      );

      expect(field.defaultValue, 2);
    });

    test('encodes and decodes selector labels', () {
      final field = SelectorField<int>(
        name: 'number',
        selectors: _selectors,
      );

      expect(field.codec.toParam(2), 'Two');
      expect(field.codec.toValue('Two'), 2);
      expect(field.codec.toValue('Missing'), 1);
      expect(field.codec.toValue(null), 1);
    });

    test('throws when selectors are empty', () {
      expect(
        () => SelectorField<int>(name: 'empty', selectors: const []),
        throwsStateError,
      );
    });

    test('serializes selector values to JSON', () {
      final field = SelectorField<int>(
        name: 'number',
        selectors: _selectors,
      );

      expect(field.toJson(), {'One': 1, 'Two': 2});
    });

    testWidgets('builds dropdown menu entries', (tester) async {
      final field = SelectorField<int>(
        name: 'number',
        selectors: _selectors,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => field.toWidget(context, 'group', 1),
            ),
          ),
        ),
      );

      expect(find.byType(DropdownMenu<int>), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
    });
  });

  group('SelectorKnobBuilder', () {
    test('returns selected knob value', () {
      final builder = KnobsBuilder(<T>(knob) => 2 as T?);

      final value = builder.selector(
        label: 'number',
        initialValue: 1,
        selectors: _selectors,
      );

      expect(value, 2);
    });

    test('throws when non-null selector returns null', () {
      final builder = KnobsBuilder(<T>(knob) => null);

      expect(
        () => builder.selector(
          label: 'number',
          initialValue: 1,
          selectors: _selectors,
        ),
        throwsStateError,
      );
    });

    test('returns nullable selector value', () {
      final builder = KnobsBuilder(<T>(knob) => null);

      final value = builder.selectorOrNull(
        label: 'number',
        selectors: _selectors,
      );

      expect(value, isNull);
    });
  });
}
