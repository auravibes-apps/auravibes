import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

/// A customizable field hint component following the Aura design system.
///
/// This hint provides helper text and error messages with consistent
/// typography and styling for field descriptions.
class AuraFieldHint extends StatelessWidget {
  /// Creates a Aura field hint.
  const AuraFieldHint({
    super.key,
    this.text,
    this.error,
    this.style,
    this.errorStyle,
    this.semanticLabel,
  });

  /// The hint text to display (shown when there's no error).
  final Widget? text;

  /// The error text to display (takes precedence over hint text).
  final Widget? error;

  /// Optional text style to override the default hint style.
  final AuraTextStyle? style;

  /// Optional text style to override the default error style.
  final AuraTextStyle? errorStyle;

  /// A semantic label for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // final auraColors = context.auraColors;
    final displayText = error ?? text;

    if (displayText == null) return const SizedBox.shrink();

    final isError = error != null;
    final color = isError
        ? AuraColorVariant.error
        : AuraColorVariant.onSurfaceVariant;
    final textStyle = isError
        ? (errorStyle ?? AuraTextStyle.caption)
        : (style ?? AuraTextStyle.caption);

    return AuraText(
      style: textStyle,
      color: color,
      child: Semantics(
        label: semanticLabel,
        child: displayText,
      ),
    );
  }
}
