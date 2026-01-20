import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Basic Popup Menu', type: AuraPopupMenu)
Widget basicContextMenuUseCase(BuildContext context) {
  final AuraPopupMenuController controller = AuraPopupMenuController();

  return AuraPopupMenu(
    controller: controller,
    items: [
      AuraPupupMenuItem(title: Text('Item 1'), onTap: () {}),
      AuraPupupMenuDivider(),
      AuraPupupMenuItem(title: Text('Item 2'), onTap: () {}),
    ],
    child: MaterialButton(
      onPressed: () {
        controller.toggle();
      },
      child: const Text('Open Popup Menu'),
    ),
  );
}
