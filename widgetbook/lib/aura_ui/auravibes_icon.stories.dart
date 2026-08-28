// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

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

class _IconInput {
  const _IconInput({required this.icon, required this.size});

  final IconData icon;
  final AuraIconSize size;
}

const component = ComponentMeta(name: 'AuraIcon');
const meta = Meta(AuraIcon.new, argsType: _IconInput.new);

final _Defaults iconDefaults = _Defaults(
  builder: (context, args) => AuraIcon(
    args.icon,
    size: args.size,
    semanticLabel: auraIconLabel(args.icon),
  ),
);

final $BasicIcons = _Story(
  name: 'Basic Icons',
  args: _Args(
    icon: SingleArg(
      Icons.add,
      values: _iconValues,
      labelBuilder: auraIconLabel,
    ),
    size: EnumArg(AuraIconSize.values.first, values: AuraIconSize.values),
  ),
);
