// ignore_for_file: no-magic-number
// Required: Widgetbook stories use fixed example sizes.
// ignore_for_file: avoid-returning-widgets
// Required: Widgetbook stories use helper functions that return widgets.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'AuraSpinner', type: AuraSpinner)
Widget basicSpinnerUseCase(BuildContext context) {
  return AuraSpinner(
    size: context.knobs.object.dropdown(
      label: 'size',
      options: AuraSpinnerSize.values,
      labelBuilder: (value) => value.name,
    ),
    color: context.knobs.color(label: 'color', initialValue: Colors.blue),
    strokeWidth: context.knobs.double.slider(
      label: 'strokeWidth',
      initialValue: 4,
      min: 1,
      max: 10,
    ),
  );
}
