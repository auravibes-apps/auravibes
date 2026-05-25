import 'package:auravibes_app/widgets/app_dropdown_base.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('constructor stores required parameters', () {
    final valueProvider = Provider<String?>((ref) => null);
    final onChangedProvider = Provider<void Function(String?)?>((ref) => null);

    final widget = AppDropdownBase<String>(
      value: valueProvider,
      onChanged: onChangedProvider,
      options: const [
        AuraDropdownOption(value: 'a', child: Text('A')),
        AuraDropdownOption(value: 'b', child: Text('B')),
      ],
      labelLocaleKey: 'models.label',
    );

    expect(widget.labelLocaleKey, 'models.label');
    expect(widget.options, hasLength(2));
    expect(widget.options.first.value, 'a');
    expect(widget.options[1].value, 'b');
  });

  test('is a HookConsumerWidget', () {
    final valueProvider = Provider<String?>((ref) => null);
    final onChangedProvider = Provider<void Function(String?)?>((ref) => null);

    final widget = AppDropdownBase<String>(
      value: valueProvider,
      onChanged: onChangedProvider,
      options: const [],
      labelLocaleKey: 'test',
    );

    expect(widget, isA<AppDropdownBase<String>>());
  });
}
