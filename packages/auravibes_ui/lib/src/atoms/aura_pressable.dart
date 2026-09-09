// ignore_for_file: type=lint, type=warning
import 'dart:async';

import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/widgets.dart';

/// A reusable Aura pressable surface with pointer and keyboard feedback.
class AuraPressable extends StatefulWidget {
  /// Constructor.
  const new({
    required this.child,
    required this.color,
    super.key,
    this.decoration,
    this.onPressed,
    this.onLongPress,
    this.onFocusChange,
    this.interaction = AuraPressableInteraction.action,
    this.clipBehavior = Clip.hardEdge,
    this.padding,
    this.semanticLabel,
    this.isButtonSemantics = false,
  });

  /// Child.
  final Widget child;

  /// Base color for the hover and pressed state layers.
  ///
  /// The alpha channel is ignored. Aura applies an 8% hover/focus layer and
  /// a 16% pressed layer so callers can pass a resolved theme color.
  final Color color;

  /// Decoration.
  final Decoration? decoration;

  /// OnPressed.
  final void Function()? onPressed;

  /// OnLongPress.
  final void Function()? onLongPress;

  /// Called when keyboard focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Defines whether the pressable is a command or local navigation control.
  final AuraPressableInteraction interaction;

  /// ClipBehavior.
  final Clip? clipBehavior;

  /// Optional padding to apply around the pressable widget.
  final AuraEdgeInsetsGeometry? padding;

  /// A semantic label announced by assistive technologies.
  final String? semanticLabel;

  /// Preserves button semantics when the owning control is disabled.
  final bool isButtonSemantics;

  @override
  AuraPressableState createState() => AuraPressableState();
}

/// AuraPressableState.
class AuraPressableState extends State<AuraPressable> {
  static const _hoverAlpha = 0.08;
  static const _pressedAlpha = 0.16;
  // Our state.
  bool _hovering = false;
  bool _focused = false;
  bool _pressDown = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auraTheme = context.auraTheme;
    final auraColors = context.auraColors;
    final policy = AuraInteractionScope.of(context);
    final isAllowed = switch (widget.interaction) {
      AuraPressableInteraction.action => policy.allowsActions,
      AuraPressableInteraction.localNavigation => policy.allowsNavigation,
    };
    final onPressed = isAllowed ? widget.onPressed : null;
    final onLongPress = isAllowed ? widget.onLongPress : null;
    if (onPressed == null) {
      return _buildDisabled(policy);
    }

    final alpha = _stateLayerAlpha(_pressDown, _hovering || _focused);
    return _buildEnabled(auraTheme, auraColors, alpha, onPressed, onLongPress);
  }

  Widget _buildDisabled(AuraInteractionPolicy policy) {
    final content = Container(
      decoration: widget.decoration,
      child: widget.child,
      clipBehavior: _clipBehavior,
    );

    if (!widget.isButtonSemantics &&
        policy.mode == AuraInteractionMode.interactive &&
        widget.semanticLabel == null) {
      return content;
    }

    return Semantics(
      label: widget.semanticLabel,
      button: widget.isButtonSemantics || widget.semanticLabel != null,
      enabled: false,
      child: content,
    );
  }

  Widget _buildEnabled(
    AuraTheme auraTheme,
    AuraColorScheme auraColors,
    double alpha,
    void Function() onPressed,
    void Function()? onLongPress,
  ) {
    return Semantics(
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onPressed.call();

              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) => setState(() => _hovering = value),
        onFocusChange: _onFocusChange,
        mouseCursor: SystemMouseCursors.click,
        child: CustomPaint(
          foregroundPainter: _focused
              ? _AuraPressableFocusRingPainter(
                  color: auraColors.primary,
                  decoration: widget.decoration,
                )
              : null,
          child: GestureDetector(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: AuraPadding(
                child: Container(
                  decoration: widget.decoration,
                  child: AnimatedContainer(
                    color: widget.color.withValues(alpha: alpha),
                    child: widget.child,
                    duration: auraTheme.animation.normal,
                  ),
                  clipBehavior: _clipBehavior,
                ),
                padding: widget.padding ?? .none,
              ),
            ),
            onTapDown: (_) => _onPressed(),
            onTapUp: (_) {
              _timer?.cancel();
              _timer = Timer(auraTheme.animation.normal, _onExitPressed);
            },
            onTap: onPressed,
            onTapCancel: _onExitPressed,
            onLongPress: onLongPress,
            behavior: HitTestBehavior.translucent,
            excludeFromSemantics: true,
          ),
        ),
      ),
      enabled: true,
      button: true,
      label: widget.semanticLabel,
      onTap: onPressed,
    );
  }

  Clip get _clipBehavior =>
      widget.decoration == null ? Clip.none : widget.clipBehavior ?? Clip.none;

  double _stateLayerAlpha(bool pressed, bool highlighted) {
    if (pressed) return _pressedAlpha;
    if (highlighted) return _hoverAlpha;
    return 0;
  }

  void _onPressed() {
    setState(() => _pressDown = true);
  }

  void _onExitPressed() {
    setState(() => _pressDown = false);
  }

  void _onFocusChange(bool value) {
    widget.onFocusChange?.call(value);
  }
}

/// Interaction category used by [AuraPressable].
enum AuraPressableInteraction {
  /// A command that changes state or triggers an external action.
  action,

  /// Local navigation that can remain usable in read-only mode.
  localNavigation,
}

class const _AuraPressableFocusRingPainter({
  required final Color color,
  required final Decoration? decoration,
}) extends CustomPainter {
  double get _borderRadius {
    final decoration = this.decoration;
    if (decoration is! BoxDecoration) return 0;

    final borderRadius = decoration.borderRadius;
    if (borderRadius is! BorderRadius) return 0;

    return borderRadius.topLeft.x;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final radius = _borderRadius + 4;
    final rect = Offset.zero & size;
    final ringRect = rect.inflate(3);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(ringRect, Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_AuraPressableFocusRingPainter oldDelegate) {
    return color != oldDelegate.color || decoration != oldDelegate.decoration;
  }
}
