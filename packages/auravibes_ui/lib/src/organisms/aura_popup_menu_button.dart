import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/organisms/aura_popup_menu_controller.dart';
import 'package:flutter/material.dart';

/// Icon button that opens an [AuraPopupMenu].
class AuraPopupMenuButton extends StatefulWidget {
  /// Creates an Aura popup menu button.
  const new({
    required this.items,
    super.key,
    this.icon = Icons.more_vert,
    this.tooltip,
  });

  /// The icon shown in the trigger button.
  final IconData icon;

  /// Tooltip shown for the trigger button.
  final String? tooltip;

  /// The menu entries shown when opened.
  final List<AuraPopupMenuEntry> items;

  @override
  State<AuraPopupMenuButton> createState() => _AuraPopupMenuButtonState();
}

class _AuraPopupMenuButtonState extends State<AuraPopupMenuButton> {
  final _controller = AuraPopupMenuController();

  @override
  Widget build(BuildContext context) {
    return AuraPopupMenu(
      child: AuraIconButton(
        icon: widget.icon,
        onPressed: _controller.toggle,
        tooltip: widget.tooltip,
      ),
      items: widget.items,
      controller: _controller,
    );
  }
}
