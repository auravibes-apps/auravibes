// Required: Widgetbook stories use fixed example sizes.

// Required: Widgetbook stories use intentional no-op callbacks.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.
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
      child: IconButton(
        onPressed: () {
          final _ = Object();
        },
        icon: const Icon(Icons.info_outline),
      ),
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
