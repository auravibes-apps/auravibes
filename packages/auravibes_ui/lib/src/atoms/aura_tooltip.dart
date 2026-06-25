import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A custom tooltip widget that follows the Aura design system.
///
/// This tooltip uses Flutter's native tooltip behavior with Aura styling.
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
    this.tint = AuraTint.primary,
    this.showDuration = const Duration(seconds: 2),
    this.waitDuration = Duration.zero,
    this.preferBelow = true,
  });

  /// The text to display in the tooltip.
  final String message;

  /// The widget that triggers the tooltip.
  final Widget child;

  /// The tint for the tooltip background.
  /// Defaults to [AuraTint.primary].
  final AuraTint tint;

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
    final auraColors = context.auraColors;
    final backgroundColor = _getBackgroundColor(auraColors);
    final textColor = _getForegroundColor(auraColors);

    return Tooltip(
      message: message,
      padding: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: 8,
      ),
      preferBelow: preferBelow,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: auraColors.shadow.withValues(alpha: 0.15),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      textStyle: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      waitDuration: waitDuration,
      showDuration: showDuration,
      child: child,
    );
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    return colors.colorFor(tint);
  }

  Color _getForegroundColor(AuraColorScheme colors) => colors.onTint(tint);
}
