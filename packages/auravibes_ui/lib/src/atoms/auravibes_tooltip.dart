import 'dart:async';

import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// Maximum width constraint for the tooltip.
const _kDefaultMaxTooltipWidth = 200.0;

/// Estimated line height for tooltip text calculations.
const _kEstimatedLineHeight = 20.0;

/// Average character width for tooltip width calculations (based on 12px font).
const _kAverageCharWidth = 7.0;

/// Padding/margin buffer for tooltip size calculations.
const _kTooltipSizePadding = 16.0;

/// A custom tooltip widget that follows the Aura design system.
///
/// This tooltip uses [OverlayEntry] instead of Material's [Tooltip] to provide
/// custom styling and behavior while keeping Flutter's gesture handling.
///
/// Tooltips display informative text when users hover over (desktop) or tap
/// (mobile) an element. The tooltip appears near the child widget and
/// auto-dismisses after a configurable duration.
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
    this.verticalOffset = 24,
    this.margin = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
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

  /// The vertical gap between the widget and the displayed tooltip.
  /// Defaults to 24.
  final double verticalOffset;

  /// The amount of space by which to inset the tooltip from the edge
  /// of the screen.
  /// Defaults to 16.
  final double margin;

  /// The amount of padding inside the tooltip.
  /// Defaults to EdgeInsets.symmetric(horizontal: 12, vertical: 8).
  final EdgeInsetsGeometry padding;

  /// The border radius of the tooltip.
  /// Defaults to BorderRadius.all(Radius.circular(8)).
  final BorderRadiusGeometry borderRadius;

  @override
  State<AuraTooltip> createState() => _AuraTooltipState();
}

class _AuraTooltipState extends State<AuraTooltip> {
  OverlayEntry? _overlayEntry;
  Timer? _waitTimer;
  Timer? _showTimer;
  bool _isHovering = false;

  @override
  void dispose() {
    _removeOverlay();
    _waitTimer?.cancel();
    _showTimer?.cancel();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _cancelTimers() {
    _waitTimer?.cancel();
    _showTimer?.cancel();
  }

  void _onHoverChanged(bool isHovering) {
    if (isHovering) {
      _isHovering = true;
      _startWaitTimer();
    } else {
      _isHovering = false;
      _cancelTimers();
      _removeOverlay();
    }
  }

  void _onTap() {
    if (_overlayEntry != null) {
      // Already showing, remove it
      _removeOverlay();
    } else {
      // Show tooltip on tap
      _showTooltip();
    }
  }

  void _startWaitTimer() {
    _cancelTimers();

    if (widget.waitDuration == Duration.zero) {
      _showTooltip();
    } else {
      _waitTimer = Timer(widget.waitDuration, () {
        if (_isHovering) {
          _showTooltip();
        }
      });
    }
  }

  void _showTooltip() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    final renderObject = context.findRenderObject();
    if (renderObject == null || renderObject is! RenderBox) return;
    final renderBox = renderObject;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    // Calculate tooltip position
    final screenSize = MediaQuery.of(context).size;
    final tooltipHeight = _calculateTooltipHeight();
    final tooltipWidth = _calculateTooltipWidth();

    // Determine horizontal position (centered by default)
    var left = position.dx + (size.width - tooltipWidth) / 2;

    // Clamp horizontal position to stay within screen bounds
    left = left.clamp(
      widget.margin,
      screenSize.width - tooltipWidth - widget.margin,
    );

    // Determine vertical position
    double top;
    final isBelowAvailable =
        position.dy + size.height + widget.verticalOffset + tooltipHeight <
        screenSize.height - widget.margin;
    final isAboveAvailable =
        position.dy - widget.verticalOffset - tooltipHeight > widget.margin;

    if (widget.preferBelow) {
      if (isBelowAvailable || !isAboveAvailable) {
        top = position.dy + size.height + widget.verticalOffset;
      } else {
        top = position.dy - widget.verticalOffset - tooltipHeight;
      }
    } else {
      if (isAboveAvailable || !isBelowAvailable) {
        top = position.dy - widget.verticalOffset - tooltipHeight;
      } else {
        top = position.dy + size.height + widget.verticalOffset;
      }
    }

    // Clamp vertical position
    top = top.clamp(
      widget.margin,
      screenSize.height - tooltipHeight - widget.margin,
    );

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        child: _buildTooltipWidget(),
      ),
    );

    overlay.insert(_overlayEntry!);

    // Set up auto-dismiss timer
    _showTimer = Timer(widget.showDuration, _removeOverlay);
  }

  double _calculateTooltipHeight() {
    // Estimate tooltip height based on text and padding
    // This is a rough estimate since we can't measure without rendering
    final resolvedPadding = widget.padding.resolve(TextDirection.ltr);
    return _kEstimatedLineHeight +
        resolvedPadding.vertical +
        _kTooltipSizePadding; // padding + margins
  }

  double _calculateTooltipWidth() {
    // Estimate based on message length (rough approximation)
    // A more accurate solution would measure after first render
    final resolvedPadding = widget.padding.resolve(TextDirection.ltr);
    return widget.message.length * _kAverageCharWidth +
        resolvedPadding.horizontal +
        _kTooltipSizePadding;
  }

  Widget _buildTooltipWidget() {
    final auraColors = context.auraColors;
    final backgroundColor = _getBackgroundColor(auraColors);
    final textColor = _getForegroundColor(auraColors);

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: _kDefaultMaxTooltipWidth),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: widget.padding,
        child: Text(
          widget.message,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  /// Gets the background color based on the color variant.
  Color _getBackgroundColor(AuraColorScheme colors) {
    return switch (widget.colorVariant) {
      AuraColorVariant.primary => colors.primary,
      AuraColorVariant.secondary => colors.secondary,
      AuraColorVariant.success => colors.success,
      AuraColorVariant.error => colors.error,
      AuraColorVariant.warning => colors.warning,
      AuraColorVariant.info => colors.info,
      AuraColorVariant.surfaceVariant => colors.surfaceVariant,
      AuraColorVariant.onSurface => colors.surface,
      AuraColorVariant.onSurfaceVariant => colors.surfaceVariant,
      AuraColorVariant.onPrimary => colors.primary,
    };
  }

  /// Gets the foreground text color based on the color variant.
  Color _getForegroundColor(AuraColorScheme colors) {
    return switch (widget.colorVariant) {
      AuraColorVariant.primary => colors.onPrimary,
      AuraColorVariant.secondary => colors.onSecondary,
      AuraColorVariant.success => colors.onSuccess,
      AuraColorVariant.error => colors.onError,
      AuraColorVariant.warning => colors.onWarning,
      AuraColorVariant.info => colors.onInfo,
      AuraColorVariant.surfaceVariant => colors.onSurface,
      AuraColorVariant.onSurface => colors.onSurface,
      AuraColorVariant.onSurfaceVariant => colors.onSurfaceVariant,
      AuraColorVariant.onPrimary => colors.onPrimary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: widget.child,
      ),
    );
  }
}
