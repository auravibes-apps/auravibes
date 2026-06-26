// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'AuraText', type: AuraText)
Widget textStylesUseCase(BuildContext context) {
  return AuraText(
    child: Text(
      context.knobs.string(
        label: 'Text',
        initialValue: 'This is an example of AuraText widget.',
      ),
    ),
    style: context.knobs.object.dropdown(
      label: 'Style',
      options: AuraTextStyle.values,
      initialOption: .body,
      labelBuilder: (value) => value.name,
    ),
    textAlign: context.knobs.objectOrNull.dropdown(
      label: 'Text Align',
      options: TextAlign.values,
      initialOption: null,
      labelBuilder: (value) => value.name,
    ),
    tint: context.knobs.objectOrNull.dropdown(
      label: 'Tint',
      options: AuraTint.values,
      initialOption: null,
      labelBuilder: (value) => value.name,
    ),
  );
}
