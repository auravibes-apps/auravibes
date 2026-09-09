// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_text.stories.bridge.g.dart';
part 'auravibes_text.stories.g.dart';

class const _TextInput({
  required final String text,
  required final AuraTextStyle style,
  required final TextAlign? textAlign,
  required final AuraTint? tint,
});

const _meta = Meta(AuraText.new, argsType: _TextInput.new);

final _Defaults _textDefaults = _Defaults(
  builder: (context, args) => AuraText(
    child: Text(args.text),
    style: args.style,
    textAlign: args.textAlign,
    tint: args.tint,
  ),
);

abstract final class _StorybookDefinitions {
  static final $AuraText = _Story(
    name: 'AuraText',
    setup: (context, child, args) => StoryHelpers.constrainStoryWidth(child),
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
}
