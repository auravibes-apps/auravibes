import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_app_bar.stories.g.dart';

class _AppBarInput {
  const _AppBarInput({required this.title, required this.showLeading});

  final String title;
  final bool showLeading;
}

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
class AppBarDemo extends StatelessWidget implements PreferredSizeWidget {
  const AppBarDemo({required this.title, required this.showLeading, super.key});

  final String title;
  final bool showLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AuraAppBar(
      title: Text(title),
      leading: showLeading
          ? const AuraIconButton(
              icon: Icons.menu,
              tooltip: 'Open menu',
              onPressed: noopCallback,
            )
          : null,
      actions: const [
        AuraIconButton(
          icon: Icons.notifications_none,
          tooltip: 'Notifications',
          onPressed: noopCallback,
        ),
      ],
    );
  }
}
