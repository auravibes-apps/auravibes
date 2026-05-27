// ignore_for_file: no-magic-number
// Required: UI tokens and layout use fixed design values.
// ignore_for_file: avoid-non-null-assertion
// Required: Existing nullable API contracts still use explicit assertions.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';

import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A custom tooltip widget that follows the Aura design system.
///
/// This tooltip uses a custom OverlayEntry-based implementation with Aura
/// styling. It shows informative text when users hover over (desktop) or
/// long-press (mobile) the wrapped widget.
///
/// Example:
/// ```dart
/// AuraTooltip(
///   message: 'This is a helpful tip',
///   child: IconButton(
///     icon: Icon(Icons.info),
///     onPressed: () {},
///   ),
/// )
/// ```
class AuraTooltip extends StatefulWidget {
  /// Creates an Aura tooltip.
  const AuraTooltip({
    required this.message,
    required this.child,
    super.key,
    this.colorVariant = AuraColorVariant.onSurface,
    this.showDuration = const Duration(seconds: 2),
    this.waitDuration = Duration.zero,
    this.preferBelow = true,
  });

  /// The text to display in the tooltip.
  final String message;

  /// The widget that triggers the tooltip.
  final Widget child;

  /// The color variant for the tooltip background.
  /// Defaults to [AuraColorVariant.onSurface].
  final AuraColorVariant colorVariant;

  /// The length of time that the tooltip is shown.
  /// Defaults to 2 seconds.
  final Duration showDuration;

  /// The length of time that a pointer must hover over the tooltip's
  /// widget before the tooltip will be shown.
  /// Defaults to [Duration.zero] (immediate).
  final Duration waitDuration;

  /// Whether the tooltip is displayed below the widget by default.
  /// Defaults to true.
  final bool preferBelow;

  @override
  State<AuraTooltip> createState() => _AuraTooltipState();
}

class _AuraTooltipState extends State<AuraTooltip> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _showTimer;
  Timer? _hideTimer;

  bool get _isVisible => _overlayEntry != null;

  @override
  void dispose() {
    _cancelTimers();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _handlePointerEnter,
      onExit: _handlePointerExit,
      child: GestureDetector(
        child: CompositedTransformTarget(
          link: _layerLink,
          child: widget.child,
        ),
        onLongPress: _handleLongPress,
        behavior: HitTestBehavior.translucent,
      ),
    );
  }

  void _handlePointerEnter(PointerEnterEvent _) {
    _cancelTimers();
    if (widget.waitDuration > Duration.zero) {
      _showTimer = Timer(widget.waitDuration, _showTooltip);
    } else {
      _showTooltip();
    }
  }

  void _handlePointerExit(PointerExitEvent _) {
    _cancelTimers();
    _removeOverlay();
  }

  void _handleLongPress() {
    // On tap, show immediately and auto-hide after [showDuration].
    _cancelTimers();
    if (_isVisible) {
      _removeOverlay();
      return;
    }
    _showTooltip();
  }

  void _showTooltip() {
    if (!mounted || _isVisible) return;

    final auraColors = context.auraColors;
    final backgroundColor = _getBackgroundColor(auraColors);
    final textColor = _getForegroundColor(auraColors);

    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: IgnorePointer(
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: widget.preferBelow
                  ? const Offset(0, 8)
                  : const Offset(0, -8),
              child: Material(
                color: Colors.transparent,
                child: Align(
                  alignment: widget.preferBelow
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);

    if (widget.showDuration > Duration.zero) {
      _hideTimer = Timer(widget.showDuration, _removeOverlay);
    }
  }

  void _removeOverlay() {
    _hideTimer?.cancel();
    _hideTimer = null;

    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _cancelTimers() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _showTimer = null;
    _hideTimer = null;
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    return colors.getColor(widget.colorVariant);
  }

  Color _getForegroundColor(AuraColorScheme colors) {
    // Use the corresponding "on" color for contrast.
    // For surface variants, use onSurface for readable text.
    return switch (widget.colorVariant) {
      AuraColorVariant.primary => colors.onPrimary,
      AuraColorVariant.secondary => colors.onSecondary,
      AuraColorVariant.success => colors.onSuccess,
      AuraColorVariant.error => colors.onError,
      AuraColorVariant.warning => colors.onWarning,
      AuraColorVariant.info => colors.onInfo,
      AuraColorVariant.surfaceVariant => colors.onSurface,
      AuraColorVariant.onSurface => colors.surface,
      AuraColorVariant.onSurfaceVariant => colors.surface,
      AuraColorVariant.onPrimary => colors.onPrimary,
    };
  }
}
