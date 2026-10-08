import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_avatar.stories.bridge.g.dart';
part 'auravibes_avatar.stories.g.dart';

const _meta = Meta(AuraAvatar.new);

abstract final class _StorybookDefinitions {
  static final $Example = _Story(
    name: 'AuraAvatar',
    setup: (context, child, args) =>
        StoryHelpers.constrainStoryWidth(child, maxWidth: 320),
    args: _Args(
      child: .fixed(const Text('AL')),
      semanticLabel: NullableStringArg('Alex Lee'),
      size: EnumArg(AuraSpacing.xl2, values: AuraSpacing.values),
      tint: EnumArg(AuraTint.primary, values: AuraTint.values),
    ),
  );
}
