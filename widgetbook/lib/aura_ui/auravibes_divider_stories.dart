import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _endIndentLabel = 'End Indent';

@widgetbook.UseCase(name: 'Horizontal Divider', type: AuraDivider)
Widget basicHorizontalDividerUseCase(BuildContext context) {
  return AuraDivider(
    endIndent: context.knobs.double.slider(
      label: _endIndentLabel,
      initialValue: 0,
      max: 100,
    ),
    height: context.knobs.double.slider(
      label: 'Height',
      initialValue: 0,
      min: 0,
      max: 1,
    ),
    indent: context.knobs.double.slider(
      label: 'Indent',
      initialValue: 0,
      max: 100,
    ),
    thickness: context.knobs.double.slider(
      label: 'Thickness',
      initialValue: 1,
      max: 1,
      min: 0,
    ),
  );
}

@widgetbook.UseCase(name: 'Vertical Divider', type: AuraDivider)
Widget verticalDividerUseCase(BuildContext context) {
  return AuraDivider.vertical(
    width: context.knobs.double.slider(
      label: 'Width',
      initialValue: 0,
      min: 0,
      max: 1,
    ),
    endIndent: context.knobs.double.slider(
      label: _endIndentLabel,
      initialValue: 0,
      max: 100,
    ),

    indent: context.knobs.double.slider(
      label: 'Indent',
      initialValue: 0,
      max: 100,
    ),
    thickness: context.knobs.double.slider(
      label: 'Thickness',
      initialValue: 1,
      max: 1,
      min: 0,
    ),
  );
}

@widgetbook.UseCase(name: 'Divider with Label', type: AuraDivider)
Widget dividerWithLabelUseCase(BuildContext context) {
  return AuraDivider.withLabel(
    label: const Text('Section 1'),

    height: context.knobs.double.slider(
      label: 'Height',
      initialValue: 0,
      min: 0,
      max: 1,
    ),
    endIndent: context.knobs.double.slider(
      label: _endIndentLabel,
      initialValue: 0,
      max: 100,
    ),

    indent: context.knobs.double.slider(
      label: 'Indent',
      initialValue: 0,
      max: 100,
    ),
    thickness: context.knobs.double.slider(
      label: 'Thickness',
      initialValue: 1,
      max: 1,
      min: 0,
    ),
  );
}
