import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_app_bar.stories.g.dart';

class const _AppBarInput({
  required final String title,
  required final bool showLeading,
});

const component = ComponentMeta(name: 'AuraAppBar');
const meta = Meta(AppBarDemo.new, argsType: _AppBarInput.new);

final _Defaults appBarDefaults = _Defaults(
  builder: (context, args) =>
      AppBarDemo(title: args.title, showLeading: args.showLeading),
);

final $AppBar = _Story(
  name: 'App Bar',
  setup: (context, child, args) => ColoredBox(
    color: context.auraColors.surface,
    child: SizedBox(width: 420, height: 120, child: child),
  ),
  args: _Args(
    title: StringArg('AuraVibes', name: 'Title'),
    showLeading: BoolArg(true, name: 'Show Leading'),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(name: 'Arabic', modes: [AuraArabicLocaleMode()]),
    _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
  ],
);

/// Demonstrates the Aura app bar with editable title and leading action.
class const AppBarDemo({
  required final String title,
  required final bool showLeading,
  super.key,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AuraAppBar(
      title: Text(title),
      actions: const [
        AuraIconButton(
          icon: Icons.notifications_none,
          onPressed: noopCallback,
          tooltip: 'Notifications',
        ),
      ],
      leading: showLeading
          ? const AuraIconButton(
              icon: Icons.menu,
              onPressed: noopCallback,
              tooltip: 'Open menu',
            )
          : null,
    );
  }
}
