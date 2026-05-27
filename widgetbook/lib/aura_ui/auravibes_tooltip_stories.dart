// ignore_for_file: no-magic-number
// Required: Widgetbook stories use fixed example sizes.
// ignore_for_file: avoid-returning-widgets
// Required: Widgetbook stories use helper functions that return widgets.
// ignore_for_file: no-empty-block
// Required: Widgetbook stories use intentional no-op callbacks.
// ignore_for_file: prefer-moving-to-variable
// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default Tooltip', type: AuraTooltip)
Widget defaultTooltipUseCase(BuildContext context) {
  return Center(
    child: AuraTooltip(
      message: context.knobs.string(
        label: 'message',
        initialValue: 'This is a helpful tooltip!',
      ),
      child: IconButton(onPressed: () {}, icon: const Icon(Icons.info_outline)),
      colorVariant: context.knobs.object.dropdown(
        label: 'colorVariant',
        options: AuraColorVariant.values,
        initialOption: AuraColorVariant.onSurface,
        labelBuilder: (value) => value.name,
      ),
      showDuration: Duration(
        milliseconds: context.knobs.double
            .slider(
              label: 'showDuration (ms)',
              initialValue: 2000,
              min: 500,
              max: 5000,
            )
            .toInt(),
      ),
      waitDuration: Duration(
        milliseconds: context.knobs.double
            .slider(
              label: 'waitDuration (ms)',
              initialValue: 0,
              min: 0,
              max: 2000,
            )
            .toInt(),
      ),
    ),
  );
}
