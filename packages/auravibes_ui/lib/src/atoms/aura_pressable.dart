// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-extracting-callbacks
// Required: Component callbacks stay colocated with UI state.
import 'dart:async';

import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';

/// Pessable implementation of auravibes
class AuraPressable extends StatefulWidget {
  /// constructor
  const AuraPressable({
    required this.child,
    required this.color,
    super.key,
    this.decoration,
    this.onPressed,
    this.onLongPress,
    this.clipBehavior = Clip.hardEdge,
    this.padding,
  });

  /// child
  final Widget child;

  /// color
  final Color color;

  /// decoration
  final Decoration? decoration;

  /// onPressed
  final void Function()? onPressed;

  /// onLongPress
  final void Function()? onLongPress;

  /// clipBehavior
  final Clip? clipBehavior;

  /// Optional padding to apply around the pressable widget.
  final AuraEdgeInsetsGeometry? padding;

  @override
  AuraPressableState createState() => AuraPressableState();
}

/// AuraPressableState
class AuraPressableState extends State<AuraPressable> {
  // Our state
  bool _hovering = false;
  final bool _pressed = false;
  bool _pressDown = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onPressed() {
    setState(() => _pressDown = true);
  }

  void _onExitPressed() {
    setState(() => _pressDown = false);
  }

  void _onHover() {
    setState(() => _hovering = true);
  }

  void _onExitHover() {
    setState(() => _hovering = false);
  }

  @override
  Widget build(BuildContext context) {
    final auraTheme = context.auraTheme;
    final selectedColor = widget.color;
    final canChangeColor = (widget.onPressed != null);
    final pressed = (_pressDown || _pressed) && canChangeColor;
    final hovered = _hovering && canChangeColor;

    final alphaHover = selectedColor.a / 2;
    final alphaNorPressed = hovered ? alphaHover : 0.0;

    final alpha = pressed ? (selectedColor.a) : alphaNorPressed;
    if (widget.onPressed == null) {
      return Container(
        decoration: widget.decoration,
        child: widget.child,
        clipBehavior: widget.decoration == null
            ? Clip.none
            : widget.clipBehavior ?? Clip.none,
      );
    }

    return GestureDetector(
      child: AuraPadding(
        child: Container(
          decoration: widget.decoration,
          child: AnimatedContainer(
            color: selectedColor.withValues(alpha: alpha),
            child: MouseRegion(
              onEnter: (details) => _onHover(),
              onExit: (details) => _onExitHover(),
              cursor: canChangeColor
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: Listener(child: widget.child),
            ),
            duration: auraTheme.animation.normal,
          ),
          clipBehavior: widget.decoration == null
              ? Clip.none
              : widget.clipBehavior ?? Clip.none,
        ),
        padding: widget.padding ?? .none,
      ),
      onTapDown: (_) => _onPressed(),
      onTapUp: (_) {
        _timer?.cancel();
        _timer = Timer(auraTheme.animation.normal, _onExitPressed);
      },
      onTap: widget.onPressed,
      onTapCancel: _onExitPressed,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.translucent,
    );
  }
}
