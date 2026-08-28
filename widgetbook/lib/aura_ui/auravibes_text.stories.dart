// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_text.stories.g.dart';

class _TextInput {
  const _TextInput({
    required this.text,
    required this.style,
    required this.textAlign,
    required this.tint,
  });

  final String text;
  final AuraTextStyle style;
  final TextAlign? textAlign;
  final AuraTint? tint;
}

const meta = Meta(AuraText.new, argsType: _TextInput.new);

final _Defaults textDefaults = _Defaults(
  builder: (context, args) => AuraText(
    child: Text(args.text),
    style: args.style,
    textAlign: args.textAlign,
    tint: args.tint,
  ),
);

final $AuraText = _Story(
  name: 'AuraText',
  setup: (context, child, args) => constrainStoryWidth(child),
  args: _Args(
    text: StringArg('This is an example of AuraText widget.', name: 'Text'),
    style: EnumArg(
      AuraTextStyle.body,
      name: 'Style',
      values: AuraTextStyle.values,
    ),
    textAlign: NullableEnumArg(
      null,
      name: 'Text Align',
      values: TextAlign.values,
    ),
    tint: NullableEnumArg(null, name: 'Tint', values: AuraTint.values),
  ),
);
