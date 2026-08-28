// Required: Widgetbook stories use intentional no-op callbacks.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_popup_menu.stories.g.dart';

class _PopupMenuInput {
  const _PopupMenuInput();
}

const component = ComponentMeta(name: 'AuraPopupMenu');
const meta = Meta(AuraPopupMenu.new, argsType: _PopupMenuInput.new);

final _Defaults popupMenuDefaults = _Defaults(
  builder: (context, args) {
    final controller = AuraPopupMenuController();

    return AuraPopupMenu(
      child: AuraIconButton(
        icon: Icons.more_vert,
        tooltip: 'Open popup menu',
        onPressed: controller.toggle,
      ),
      items: const [
        AuraPopupMenuItem(title: Text('Item 1'), onTap: noopCallback),
        AuraPopupMenuDivider(),
        AuraPopupMenuItem(title: Text('Item 2'), onTap: noopCallback),
      ],
      controller: controller,
    );
  },
);

final $BasicPopupMenu = _Story(
  name: 'Basic Popup Menu',
  setup: (context, child, args) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420, maxHeight: 300),
    child: child,
  ),
  args: _Args(),
  scenarios: [
    _Scenario(
      name: 'Opens Menu',
      modes: [ViewportMode(compactPhoneViewport)],
      run: (tester, args) async {
        await tester.tap(find.byType(AuraIconButton));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
  ],
);
