import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_list.stories.g.dart';

class _ListInput {
  const _ListInput({required this.direction, required this.itemCount});

  final Axis direction;
  final int itemCount;
}

const meta = Meta(AuraList.new, argsType: _ListInput.new);

final _Defaults listDefaults = _Defaults(
  builder: (context, args) => AuraList(
    children: [
      for (var index = 0; index < args.itemCount; index++)
        Container(
          width: args.direction == Axis.horizontal ? 160 : null,
          height: 72,
          color: context.auraColors.surfaceVariant,
          child: Center(
            child: Text(
              'Item ${index + 1}',
              style: TextStyle(color: context.auraColors.onSurface),
            ),
          ),
        ),
    ],
    direction: args.direction,
  ),
);

final $AuraList = _Story(
  name: 'AuraList',
  setup: (context, child, args) => SizedBox(
    width: 420,
    height: args.direction == Axis.vertical ? 320 : 140,
    child: child,
  ),
  args: _Args(
    direction: EnumArg(Axis.vertical, name: 'direction', values: Axis.values),
    itemCount: IntArg(
      8,
      name: 'item count',
      style: const SliderIntArgStyle(min: 0, max: 20, divisions: 20),
    ),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(
      name: 'Landscape Phone',
      modes: [ViewportMode(landscapePhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
  ],
);
