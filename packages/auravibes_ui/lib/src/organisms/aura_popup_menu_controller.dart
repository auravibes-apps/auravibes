import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/atoms/aura_tile.dart' show AuraTileVariant;
import 'package:auravibes_ui/src/molecules/aura_card.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
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
  FocusScopeNode? _menuFocusScopeNode;
  bool _ownsFocusNode = false;
  bool _visible = false;

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
    _menuFocusScopeNode = .new(
      debugLabel: 'AuraPopupMenu menu',
      onKeyEvent: _handleMenuKeyEvent,
    );
    _initializePopupMenuFocus();
    widget.controller._state = this;
  }

  @override
  void dispose() {
    _visible = false;
    widget.controller._state = null;
    if (_ownsFocusNode) {
      _requiredFocusNode.dispose();
    }
    _requiredMenuFocusScopeNode.dispose();
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
    menuFocusScopeNode: _requiredMenuFocusScopeNode,
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
  state
    .._focusNode = focus.node
    .._ownsFocusNode = focus.ownsNode;
}

void _requestMenuFocus(_AuraPopupMenuState state) {
  if (!state.mounted || !state._visible) return;

  state._requiredMenuFocusScopeNode.requestFocus();
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
  new({
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
             child: _AuraPopupMenuSurface(items: items, close: close),
           ),
           behavior: .opaque,
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

class _AuraPopupMenuSurface extends StatelessWidget {
  static const _minWidth = 240;
  static const _maxWidth = 320;

  const new({required this.items, required this.close});

  final List<AuraPopupMenuEntry> items;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: _constraints(context),
    child: IntrinsicWidth(
      child: _AuraPopupMenuCard(items: items, close: close),
    ),
  );

  BoxConstraints _constraints(BuildContext context) {
    final spacing = context.auraTheme.spacing;
    final maxWidth = (MediaQuery.sizeOf(context).width - spacing.md * 2)
        .clamp(0, _maxWidth)
        .toDouble();

    return .new(
      minWidth: maxWidth.clamp(0, _minWidth).toDouble(),
      maxWidth: maxWidth,
    );
  }
}

class _AuraPopupMenuCard extends StatelessWidget {
  const new({required this.items, required this.close});

  final List<AuraPopupMenuEntry> items;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) => AuraCard(
    child: ClipRRect(
      borderRadius: BorderRadius.all(
        .circular(context.auraTheme.fromBorderRadius(.xl)),
      ),
      child: _AuraPopupMenuCardContent(items: items, close: close),
    ),
    padding: .none,
    style: .border,
  );
}

class _AuraPopupMenuCardContent extends StatelessWidget {
  const new({required this.items, required this.close});

  final List<AuraPopupMenuEntry> items;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) => _AuraPopupMenuCloseScope(
    close: close,
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: items.map((entry) => Builder(builder: entry.build)).toList(),
    ),
  );
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
  Widget build(BuildContext context) => _AuraPopupMenuItemButton(item: this);
}

class _AuraPopupMenuItemButton extends StatelessWidget {
  const new({required this.item});

  final AuraPopupMenuItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final interactionColor = _popupMenuItemColor(item.variant, colors);
    final contentColor = item.onTap != null
        ? interactionColor
        : colors.onSurfaceVariant.withValues(alpha: 0.6);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: _AuraPopupMenuPressable(
        item: item,
        interactionColor: interactionColor,
        contentColor: contentColor,
      ),
    );
  }
}

class _AuraPopupMenuPressable extends StatelessWidget {
  const new({
    required this.item,
    required this.interactionColor,
    required this.contentColor,
  });

  final AuraPopupMenuItem item;
  final Color interactionColor;
  final Color contentColor;

  @override
  Widget build(BuildContext context) => AuraPressable(
    child: AuraPadding(
      child: _AuraPopupMenuItemContent(
        title: item.title,
        leading: item.leading,
        trailing: item.trailing,
        color: contentColor,
      ),
      padding: const .symmetric(horizontal: .md, vertical: .sm),
    ),
    color: interactionColor,
    onPressed: _onPressed(context),
    isButtonSemantics: true,
  );

  VoidCallback? _onPressed(BuildContext context) {
    final onTap = item.onTap;
    if (onTap == null) return null;

    return () {
      onTap();
      _AuraPopupMenuCloseScope.maybeOf(context)?.call();
    };
  }
}

class _AuraPopupMenuItemContent extends StatelessWidget {
  const new({
    required this.title,
    required this.leading,
    required this.trailing,
    required this.color,
  });

  final Widget title;
  final Widget? leading;
  final Widget? trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;

    return DefaultTextStyle(
      style: _textStyle(theme.typography),
      child: IconTheme(
        data: .new(color: color),
        child: _AuraPopupMenuItemRow(
          title: title,
          leading: leading,
          trailing: trailing,
          spacing: theme.spacing.sm,
        ),
      ),
    );
  }

  TextStyle _textStyle(AuraTypographyScale typography) => TextStyle(
    color: color,
    fontSize: typography.fontSizeBase,
    fontWeight: typography.fontWeightMedium,
    height: typography.lineHeightBase,
  );
}

class _AuraPopupMenuItemRow extends StatelessWidget {
  const new({
    required this.title,
    required this.leading,
    required this.trailing,
    required this.spacing,
  });

  final Widget title;
  final Widget? leading;
  final Widget? trailing;
  final double spacing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (leading case final value?) ...[value, SizedBox(width: spacing)],
      Expanded(child: title),
      if (trailing case final value?) ...[SizedBox(width: spacing), value],
    ],
  );
}

Color _popupMenuItemColor(AuraTileVariant variant, AuraColorScheme colors) =>
    switch (variant) {
      .error => colors.error,
      .surface => colors.foregroundOnSurface,
      .primary || .ghost || .selected => colors.primary,
    };
