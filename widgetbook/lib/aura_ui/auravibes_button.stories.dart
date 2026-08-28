// Required: Widgetbook stories use intentional no-op callbacks.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_button.stories.g.dart';

class _ButtonInput {
  const _ButtonInput({
    required this.buttonContent,
    required this.variant,
    required this.size,
    required this.isLoading,
    required this.isFullWidth,
    required this.disabled,
    required this.semanticLabel,
  });

  final String buttonContent;
  final AuraButtonVariant variant;
  final AuraButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final bool disabled;
  final String semanticLabel;
}

const meta = Meta(AuraButton.new, argsType: _ButtonInput.new);

final _Defaults buttonDefaults = _Defaults(
  builder: (context, args) => AuraButton(
    onPressed: noopCallback,
    child: Text(args.buttonContent),
    variant: args.variant,
    size: args.size,
    isLoading: args.isLoading,
    isFullWidth: args.isFullWidth,
    disabled: args.disabled,
    semanticLabel: args.semanticLabel,
  ),
);

final $PrimaryButton = _Story(
  name: 'Primary Button',
  args: _Args(
    buttonContent: StringArg('Primary Button', name: 'button content'),
    variant: EnumArg(
      AuraButtonVariant.primary,
      values: AuraButtonVariant.values,
    ),
    size: EnumArg(AuraButtonSize.medium, values: AuraButtonSize.values),
    isLoading: BoolArg(false),
    isFullWidth: BoolArg(false),
    disabled: BoolArg(false),
    semanticLabel: StringArg('Primary action', name: 'Semantic Label'),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
    _Scenario(
      name: 'Pressed',
      run: (tester, args) async {
        await tester.tap(find.byType(AuraButton));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);
