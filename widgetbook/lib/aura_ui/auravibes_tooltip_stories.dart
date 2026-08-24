// Required: Widgetbook stories use fixed example sizes.

// Required: Widgetbook stories use intentional no-op callbacks.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _defaultShowDurationMs = 2000.0;
const _minShowDurationMs = 500.0;
const _maxShowDurationMs = 5000.0;
const _maxWaitDurationMs = 2000.0;

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
      tint: context.knobs.object.dropdown(
        label: 'tint',
        options: AuraTint.values,
        initialOption: AuraTint.primary,
        labelBuilder: (value) => value.name,
      ),
      showDuration: Duration(
        milliseconds: context.knobs.double
            .slider(
              label: 'showDuration (ms)',
              initialValue: _defaultShowDurationMs,
              min: _minShowDurationMs,
              max: _maxShowDurationMs,
            )
            .toInt(),
      ),
      waitDuration: Duration(
        milliseconds: context.knobs.double
            .slider(
              label: 'waitDuration (ms)',
              initialValue: 0,
              min: 0,
              max: _maxWaitDurationMs,
            )
            .toInt(),
      ),
    ),
  );
}
