import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_avatar_group.stories.bridge.g.dart';
part 'auravibes_avatar_group.stories.g.dart';

const _meta = Meta(AuraAvatarGroup.new);

abstract final class _StorybookDefinitions {
  static final $Example = _Story(
    name: 'AuraAvatarGroup',
    setup: (context, child, args) =>
        StoryHelpers.constrainStoryWidth(child, maxWidth: 320),
    args: _Args(
      children: .fixed(const [
        AuraAvatar(child: Text('AL'), semanticLabel: 'Alex Lee'),
        AuraAvatar(child: Text('SR'), semanticLabel: 'Sam Rivera'),
        AuraAvatar(child: Text('JT'), semanticLabel: 'Jamie Taylor'),
      ]),
      maxVisible: .fixed(2),
      overflowSemanticLabel: NullableStringArg('1 more person'),
    ),
  );
}
