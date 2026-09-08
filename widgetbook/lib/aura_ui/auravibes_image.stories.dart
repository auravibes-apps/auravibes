// Required: Widgetbook stories use fixed example sizes.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_image.stories.g.dart';

const meta = Meta(AuraImage.new);

final $BasicImage = _Story(
  name: 'Basic Image',
  setup: (context, child, args) =>
      SizedBox(width: 320, height: 200, child: child),
  args: _Args(
    url: StringArg(
      'https://picsum.photos/seed/aura-image/320/200',
      name: 'URL',
    ),
    fit: EnumArg(BoxFit.cover, name: 'Fit', values: BoxFit.values),
    semanticLabel: NullableStringArg(null, name: 'Semantic Label'),
    imageProvider: Arg.fixed(auraSampleImageProvider()),
  ),
);
