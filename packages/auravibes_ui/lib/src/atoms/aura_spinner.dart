// Required: UI components keep related private widgets together.

import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable loading spinner component following the Aura design system.
///
/// This spinner widget provides consistent loading indicators with different
/// sizes and styles across the application.
class AuraSpinner extends StatelessWidget {
  /// Creates a Aura spinner.
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
    final spinnerSize = _getSpinnerSize();
    final spinnerColor = color ?? auraColors.primary;
    final spinnerStrokeWidth = strokeWidth ?? _getDefaultStrokeWidth();

    return SizedBox(
      width: spinnerSize,
      height: spinnerSize,
      child: CircularProgressIndicator(
        color: spinnerColor,
        strokeWidth: spinnerStrokeWidth,
        semanticsLabel: semanticLabel ?? 'Loading',
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

/// A specialized full-screen loading overlay component.
///
/// This provides a consistent way to show loading states that cover the entire
/// screen.
class AuraLoadingOverlay extends StatelessWidget {
  /// Creates a Aura loading overlay.
  const AuraLoadingOverlay({
    super.key,
    this.isLoading = true,
    this.child,
    this.message,
    this.backgroundColor,
    this.spinnerSize = AuraSpinnerSize.large,
    this.spinnerColor,
  });

  /// Whether the loading overlay is visible.
  final bool isLoading;

  /// The widget to display behind the loading overlay.
  final Widget? child;

  /// Optional message to display with the spinner.
  final String? message;

  /// The background color of the overlay.
  final Color? backgroundColor;

  /// The size of the loading spinner.
  final AuraSpinnerSize spinnerSize;

  /// The color of the loading spinner.
  final Color? spinnerColor;

  @override
  Widget build(BuildContext context) {
    final child = this.child;

    if (!isLoading) {
      return child ?? const SizedBox.shrink();
    }

    final auraColors = context.auraColors;
    final message = this.message;
    final overlay = ColoredBox(
      color: backgroundColor ?? auraColors.scrim,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(DesignSpacing.xl),
          decoration: BoxDecoration(
            color: auraColors.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(DesignBorderRadius.lg),
            ),
            boxShadow: const [DesignShadows.lg],
          ),
          child: message != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuraSpinner(
                      size: spinnerSize,
                      color: spinnerColor,
                    ),
                    const SizedBox(height: DesignSpacing.md),
                    Text(
                      message,
                      style: TextStyle(
                        color: auraColors.onSurfaceVariant,
                        fontSize: DesignTypography.fontSizeLg,
                        fontWeight: DesignTypography.fontWeightRegular,
                        fontFamily: DesignTypography.bodyFontFamily,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : AuraSpinner(
                  size: spinnerSize,
                  color: spinnerColor,
                ),
        ),
      ),
    );

    if (child != null) {
      return Stack(
        children: [
          child,
          if (isLoading) overlay,
        ],
      );
    }

    return overlay;
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
