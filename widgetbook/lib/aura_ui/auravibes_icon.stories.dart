// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_icon.stories.bridge.g.dart';
part 'auravibes_icon.stories.g.dart';

const _iconValues = <IconData>[
  Icons.add,
  Icons.edit,
  Icons.favorite,
  Icons.thumb_up,
  Icons.star,
  Icons.info,
  Icons.settings,
  Icons.search,
  Icons.home,
  Icons.person,
  Icons.camera_alt,
  Icons.phone,
  Icons.map,
  Icons.lock,
];

class const _IconInput({
  required final IconData icon,
  required final AuraIconSize size,
});

const _component = ComponentMeta(name: 'AuraIcon');
const _meta = Meta(AuraIcon.new, argsType: _IconInput.new);

final _Defaults _iconDefaults = _Defaults(
  builder: (context, args) => AuraIcon(
    args.icon,
    size: args.size,
    semanticLabel: StoryHelpers.auraIconLabel(args.icon),
  ),
);

abstract final class _StorybookDefinitions {
  static final $BasicIcons = _Story(
    name: 'Basic Icons',
    args: _Args(
      icon: SingleArg(
        Icons.add,
        values: _iconValues,
        labelBuilder: StoryHelpers.auraIconLabel,
      ),
      size: EnumArg(AuraIconSize.values.first, values: AuraIconSize.values),
    ),
  );
}
