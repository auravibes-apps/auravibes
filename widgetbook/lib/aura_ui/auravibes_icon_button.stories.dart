// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_icon_button.stories.bridge.g.dart';
part 'auravibes_icon_button.stories.g.dart';

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

class const _IconButtonInput({
  required final IconData icon,
  required final bool disabled,
  required final AuraIconSize size,
  required final AuraIconButtonVariant variant,
  required final String tooltip,
});

const _component = ComponentMeta(name: 'AuraIconButton');
const _meta = Meta(AuraIconButton.new, argsType: _IconButtonInput.new);

final _Defaults _iconButtonDefaults = _Defaults(
  builder: (context, args) => AuraIconButton(
    icon: args.icon,
    onPressed: () {
      final _ = ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Icon button pressed!')));
    },
    disabled: args.disabled,
    size: args.size,
    variant: args.variant,
    tooltip: args.tooltip,
  ),
);

abstract final class _StorybookDefinitions {
  static final $IconButtonBasic = _Story(
    name: 'Icon Button Basic',
    setup: (context, child, args) =>
        SizedBox(width: 420, height: 200, child: Scaffold(body: child)),
    args: _Args(
      icon: SingleArg(
        Icons.add,
        values: _iconValues,
        labelBuilder: StoryHelpers.auraIconLabel,
      ),
      disabled: BoolArg(false, name: 'Disabled'),
      size: EnumArg(AuraIconSize.values.first, values: AuraIconSize.values),
      variant: EnumArg(
        AuraIconButtonVariant.values.first,
        values: AuraIconButtonVariant.values,
      ),
      tooltip: StringArg('Add to favorites', name: 'Tooltip'),
    ),
    scenarios: [
      _Scenario(
        name: 'Compact Phone',
        modes: [ViewportMode(StoryHelpers.compactPhoneViewport)],
      ),
      _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(.rtl)]),
      _Scenario(
        name: 'Pressed',
        run: (tester, args) async {
          await tester.tap(find.byType(AuraIconButton));
          await tester.pump(const Duration(milliseconds: 300));
        },
      ),
    ],
  );
}
