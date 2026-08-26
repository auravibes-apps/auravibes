import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';

export 'aura_loading_overlay.dart';

/// A customizable loading spinner component following the Aura design system.
class AuraSpinner extends StatelessWidget {
  /// Creates an Aura spinner.
  const AuraSpinner({
    super.key,
    this.size = AuraSpinnerSize.medium,
    this.color,
    this.strokeWidth,
    this.semanticLabel,
  });

  /// The size of the spinner.
  final AuraSpinnerSize size;

  /// The color of the spinner. If null, uses the primary color.
  final Color? color;

  /// The width of the spinner stroke. If null, uses a default based on size.
  final double? strokeWidth;

  /// A semantic label for the spinner for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final spinnerColor = color ?? auraColors.primary;

    return SizedBox(
      width: _getSpinnerSize(),
      height: _getSpinnerSize(),
      child: CircularProgressIndicator(
        color: spinnerColor,
        strokeWidth: strokeWidth ?? _getDefaultStrokeWidth(),
        semanticsLabel: semanticLabel,
      ),
    );
  }

  double _getSpinnerSize() {
    return switch (size) {
      AuraSpinnerSize.extraSmall => 12.0,
      AuraSpinnerSize.small => 16.0,
      AuraSpinnerSize.medium => 24.0,
      AuraSpinnerSize.large => 32.0,
      AuraSpinnerSize.extraLarge => 48.0,
    };
  }

  double _getDefaultStrokeWidth() {
    return switch (size) {
      AuraSpinnerSize.extraSmall => 1.5,
      AuraSpinnerSize.small => 2.0,
      AuraSpinnerSize.medium => 2.5,
      AuraSpinnerSize.large => 3.0,
      AuraSpinnerSize.extraLarge => 4.0,
    };
  }
}

/// The size of a [AuraSpinner].
enum AuraSpinnerSize {
  /// Extra small spinner (12px).
  extraSmall,

  /// Small spinner (16px).
  small,

  /// Medium spinner (24px) - default.
  medium,

  /// Large spinner (32px).
  large,

  /// Extra large spinner (48px).
  extraLarge,
}
