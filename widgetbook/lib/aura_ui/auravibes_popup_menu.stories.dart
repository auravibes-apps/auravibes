// Required: Widgetbook stories use intentional no-op callbacks.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_popup_menu.stories.bridge.g.dart';
part 'auravibes_popup_menu.stories.g.dart';

class const _PopupMenuInput();

const _component = ComponentMeta(name: 'AuraPopupMenu');
const _meta = Meta(AuraPopupMenu.new, argsType: _PopupMenuInput.new);

final _Defaults _popupMenuDefaults = _Defaults(
  builder: (context, args) {
    final controller = AuraPopupMenuController();

    return AuraPopupMenu(
      child: AuraIconButton(
        icon: Icons.more_vert,
        onPressed: controller.toggle,
        tooltip: 'Open popup menu',
      ),
      items: const [
        AuraPopupMenuItem(
          title: Text('Attach file'),
          onTap: StoryHelpers.noopCallback,
          leading: AuraIcon(Icons.attach_file),
        ),
        AuraPopupMenuItem(
          title: Text('Tools'),
          onTap: StoryHelpers.noopCallback,
          leading: AuraIcon(Icons.build_circle_outlined),
        ),
        AuraPopupMenuDivider(),
        AuraPopupMenuItem(
          title: Text('Continue agent'),
          leading: AuraIcon(Icons.play_circle_outline),
          trailing: AuraIcon(Icons.info_outline),
        ),
        AuraPopupMenuItem(
          title: Text('Compact conversation'),
          leading: AuraIcon(Icons.compress_outlined),
          trailing: AuraIcon(Icons.info_outline),
        ),
        AuraPopupMenuItem(
          title: Text('Delete'),
          onTap: StoryHelpers.noopCallback,
          leading: AuraIcon(Icons.delete_outline),
          variant: .error,
        ),
      ],
      controller: controller,
    );
  },
);

abstract final class _StorybookDefinitions {
  static final $BasicPopupMenu = _Story(
    name: 'Basic Popup Menu',
    setup: (context, child, args) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 300),
      child: child,
    ),
    args: _Args(),
    scenarios: [
      _Scenario(
        name: 'Opens Menu',
        modes: [ViewportMode(StoryHelpers.compactPhoneViewport)],
        run: (tester, args) async {
          await tester.tap(find.byType(AuraIconButton));
          await tester.pump(const Duration(milliseconds: 300));
        },
      ),
      _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(.rtl)]),
    ],
  );
}
