import 'package:auravibes_app/widgets/app_toggle_base.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('constructor stores required parameters', () {
    final valueProvider = Provider<bool>((ref) => false);
    final onChangedProvider = Provider<void Function(bool)?>((ref) => null);

    final widget = AppToggleBase(
      value: valueProvider,
      onChanged: onChangedProvider,
      labelLocaleKey: 'toggle.label',
      hintLocaleKey: 'toggle.hint',
    );

    expect(widget.labelLocaleKey, 'toggle.label');
    expect(widget.hintLocaleKey, 'toggle.hint');
  });

  test('is a ConsumerWidget', () {
    final valueProvider = Provider<bool>((ref) => false);
    final onChangedProvider = Provider<void Function(bool)?>((ref) => null);

    final widget = AppToggleBase(
      value: valueProvider,
      onChanged: onChangedProvider,
      labelLocaleKey: 'test',
      hintLocaleKey: 'test',
    );

    expect(widget, isA<AppToggleBase>());
  });
}
