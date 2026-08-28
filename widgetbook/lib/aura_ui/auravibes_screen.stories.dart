// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_screen.stories.g.dart';

class _ScreenInput {
  const _ScreenInput({required this.variant});

  final AuraScreenVariation variant;
}

const meta = Meta(AuraScreen.new, argsType: _ScreenInput.new);

final _Defaults screenDefaults = _Defaults(
  builder: (context, args) => AuraScreen(
    child: const Center(
      child: AuraPadding(
        child: AuraCard(
          child: SizedBox(
            width: 300,
            height: 300,
            child: AuraText(child: Text('Hello, Aura Screen!')),
          ),
          style: AuraCardStyle.glass,
        ),
        padding: AuraEdgeInsetsGeometry.large,
      ),
    ),
    appBar: AppBar(
      title: Text(
        'Aura Screen',
        style: TextStyle(color: context.auraColors.onPrimary),
      ),
      backgroundColor: context.auraColors.primary,
    ),
    variant: args.variant,
  ),
);

final $AuraScreen = _Story(
  name: 'Aura Screen',
  setup: (context, child, args) =>
      SizedBox(width: 420, height: 500, child: child),
  args: _Args(
    variant: EnumArg(
      AuraScreenVariation.values.first,
      name: 'variant',
      values: AuraScreenVariation.values,
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
    _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
  ],
);
