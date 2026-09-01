import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_linear_progress_indicator.stories.g.dart';

class const _ProgressInput({
  required final double value,
  required final double height,
  required final AuraTint tint,
  required final double backgroundAlpha,
  required final AuraBorderRadius borderRadius,
  required final String semanticLabel,
  required final String semanticValue,
});

const meta = Meta(
  AuraLinearProgressIndicator.new,
  argsType: _ProgressInput.new,
);

final $Progress = _Story(
  name: 'Progress',
  setup: (context, child, args) => SizedBox(
    width: 360,
    child: Padding(padding: const EdgeInsets.all(24), child: child),
  ),
  args: _Args(
    value: DoubleArg(
      0.65,
      name: 'Value',
      style: const SliderDoubleArgStyle(min: 0, max: 1, divisions: 20),
    ),
    height: DoubleArg(
      8,
      name: 'Height',
      style: const SliderDoubleArgStyle(min: 1, max: 24, divisions: 23),
    ),
    tint: EnumArg(AuraTint.primary, values: AuraTint.values),
    backgroundAlpha: DoubleArg(
      1,
      name: 'Background Alpha',
      style: const SliderDoubleArgStyle(min: 0, max: 1, divisions: 10),
    ),
    borderRadius: EnumArg(
      AuraBorderRadius.full,
      values: AuraBorderRadius.values,
    ),
    semanticLabel: StringArg('Upload progress', name: 'Semantic Label'),
    semanticValue: StringArg('65 percent', name: 'Semantic Value'),
  ),
  builder: (context, args) => AuraLinearProgressIndicator(
    value: args.value,
    height: args.height,
    tint: args.tint,
    backgroundAlpha: args.backgroundAlpha,
    borderRadius: args.borderRadius,
    semanticLabel: args.semanticLabel,
    semanticValue: args.semanticValue,
  ),
  scenarios: [
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
  ],
);
