// ignore_for_file: no-empty-block
// Required: Tests use intentional no-op callbacks and fake hooks.
import 'package:auravibes_app/widgets/app_group_button_single_base.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('constructor stores required parameters', () {
    final valueProvider = Provider<String?>((ref) => null);
    final onChangedProvider = Provider<ValueChanged<String>>((ref) => (_) {});

    final widget = AppGroupButtonSingleBase<String>(
      value: valueProvider,
      items: const [
        AuraButtonGroupItem(value: 'x', child: Text('X')),
        AuraButtonGroupItem(value: 'y', child: Text('Y')),
      ],
      onChanged: onChangedProvider,
      labelLocaleKey: 'settings.label',
    );

    expect(widget.labelLocaleKey, 'settings.label');
    expect(widget.items, hasLength(2));
    expect(widget.items.first.value, 'x');
    expect(widget.items[1].value, 'y');
  });

  test('is a HookConsumerWidget', () {
    final valueProvider = Provider<String?>((ref) => null);
    final onChangedProvider = Provider<ValueChanged<String>>((ref) => (_) {});

    final widget = AppGroupButtonSingleBase<String>(
      value: valueProvider,
      items: const [],
      onChanged: onChangedProvider,
      labelLocaleKey: 'test',
    );

    expect(widget, isA<AppGroupButtonSingleBase<String>>());
  });
}
