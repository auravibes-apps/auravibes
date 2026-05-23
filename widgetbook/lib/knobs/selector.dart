import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

class KnobSelector<T> {
  const KnobSelector({required this.label, required this.value});

  final String label;
  final T value;
}

class SelectorKnob<T> extends Knob<T> {
  SelectorKnob({
    required super.label,
    super.initialValue,
    required this.selectors,
  });

  SelectorKnob.nullable({
    required super.label,
    super.initialValue,
    required this.selectors,
  }) : super(isNullable: true);

  final List<KnobSelector<T>> selectors;

  @override
  List<Field> get fields {
    return [
      SelectorField<T>(
        name: '$label.val',
        selectors: selectors,
        initialValue: initialValue,
      ),
    ];
  }

  @override
  T valueFromQueryGroup(Map<String, String> group) {
    return valueOf<T>('$label.val', group) as T;
  }
}

class SelectorField<T> extends Field<T> {
  /// Creates a new instance of [SelectorField].
  SelectorField({
    required super.name,
    required this.selectors,
    super.initialValue,
  }) : super(
         defaultValue: initialValue ?? selectors.firstOrNull!.value,
         type: FieldType.objectDropdown,
         codec: FieldCodec(
           toParam: (value) =>
               selectors
                   .firstWhereOrNull((selector) => selector.value == value)
                   ?.label ??
               '',
           toValue: (param) =>
               (selectors.firstWhereOrNull(
                         (selector) => selector.label == param,
                       ) ??
                       selectors.firstOrNull)
                   ?.value,
         ),
       );

  /// The list of values to display in the dropdown.
  final List<KnobSelector<T>> selectors;

  /// The default label builder that converts the value to a string.
  static String defaultLabelBuilder(dynamic value) {
    return value.toString();
  }

  @override
  Widget toWidget(BuildContext context, String group, T? value) {
    return DropdownMenu<T>(
      expandedInsets: EdgeInsets.zero,
      trailingIcon: const Icon(Icons.keyboard_arrow_down_rounded),
      selectedTrailingIcon: const Icon(Icons.keyboard_arrow_up_rounded),
      initialSelection: value,
      onSelected: (value) {
        if (value != null) {
          updateField(context, group, value);
        }
      },
      dropdownMenuEntries: selectors
          .map(
            (value) =>
                DropdownMenuEntry(value: value.value, label: value.label),
          )
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return selectors.asMap().map((key, value) {
      return MapEntry(value.label, value.value);
    });
  }
}

extension SelectorKnobBuilder on KnobsBuilder {
  T selector<T>({
    required String label,
    T? initialValue,
    required List<KnobSelector<T>> selectors,
  }) => onKnobAdded(
    SelectorKnob(
      label: label,
      selectors: selectors,
      initialValue: initialValue,
    ),
  )!;

  T? selectorOrNull<T>({
    required String label,
    T? initialValue,
    required List<KnobSelector<T>> selectors,
  }) => onKnobAdded(
    SelectorKnob.nullable(
      label: label,
      selectors: selectors,
      initialValue: initialValue,
    ),
  );
}
