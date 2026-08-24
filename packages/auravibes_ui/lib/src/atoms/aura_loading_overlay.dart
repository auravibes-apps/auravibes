import 'package:auravibes_ui/src/atoms/aura_spinner.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A specialized full-screen loading overlay component.
class AuraLoadingOverlay extends StatelessWidget {
  /// Creates an Aura loading overlay.
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

    if (!isLoading) return child ?? const SizedBox.shrink();

    final auraColors = context.auraColors;
    final auraTheme = context.auraTheme;
    final typography = auraTheme.typography;
    final message = this.message;
    final overlay = ColoredBox(
      color: backgroundColor ?? auraColors.scrim,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(auraTheme.fromSpacing(.xl)),
          decoration: BoxDecoration(
            color: auraColors.surface,
            borderRadius: BorderRadius.all(
              Radius.circular(auraTheme.fromBorderRadius(.lg)),
            ),
            boxShadow: const [DesignShadows.lg],
          ),
          child: message != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuraSpinner(size: spinnerSize, color: spinnerColor),
                    SizedBox(height: auraTheme.fromSpacing(.md)),
                    Text(
                      message,
                      style: TextStyle(
                        color: auraColors.onSurfaceVariant,
                        fontSize: typography.fontSizeLg,
                        fontWeight: typography.fontWeightRegular,
                        fontFamily: typography.bodyFontFamily,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : AuraSpinner(size: spinnerSize, color: spinnerColor),
        ),
      ),
    );

    if (child == null) return overlay;

    return Stack(
      children: [
        child,
        overlay,
      ],
    );
  }
}
