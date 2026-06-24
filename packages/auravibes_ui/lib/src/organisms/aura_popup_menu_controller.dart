// Required: Existing test and UI helpers keep compact return flow.
// Required: Component callbacks stay colocated with UI state.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Icon button that opens an [AuraPopupMenu].
class AuraPopupMenuButton extends StatefulWidget {
  /// Creates an Aura popup menu button.
  const AuraPopupMenuButton({
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
  /// [focusNode] defines the keyboard focus for this widget.
  const AuraPopupMenu({
    required this.child,
    required this.items,
    required this.controller,
    this.focusNode,
    super.key,
  });

  /// The widget that triggers the popup menu.
  final Widget child;

  /// The list of menu items to display in the popup.
  final List<AuraPopupMenuEntry> items;

  /// Controller for managing menu visibility.
  final AuraPopupMenuController controller;

  /// Defines the keyboard focus for this widget.
  final FocusNode? focusNode;

  @override
  State<AuraPopupMenu> createState() => _AuraPopupMenuState();
}

class _AuraPopupMenuState extends State<AuraPopupMenu> {
  FocusNode? _focusNode;
  FocusScopeNode? _menuFocusScopeNode;
  bool _visible = false;

  FocusNode get _requiredFocusNode {
    final node = _focusNode;
    if (node == null) {
      throw StateError('Focus node not initialized');
    }

    return node;
  }

  FocusScopeNode get _requiredMenuFocusScopeNode {
    final node = _menuFocusScopeNode;
    if (node == null) {
      throw StateError('Menu focus scope node not initialized');
    }

    return node;
  }

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _menuFocusScopeNode = FocusScopeNode(
      debugLabel: 'AuraPopupMenu menu',
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _visible) {
          close();

          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
    );
    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(covariant AuraPopupMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller._state = this;
  }

  @override
  void dispose() {
    widget.controller._state = null;
    if (widget.focusNode == null) {
      _requiredFocusNode.dispose();
    }
    _requiredMenuFocusScopeNode.dispose();
    super.dispose();
  }

  void open() {
    if (_visible) {
      return;
    }

    setState(() {
      _visible = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_visible) {
        return;
      }

      _requiredMenuFocusScopeNode.requestFocus();
    });
  }

  void close() {
    if (!_visible) {
      return;
    }

    setState(() {
      _visible = false;
    });
    _requiredFocusNode.unfocus();
  }

  void toggle() {
    if (_visible) {
      close();
    } else {
      open();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: PortalTarget(
        visible: _visible,
        portalFollower: GestureDetector(
          onTap: close,
          behavior: HitTestBehavior.opaque,
        ),
        child: PortalTarget(
          visible: _visible,
          anchor: const Aligned(
            follower: .topCenter,
            target: .bottomCenter,
            portal: .bottomCenter,
            shiftToWithinBound: .new(x: true, y: true),
          ),
          portalFollower: TapRegion(
            child: FocusScope(
              node: _requiredMenuFocusScopeNode,
              child: SizedBox(
                width: 200,
                child: AuraCard(
                  child: _AuraPopupMenuCloseScope(
                    close: close,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: .start,
                      children: widget.items
                          .map((e) => Builder(builder: e.build))
                          .toList(),
                    ),
                  ),
                  padding: .none,
                  style: AuraCardStyle.border,
                ),
              ),
            ),
            groupId: this,
          ),
          child: TapRegion(
            child: widget.child,
            groupId: this,
          ),
        ),
      ),
      focusNode: _requiredFocusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _visible) {
          close();

          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      skipTraversal: true,
      descendantsAreFocusable: true,
    );
  }
}

class _AuraPopupMenuCloseScope extends InheritedWidget {
  const _AuraPopupMenuCloseScope({
    required this.close,
    required super.child,
  });

  final VoidCallback close;

  static VoidCallback? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_AuraPopupMenuCloseScope>()
        ?.close;
  }

  @override
  bool updateShouldNotify(_AuraPopupMenuCloseScope oldWidget) {
    return close != oldWidget.close;
  }
}

/// Base class for entries in a popup menu.
///
/// This abstract class defines the interface for all menu items,
/// including regular items, dividers, and custom builders.
// ignore: one_member_abstracts - Required as extension point for menu entries.
abstract class AuraPopupMenuEntry {
  /// Creates a new menu entry.
  const AuraPopupMenuEntry();

  /// Builds the widget for this menu entry.
  Widget build(BuildContext context);
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
    this.variant = .ghost,
  });

  /// The main content of the menu item.
  final Widget title;

  /// Callback when the item is tapped.
  final VoidCallback? onTap;

  /// Optional widget displayed before the title.
  final Widget? leading;

  /// Optional widget displayed after the title.
  final Widget? trailing;

  /// The visual variant of the menu item.
  final AuraTileVariant variant;

  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: title,
      onTap: () {
        onTap?.call();
        _AuraPopupMenuCloseScope.maybeOf(context)?.call();
      },
      variant: variant,
      leading: leading,
      trailing: trailing,
    );
  }
}
