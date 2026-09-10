import 'package:auravibes_ui/src/atoms/aura_tile.dart';
import 'package:auravibes_ui/src/molecules/aura_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';

export 'aura_popup_menu_button.dart';

typedef _PopupFocusNode = ({FocusNode node, bool ownsNode});

typedef _PopupMenuKeyRequest = ({
  FocusNode node,
  KeyEvent event,
  FocusNode trigger,
  bool visible,
  VoidCallback toggle,
  VoidCallback close,
});

/// Controller for managing the visibility of a context menu.
class AuraPopupMenuController {
  /// Creates a new context menu controller.
  new();

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
  /// [focusNode] defines the keyboard focus for this widget.
  const new({
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
  late final FocusScopeNode _menuFocusScopeNode;
  bool _ownsFocusNode = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _initializePopupMenuFocus();
    _menuFocusScopeNode = .new(
      debugLabel: 'AuraPopupMenu menu',
      onKeyEvent: _handleMenuKeyEvent,
    );
    widget.controller._state = this;
  }

  @override
  void dispose() {
    _visible = false;
    widget.controller._state = null;
    if (_ownsFocusNode) {
      _requiredFocusNode.dispose();
    }
    _menuFocusScopeNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AuraPopupMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePopupMenuFocusNode(this, oldWidget.focusNode, widget.focusNode);
    widget.controller._state = this;
  }

  void open() {
    if (_visible) {
      return;
    }

    setState(() {
      _visible = true;
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _requestMenuFocus(this),
    );
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
  Widget build(BuildContext context) => _AuraPopupMenuData(
    visible: _visible,
    menuFocusScopeNode: _menuFocusScopeNode,
    items: widget.items,
    close: close,
    trigger: widget.child,
    focusNode: _requiredFocusNode,
    onKeyEvent: _handleMenuKeyEvent,
    groupId: this,
  ).child;

  KeyEventResult _handleMenuKeyEvent(FocusNode node, KeyEvent event) =>
      _handlePopupMenuKey((
        node: node,
        event: event,
        trigger: _requiredFocusNode,
        visible: _visible,
        toggle: toggle,
        close: close,
      ));
}

extension on _AuraPopupMenuState {
  void _initializePopupMenuFocus() {
    final focus = _popupFocusNode(widget.focusNode);
    _focusNode = focus.node;
    _ownsFocusNode = focus.ownsNode;
  }

  FocusNode get _requiredFocusNode {
    final node = _focusNode;
    if (node == null) {
      throw StateError('Focus node not initialized');
    }

    return node;
  }
}

_PopupFocusNode _popupFocusNode(FocusNode? focusNode) =>
    (node: focusNode ?? FocusNode(), ownsNode: focusNode == null);

void _updatePopupMenuFocusNode(
  _AuraPopupMenuState state,
  FocusNode? oldFocusNode,
  FocusNode? newFocusNode,
) {
  if (oldFocusNode == newFocusNode) return;
  if (state._ownsFocusNode) state._requiredFocusNode.dispose();

  final focus = _popupFocusNode(newFocusNode);
  state._focusNode = focus.node;
  state._ownsFocusNode = focus.ownsNode;
}

void _requestMenuFocus(_AuraPopupMenuState state) {
  if (!state.mounted || !state._visible) return;

  state._menuFocusScopeNode.requestFocus();
}

KeyEventResult _handlePopupMenuKey(_PopupMenuKeyRequest request) {
  final event = request.event;
  if (event is! KeyDownEvent) return KeyEventResult.ignored;

  if (_shouldTogglePopupMenu(request, event)) {
    request.toggle();

    return KeyEventResult.handled;
  }

  if (_shouldClosePopupMenu(request, event)) {
    request.close();

    return KeyEventResult.handled;
  }

  return KeyEventResult.ignored;
}

bool _isPopupMenuActivationKey(LogicalKeyboardKey key) =>
    key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space;

bool _shouldTogglePopupMenu(_PopupMenuKeyRequest request, KeyDownEvent event) =>
    request.node == request.trigger &&
    _isPopupMenuActivationKey(event.logicalKey);

bool _shouldClosePopupMenu(_PopupMenuKeyRequest request, KeyDownEvent event) =>
    request.visible && event.logicalKey == LogicalKeyboardKey.escape;

class _AuraPopupMenuData {
  _AuraPopupMenuData({
    required bool visible,
    required FocusScopeNode menuFocusScopeNode,
    required List<AuraPopupMenuEntry> items,
    required VoidCallback close,
    required Widget trigger,
    required FocusNode focusNode,
    required FocusOnKeyEventCallback onKeyEvent,
    required Object groupId,
  }) : child = PortalTarget(
         visible: visible,
         anchor: const Aligned(
           follower: .topCenter,
           target: .bottomCenter,
           portal: .bottomCenter,
           shiftToWithinBound: .new(x: true, y: true),
         ),
         portalFollower: TapRegion(
           child: FocusScope(
             node: menuFocusScopeNode,
             child: SizedBox(
               width: 200,
               child: AuraCard(
                 child: _AuraPopupMenuCloseScope(
                   close: close,
                   child: Column(
                     mainAxisSize: .min,
                     crossAxisAlignment: .start,
                     children: items
                         .map((e) => Builder(builder: e.build))
                         .toList(),
                   ),
                 ),
                 padding: .none,
                 style: .border,
               ),
             ),
           ),
           onTapOutside: (_) => close(),
           groupId: groupId,
         ),
         child: Focus(
           child: TapRegion(child: trigger, groupId: groupId),
           focusNode: focusNode,
           onKeyEvent: onKeyEvent,
           descendantsAreFocusable: false,
         ),
       );

  final Widget child;
}

class const _AuraPopupMenuCloseScope({
  required final VoidCallback close,
  required super.child,
}) extends InheritedWidget {
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
abstract class AuraPopupMenuEntry {
  /// Creates a new menu entry.
  const new();

  /// Builds the widget for this menu entry.
  Widget build(BuildContext context);
}

/// A divider for separating menu items.
///
/// Displays a horizontal line between menu items.
class AuraPopupMenuDivider extends AuraPopupMenuEntry {
  /// Creates a new menu divider.
  const new();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1);
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
  const new({
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
      semanticLabel: 'Menu item',
    );
  }
}
