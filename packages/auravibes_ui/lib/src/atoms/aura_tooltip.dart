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
  static const _verticalPadding = 4.0;
  static const _horizontalPadding = 8.0;
  static const _cornerRadius = 8.0;
  static const _shadowOffset = 2.0;
  static const _shadowAlpha = 0.15;
  static const _fontSize = 12.0;

  /// Creates an Aura tooltip.
  const new({
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

  EdgeInsets get _padding => const EdgeInsets.symmetric(
    vertical: _verticalPadding,
    horizontal: _horizontalPadding,
  );

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return Tooltip(
      message: message,
      padding: _padding,
      preferBelow: preferBelow,
      decoration: _decoration(auraColors),
      textStyle: _textStyle(auraColors),
      waitDuration: waitDuration,
      showDuration: showDuration,
      child: child,
    );
  }

  BoxDecoration _decoration(AuraColorScheme colors) => BoxDecoration(
    color: colors.colorFor(tint),
    borderRadius: const BorderRadius.all(.circular(_cornerRadius)),
    boxShadow: [_shadow(colors)],
  );

  BoxShadow _shadow(AuraColorScheme colors) => BoxShadow(
    color: colors.shadow.withValues(alpha: _shadowAlpha),
    offset: const Offset(0, _shadowOffset),
    blurRadius: _cornerRadius,
  );

  TextStyle _textStyle(AuraColorScheme colors) => .new(
    color: colors.onTint(tint),
    fontSize: _fontSize,
    fontWeight: FontWeight.w500,
  );
}
