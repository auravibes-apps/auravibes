// ignore_for_file: avoid-returning-widgets
// Required: Widgetbook stories use helper functions that return widgets.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Basic Popup Menu', type: AuraPopupMenu)
Widget basicContextMenuUseCase(BuildContext _) {
  final controller = AuraPopupMenuController();

  return AuraPopupMenu(
    child: MaterialButton(
      onPressed: () {
        controller.toggle();
      },
      child: const Text('Open Popup Menu'),
    ),
    items: [
      AuraPopupMenuItem(title: const Text('Item 1'), onTap: () {}),
      const AuraPopupMenuDivider(),
      AuraPopupMenuItem(title: const Text('Item 2'), onTap: () {}),
    ],
    controller: controller,
  );
}
