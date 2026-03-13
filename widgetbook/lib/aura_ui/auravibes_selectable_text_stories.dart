import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default SelectableText', type: AuraSelectableText)
Widget defaultSelectableTextUseCase(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: AuraSelectableText(
        context.knobs.string(
          label: 'text',
          initialValue: 'This text can be selected and copied.',
        ),
        style: context.knobs.object.dropdown(
          label: 'style',
          options: AuraTextStyle.values,
          initialOption: AuraTextStyle.body,
          labelBuilder: (value) => value.name,
        ),
        colorVariant: context.knobs.objectOrNull.dropdown(
          label: 'colorVariant',
          options: AuraColorVariant.values,
          initialOption: null,
          labelBuilder: (value) => value.name,
        ),
        textAlign: context.knobs.objectOrNull.dropdown(
          label: 'textAlign',
          options: [
            TextAlign.left,
            TextAlign.center,
            TextAlign.right,
            TextAlign.justify,
          ],
          initialOption: null,
          labelBuilder: (value) => value.name,
        ),
        maxLines: context.knobs.intOrNull.slider(
          label: 'maxLines',
          initialValue: null,
          min: 1,
          max: 10,
        ),
        showCursor: context.knobs.boolean(
          label: 'showCursor',
          initialValue: false,
        ),
        autofocus: context.knobs.boolean(
          label: 'autofocus',
          initialValue: false,
        ),
      ),
    ),
  );
}
