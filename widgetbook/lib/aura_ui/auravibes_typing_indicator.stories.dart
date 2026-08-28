// Required: Widgetbook stories use fixed example sizes.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_typing_indicator.stories.g.dart';

class _TypingIndicatorInput {
  const _TypingIndicatorInput({
    required this.size,
    required this.color,
    required this.showContainer,
    required this.animationDurationMs,
  });

  final AuraTypingIndicatorSize size;
  final Color color;
  final bool showContainer;
  final int animationDurationMs;
}

const meta = Meta(AuraTypingIndicator.new, argsType: _TypingIndicatorInput.new);

final _Defaults typingIndicatorDefaults = _Defaults(
  builder: (context, args) => AuraTypingIndicator(
    size: args.size,
    color: args.color,
    showContainer: args.showContainer,
    animationDuration: Duration(milliseconds: args.animationDurationMs),
  ),
);

final $DefaultTypingIndicator = _Story(
  name: 'Default Typing Indicator',
  setup: (context, child, args) =>
      Padding(padding: const EdgeInsets.all(16), child: child),
  args: _Args(
    size: EnumArg(
      AuraTypingIndicatorSize.values.first,
      values: AuraTypingIndicatorSize.values,
    ),
    color: ColorArg(Colors.grey, name: 'color'),
    showContainer: BoolArg(true),
    animationDurationMs: IntArg(
      600,
      name: 'animationDuration (ms)',
      style: const SliderIntArgStyle(min: 100, max: 2000, divisions: 1900),
    ),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(
      name: 'Animated Frame',
      run: (tester, args) async {
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);
