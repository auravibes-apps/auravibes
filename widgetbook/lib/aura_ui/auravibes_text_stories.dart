import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'AuraText', type: AuraText)
Widget textStylesUseCase(BuildContext context) {
  return AuraText(
    style: context.knobs.object.dropdown(
      label: 'Style',
      options: AuraTextStyle.values,
      labelBuilder: (value) => value.name,
      initialOption: .body,
    ),
    color: context.knobs.objectOrNull.dropdown(
      label: 'Color',
      options: AuraColorVariant.values,
      labelBuilder: (value) => value.name,
      initialOption: null,
    ),
    textAlign: context.knobs.objectOrNull.dropdown(
      label: 'Text Align',
      options: TextAlign.values,
      labelBuilder: (value) => value.name,
      initialOption: null,
    ),
    child: Text(
      context.knobs.string(
        label: 'Text',
        initialValue: 'This is an example of AuraText widget.',
      ),
    ),
  );
}
