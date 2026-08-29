import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_popup_menu_button.stories.g.dart';

const component = ComponentMeta(name: 'AuraPopupMenuButton');
const meta = Meta(PopupMenuButtonDemo.new);

final $PopupMenuButton = _Story(
  name: 'Popup Menu Button',
  setup: (context, child, args) =>
      SizedBox(width: 360, height: 180, child: Scaffold(body: child)),
  args: _Args(),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(name: 'Arabic', modes: [AuraArabicLocaleMode()]),
    _Scenario(
      name: 'Opens Menu',
      run: (tester, args) async {
        await tester.tap(find.byType(AuraPopupMenuButton));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Edit'), findsOneWidget);
      },
    ),
  ],
);

/// Demonstrates a labeled popup-menu trigger and its action entries.
class PopupMenuButtonDemo extends StatelessWidget {
  const PopupMenuButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: AlignmentDirectional.topEnd,
      child: AuraPopupMenuButton(
        items: [
          AuraPopupMenuItem(title: Text('Edit'), onTap: noopCallback),
          AuraPopupMenuItem(title: Text('Duplicate'), onTap: noopCallback),
          AuraPopupMenuItem(title: Text('Delete'), onTap: noopCallback),
        ],
        tooltip: 'More actions',
      ),
    );
  }
}
