import 'package:auravibes_app/widgets/app_input_base.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('constructor stores required parameters', () {
    final valueProvider = Provider<String>((ref) => '');
    final onChangedProvider = Provider<void Function(String)?>((ref) => null);

    final widget = AppInputBase(
      labelLocaleKey: 'input.label',
      placeholderLocaleKey: 'input.placeholder',
      value: valueProvider,
      onChanged: onChangedProvider,
    );

    expect(widget.labelLocaleKey, 'input.label');
    expect(widget.placeholderLocaleKey, 'input.placeholder');
    expect(widget.hintLocaleKey, isNull);
    expect(widget.obscureText, isFalse);
  });

  test('constructor stores optional hint and obscureText', () {
    final valueProvider = Provider<String>((ref) => '');
    final onChangedProvider = Provider<void Function(String)?>((ref) => null);

    final widget = AppInputBase(
      labelLocaleKey: 'input.label',
      placeholderLocaleKey: 'input.placeholder',
      value: valueProvider,
      onChanged: onChangedProvider,
      hintLocaleKey: 'input.hint',
      obscureText: true,
    );

    expect(widget.hintLocaleKey, 'input.hint');
    expect(widget.obscureText, isTrue);
  });

  test('is a HookConsumerWidget', () {
    final valueProvider = Provider<String>((ref) => '');
    final onChangedProvider = Provider<void Function(String)?>((ref) => null);

    final widget = AppInputBase(
      labelLocaleKey: 'test',
      placeholderLocaleKey: 'test',
      value: valueProvider,
      onChanged: onChangedProvider,
    );

    expect(widget, isA<AppInputBase>());
  });
}
