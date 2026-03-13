import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A custom tooltip widget that follows the Aura design system.
///
/// This tooltip wraps Material's Tooltip with Aura styling.
/// It shows informative text when users hover over (desktop) or tap (mobile)
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
class AuraTooltip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final backgroundColor = _getBackgroundColor(colors);
    final textColor = _getForegroundColor(colors);

    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      waitDuration: waitDuration,
      showDuration: showDuration,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textStyle: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      child: child,
    );
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    return switch (colorVariant) {
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

  Color _getForegroundColor(AuraColorScheme colors) {
    return switch (colorVariant) {
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
}
