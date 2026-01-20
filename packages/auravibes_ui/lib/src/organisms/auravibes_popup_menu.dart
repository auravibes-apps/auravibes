import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

/// Controller for managing the visibility of a context menu.
class AuraPopupMenuController {
  /// Creates a new context menu controller.
  AuraPopupMenuController();

  _AuraPopupMenuState? _state;

  /// Whether the context menu is currently showing.
  bool get isShowing => _state?._visible ?? false;

  /// Opens the context menu.
  void open() => _state?.open();

  /// Closes the context menu.
  void close() => _state?.close();

  /// Toggles the visibility of the context menu.
  void toggle() => _state?.toggle();
}

/// A popup menu widget that displays a list of menu items.
///
/// The menu can be controlled programmatically using an
/// [AuraPopupMenuController].
class AuraPopupMenu extends StatefulWidget {
  /// Creates a new popup menu.
  ///
  /// [child] is the widget that triggers the menu.
  /// [items] is the list of menu entries to display.
  /// [controller] is used to programmatically control menu visibility.
  const AuraPopupMenu({
    required this.child,
    required this.items,
    required this.controller,
    super.key,
  });

  /// The widget that triggers the popup menu.
  final Widget child;

  /// The list of menu items to display in the popup.
  final List<AuraPopupMenuEntry> items;

  /// Controller for managing menu visibility.
  final AuraPopupMenuController controller;

  @override
  State<AuraPopupMenu> createState() => _AuraPopupMenuState();
}

class _AuraPopupMenuState extends State<AuraPopupMenu> {
  bool _visible = false;
  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(covariant AuraPopupMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller._state = this;
  }

  void open() {
    setState(() {
      _visible = true;
    });
  }

  void close() {
    setState(() {
      _visible = false;
    });
  }

  void toggle() {
    setState(() {
      _visible = !_visible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PortalTarget(
      visible: _visible,
      anchor: const Aligned(
        follower: .topCenter,
        target: .bottomCenter,
        portal: .bottomCenter,
        shiftToWithinBound: .new(
          x: true,
          y: true,
        ),
      ),
      fit: .passthrough,
      portalFollower: SizedBox(
        width: 200,
        child: AuraCard(
          padding: .none,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: .start,
            children: widget.items
                .map((e) => Builder(builder: e.build))
                .toList(),
          ),
        ),
      ),
      child: widget.child,
    );
  }
}

/// Base class for entries in a popup menu.
///
/// This abstract class defines the interface for all menu items,
/// including regular items, dividers, and custom builders.
// ignore: one_member_abstracts
abstract class AuraPopupMenuEntry {
  /// Creates a new menu entry.
  const AuraPopupMenuEntry();

  /// Builds the widget for this menu entry.
  Widget build(BuildContext context);
}

/// A menu entry that builds a custom widget.
///
/// This allows for arbitrary widgets to be included in the menu.
class AuraPopupMenuBuilder extends AuraPopupMenuEntry {
  /// Creates a custom menu entry.
  ///
  /// [_build] is the function that builds the widget for this entry.
  const AuraPopupMenuBuilder(this._build);

  /// The builder function for this menu entry.
  final Widget Function(BuildContext context) _build;

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }
}

/// A divider for separating menu items.
///
/// Displays a horizontal line between menu items.
class AuraPopupMenuDivider extends AuraPopupMenuEntry {
  /// Creates a new menu divider.
  const AuraPopupMenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
    );
  }
}

/// A standard menu item in a popup menu.
///
/// Displays a title with optional leading and trailing widgets,
/// and can be tapped to trigger an action.
class AuraPopupMenuItem extends AuraPopupMenuEntry {
  /// Creates a new menu item.
  ///
  /// [title] is the main content of the menu item.
  /// [onTap] is the callback when the item is tapped.
  /// [leading] is an optional widget displayed before the title.
  /// [trailing] is an optional widget displayed after the title.
  const AuraPopupMenuItem({
    required this.title,
    this.onTap,
    this.leading,
    this.trailing,
  });

  /// The main content of the menu item.
  final Widget title;

  /// Callback when the item is tapped.
  final VoidCallback? onTap;

  /// Optional widget displayed before the title.
  final Widget? leading;

  /// Optional widget displayed after the title.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AuraTile(
      onTap: onTap,
      leading: leading,
      trailing: trailing,
      variant: .ghost,
      child: title,
    );
  }
}
