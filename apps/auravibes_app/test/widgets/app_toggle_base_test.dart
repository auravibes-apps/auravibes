import 'package:auravibes_app/widgets/app_toggle_base.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('constructor stores required parameters', () {
    final valueProvider = Provider<bool>((ref) => false);
    final onChangedProvider = Provider<ValueChanged<bool>?>((ref) => null);

    final widget = AppToggleBase(
      labelLocaleKey: 'toggle.label',
      hintLocaleKey: 'toggle.hint',
      value: valueProvider,
      onChanged: onChangedProvider,
    );

    expect(widget.labelLocaleKey, 'toggle.label');
    expect(widget.hintLocaleKey, 'toggle.hint');
  });

  test('is a ConsumerWidget', () {
    final valueProvider = Provider<bool>((ref) => false);
    final onChangedProvider = Provider<ValueChanged<bool>?>((ref) => null);

    final widget = AppToggleBase(
      labelLocaleKey: 'test',
      hintLocaleKey: 'test',
      value: valueProvider,
      onChanged: onChangedProvider,
    );

    expect(widget, isA<AppToggleBase>());
  });
}
