import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_image.stories.bridge.g.dart';
part 'auravibes_image.stories.g.dart';

const _meta = Meta(AuraImage.new);

abstract final class _StorybookDefinitions {
  static final $BasicImage = _Story(
    name: 'Basic Image',
    setup: (context, child, args) => StoryHelpers.constrainStoryHeight(
      StoryHelpers.constrainStoryWidth(child, maxWidth: 320),
      maxHeight: 200,
    ),
    args: _Args(
      url: StringArg(
        'https://picsum.photos/seed/aura-image/320/200',
        name: 'URL',
      ),
      fit: EnumArg(BoxFit.cover, name: 'Fit', values: BoxFit.values),
      semanticLabel: NullableStringArg(null, name: 'Semantic Label'),
      imageProvider: .fixed(StoryHelpers.auraSampleImageProvider()),
    ),
  );
}
