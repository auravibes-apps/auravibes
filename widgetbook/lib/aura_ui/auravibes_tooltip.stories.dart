// Required: Widgetbook stories use fixed example sizes.
// Required: Widgetbook stories use intentional no-op callbacks.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_tooltip.stories.g.dart';

const _defaultShowDurationMs = 2000.0;
const _minShowDurationMs = 500.0;
const _maxShowDurationMs = 5000.0;
const _maxWaitDurationMs = 2000.0;

class const _TooltipInput({
  required final String message,
  required final AuraTint tint,
  required final double showDurationMs,
  required final double waitDurationMs,
});

const meta = Meta(AuraTooltip.new, argsType: _TooltipInput.new);

final _Defaults tooltipDefaults = _Defaults(
  builder: (context, args) => AuraTooltip(
    message: args.message,
    child: IconButton(
      onPressed: noopCallback,
      tooltip: args.message,
      icon: const Icon(Icons.info_outline),
    ),
    tint: args.tint,
    showDuration: Duration(milliseconds: args.showDurationMs.toInt()),
    waitDuration: Duration(milliseconds: args.waitDurationMs.toInt()),
  ),
);

final $DefaultTooltip = _Story(
  name: 'Default Tooltip',
  args: _Args(
    message: StringArg('This is a helpful tooltip!', name: 'message'),
    tint: EnumArg(AuraTint.primary, name: 'tint', values: AuraTint.values),
    showDurationMs: DoubleArg(
      _defaultShowDurationMs,
      name: 'showDuration (ms)',
      style: const SliderDoubleArgStyle(
        min: _minShowDurationMs,
        max: _maxShowDurationMs,
        divisions: 90,
      ),
    ),
    waitDurationMs: DoubleArg(
      0,
      name: 'waitDuration (ms)',
      style: const SliderDoubleArgStyle(
        min: 0,
        max: _maxWaitDurationMs,
        divisions: 40,
      ),
    ),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(
      name: 'Shows Tooltip',
      run: (tester, args) async {
        await tester.longPress(find.byType(IconButton));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);
