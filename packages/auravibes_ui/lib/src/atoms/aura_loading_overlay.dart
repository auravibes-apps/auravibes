import 'package:auravibes_ui/src/atoms/aura_spinner.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A specialized full-screen loading overlay component.
class AuraLoadingOverlay extends StatelessWidget {
  /// Creates an Aura loading overlay.
  const new({
    super.key,
    this.isLoading = true,
    this.child,
    this.message,
    this.backgroundColor,
    this.spinnerSize = AuraSpinnerSize.large,
    this.spinnerTint,
    this.spinnerColor,
    this.semanticLabel,
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

  /// The tint of the spinner.
  final AuraTint? spinnerTint;

  /// The tint of the loading spinner.
  final Color? spinnerColor;

  /// A semantic label announced while loading.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final child = this.child;

    if (!isLoading) return child ?? const SizedBox.shrink();

    return _AuraLoadingOverlayView(
      child: child,
      message: message,
      backgroundColor: backgroundColor,
      spinnerSize: spinnerSize,
      spinnerTint: spinnerTint,
      spinnerColor: spinnerColor,
      semanticLabel: semanticLabel,
    );
  }
}

class const _AuraLoadingOverlayView({
  required final Widget? child,
  required final String? message,
  required final Color? backgroundColor,
  required final AuraSpinnerSize spinnerSize,
  required final AuraTint? spinnerTint,
  required final Color? spinnerColor,
  required final String? semanticLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final overlay = _AuraLoadingOverlayLayer(
      message: message,
      backgroundColor: backgroundColor,
      spinnerSize: spinnerSize,
      spinnerTint: spinnerTint,
      spinnerColor: spinnerColor,
      semanticLabel: semanticLabel,
    );
    final child = this.child;

    return child == null ? overlay : Stack(children: [child, overlay]);
  }
}

class const _AuraLoadingOverlayLayer({
  required final String? message,
  required final Color? backgroundColor,
  required final AuraSpinnerSize spinnerSize,
  required final AuraTint? spinnerTint,
  required final Color? spinnerColor,
  required final String? semanticLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;

    return Semantics(
      child: ColoredBox(
        color: backgroundColor ?? colors.scrim,
        child: Center(
          child: _AuraLoadingPanel(
            message: message,
            spinnerSize: spinnerSize,
            spinnerTint: spinnerTint,
            spinnerColor: spinnerColor,
          ),
        ),
      ),
      container: true,
      liveRegion: true,
      label: semanticLabel ?? message ?? 'Loading',
    );
  }
}

class const _AuraLoadingPanel({
  required final String? message,
  required final AuraSpinnerSize spinnerSize,
  required final AuraTint? spinnerTint,
  required final Color? spinnerColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    final colors = context.auraColors;

    return Container(
      padding: EdgeInsets.all(theme.fromSpacing(.xl)),
      decoration: _loadingPanelDecoration(colors, theme),
      child: _AuraLoadingPanelContent(
        message: message,
        spinnerSize: spinnerSize,
        spinnerTint: spinnerTint,
        spinnerColor: spinnerColor,
      ),
    );
  }
}

class const _AuraLoadingPanelContent({
  required final String? message,
  required final AuraSpinnerSize spinnerSize,
  required final AuraTint? spinnerTint,
  required final Color? spinnerColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final message = this.message;
    if (message == null) {
      return AuraSpinner(
        size: spinnerSize,
        tint: spinnerTint,
        color: spinnerColor,
      );
    }

    return _AuraLoadingMessage(
      message: message,
      spinnerSize: spinnerSize,
      spinnerTint: spinnerTint,
      spinnerColor: spinnerColor,
    );
  }
}

class const _AuraLoadingMessage({
  required final String message,
  required final AuraSpinnerSize spinnerSize,
  required final AuraTint? spinnerTint,
  required final Color? spinnerColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraLoadingMessageBody(
    message: message,
    spinnerSize: spinnerSize,
    spinnerTint: spinnerTint,
    spinnerColor: spinnerColor,
    theme: context.auraTheme,
    colors: context.auraColors,
  );
}

class const _AuraLoadingMessageBody({
  required final String message,
  required final AuraSpinnerSize spinnerSize,
  required final AuraTint? spinnerTint,
  required final Color? spinnerColor,
  required final AuraTheme theme,
  required final AuraColorScheme colors,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final typography = theme.typography;

    return Column(
      mainAxisAlignment: .center,
      mainAxisSize: .min,
      children: [
        AuraSpinner(size: spinnerSize, tint: spinnerTint, color: spinnerColor),
        SizedBox(height: theme.fromSpacing(.md)),
        _AuraLoadingMessageText(
          message: message,
          color: colors.onSurfaceVariant,
          typography: typography,
        ),
      ],
    );
  }
}

BoxDecoration _loadingPanelDecoration(
  AuraColorScheme colors,
  AuraTheme theme,
) => BoxDecoration(
  color: colors.surface,
  borderRadius: BorderRadius.all(.circular(theme.fromBorderRadius(.lg))),
  boxShadow: const [DesignShadows.lg],
);

class const _AuraLoadingMessageText({
  required final String message,
  required final Color color,
  required final AuraTypographyScale typography,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    message,
    style: _loadingMessageTextStyle(color, typography),
    textAlign: .center,
  );
}

TextStyle _loadingMessageTextStyle(
  Color color,
  AuraTypographyScale typography,
) => TextStyle(
  color: color,
  fontSize: typography.fontSizeLg,
  fontWeight: typography.fontWeightRegular,
  fontFamily: typography.bodyFontFamily,
);
