// ignore_for_file: avoid-returning-widgets
// Required: Widgetbook stories use helper functions that return widgets.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _endIndentLabel = 'End Indent';

double _endIndentKnob(BuildContext context) {
  return context.knobs.double.slider(
    label: _endIndentLabel,
    initialValue: 0,
    max: 100,
  );
}

double _heightKnob(BuildContext context) {
  return context.knobs.double.slider(label: 'Height', initialValue: 0, max: 20);
}

double _indentKnob(BuildContext context) =>
    context.knobs.double.slider(label: 'Indent', initialValue: 0, max: 100);

double _thicknessKnob(BuildContext context) {
  return context.knobs.double.slider(
    label: 'Thickness',
    initialValue: 1,
    min: 0,
    max: 10,
  );
}

@widgetbook.UseCase(name: 'Horizontal Divider', type: AuraDivider)
Widget horizontalDividerUseCase(BuildContext context) {
  return AuraDivider(
    height: _heightKnob(context),
    thickness: _thicknessKnob(context),
    indent: _indentKnob(context),
    endIndent: _endIndentKnob(context),
  );
}

@widgetbook.UseCase(name: 'Vertical Divider', type: AuraDivider)
Widget verticalDividerUseCase(BuildContext context) {
  return AuraDivider.vertical(
    width: context.knobs.double.slider(
      label: 'Width',
      initialValue: 0,
      min: 0,
      max: 20,
    ),
    thickness: _thicknessKnob(context),
    indent: _indentKnob(context),
    endIndent: _endIndentKnob(context),
  );
}

@widgetbook.UseCase(name: 'Divider with Label', type: AuraDivider)
Widget dividerWithLabelUseCase(BuildContext context) {
  return AuraDivider.withLabel(
    label: const Text('Section 1'),
    height: _heightKnob(context),
    thickness: _thicknessKnob(context),
    indent: _indentKnob(context),
    endIndent: _endIndentKnob(context),
  );
}
