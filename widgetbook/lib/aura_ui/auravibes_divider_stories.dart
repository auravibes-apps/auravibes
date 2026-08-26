// Required: Widgetbook stories use fixed example sizes.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _endIndentLabel = 'End Indent';
const _zeroIndent = 0.0;
const _maxIndent = 100.0;
const _maxHeight = 20.0;
const _defaultThickness = 1.0;
const _maxThickness = 10.0;

double _endIndentKnob(BuildContext context) {
  return context.knobs.double.slider(
    label: _endIndentLabel,
    initialValue: _zeroIndent,
    max: _maxIndent,
  );
}

double _heightKnob(BuildContext context) {
  return context.knobs.double.slider(
    label: 'Height',
    initialValue: _zeroIndent,
    max: _maxHeight,
  );
}

double _indentKnob(BuildContext context) => context.knobs.double.slider(
  label: 'Indent',
  initialValue: _zeroIndent,
  max: _maxIndent,
);

double _thicknessKnob(BuildContext context) {
  return context.knobs.double.slider(
    label: 'Thickness',
    initialValue: _defaultThickness,
    min: _zeroIndent,
    max: _maxThickness,
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
      initialValue: _zeroIndent,
      min: _zeroIndent,
      max: _maxHeight,
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
