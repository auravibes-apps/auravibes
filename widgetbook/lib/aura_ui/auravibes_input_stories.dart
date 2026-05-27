// ignore_for_file: no-magic-number
// Required: Widgetbook stories use fixed example sizes.
// ignore_for_file: avoid-returning-widgets
// Required: Widgetbook stories use helper functions that return widgets.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_workspace/knobs/icons.dart';

@widgetbook.UseCase(name: 'Input', type: AuraInput)
Widget basicInputUseCase(BuildContext context) {
  final placeholderText = context.knobs.stringOrNull(
    label: 'Placeholder',
    initialValue: 'Enter text here',
  );
  final hintText = context.knobs.stringOrNull(
    label: 'Hint',
    initialValue: 'This is a hint text',
  );

  final prefixIcon = context.knobs.iconDataOrNull(
    label: 'Prefix Icon',
    initialValue: null,
  );

  final suffixIcon = context.knobs.iconDataOrNull(
    label: 'Suffix Icon',
    initialValue: null,
  );

  return AuraInput(
    initialValue: context.knobs.stringOrNull(
      label: 'Initial Value',
      initialValue: null,
    ),
    placeholder: placeholderText != null ? Text(placeholderText) : null,
    hint: hintText != null ? Text(hintText) : null,
    prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
    suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
    size: context.knobs.object.dropdown(
      label: 'size',
      options: AuraInputSize.values,
      labelBuilder: (value) => value.name,
    ),
    state: context.knobs.object.dropdown(
      label: 'state',
      options: AuraInputState.values,
      labelBuilder: (value) => value.name,
    ),
    keyboardType: context.knobs.objectOrNull.dropdown(
      label: 'Keyboard Type',
      options: TextInputType.values,
      labelBuilder: (value) => value.toString(),
    ),
    enabled: context.knobs.boolean(label: 'Enabled', initialValue: true),
    maxLines: context.knobs.int.slider(
      label: 'Max Lines',
      initialValue: 1,
      min: 1,
      max: 10,
    ),
    maxLength: context.knobs.int.slider(
      label: 'Max Length',
      initialValue: 1,
      min: 1,
      max: 100,
    ),
  );
}
