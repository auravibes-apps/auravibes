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
  Widget build(BuildContext context) => _AuraLoadingOverlayFrame.fromView(
    view: this,
    theme: context.auraTheme,
    colors: context.auraColors,
  );
}

class _AuraLoadingOverlayFrame extends StatelessWidget {
  new fromView({
    required _AuraLoadingOverlayView view,
    required AuraTheme theme,
    required AuraColorScheme colors,
  }) : _child = _AuraLoadingOverlayStack(
         child: view.child,
         overlay: _AuraLoadingOverlayLayer(
           message: view.message,
           backgroundColor: view.backgroundColor,
           spinnerSize: view.spinnerSize,
           spinnerTint: view.spinnerTint,
           spinnerColor: view.spinnerColor,
           semanticLabel: view.semanticLabel,
           theme: theme,
           colors: colors,
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraLoadingOverlayStack({
  required final Widget? child,
  required final Widget overlay,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final child = this.child;
    if (child == null) return overlay;

    return Stack(children: [child, overlay]);
  }
}

class _AuraLoadingOverlayLayer extends StatelessWidget {
  new({
    required String? message,
    required Color? backgroundColor,
    required AuraSpinnerSize spinnerSize,
    required AuraTint? spinnerTint,
    required Color? spinnerColor,
    required String? semanticLabel,
    required AuraTheme theme,
    required AuraColorScheme colors,
  }) : _child = Semantics(
         child: ColoredBox(
           color: backgroundColor ?? colors.scrim,
           child: Center(
             child: _AuraLoadingPanel(
               message: message,
               spinnerSize: spinnerSize,
               spinnerTint: spinnerTint,
               spinnerColor: spinnerColor,
               theme: theme,
               colors: colors,
             ),
           ),
         ),
         container: true,
         liveRegion: true,
         label: semanticLabel ?? message ?? 'Loading',
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AuraLoadingPanel extends StatelessWidget {
  new({
    required String? message,
    required AuraSpinnerSize spinnerSize,
    required AuraTint? spinnerTint,
    required Color? spinnerColor,
    required AuraTheme theme,
    required AuraColorScheme colors,
  }) : _child = Container(
         padding: EdgeInsets.all(theme.fromSpacing(.xl)),
         decoration: _loadingPanelDecoration(colors, theme),
         child: _AuraLoadingPanelContent(
           message: message,
           spinnerSize: spinnerSize,
           spinnerTint: spinnerTint,
           spinnerColor: spinnerColor,
           theme: theme,
           colors: colors,
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AuraLoadingPanelContent extends StatelessWidget {
  new({
    required String? message,
    required AuraSpinnerSize spinnerSize,
    required AuraTint? spinnerTint,
    required Color? spinnerColor,
    required AuraTheme theme,
    required AuraColorScheme colors,
  }) : _child = message == null
           ? AuraSpinner(
               size: spinnerSize,
               tint: spinnerTint,
               color: spinnerColor,
             )
           : _AuraLoadingMessage(
               message: message,
               spinnerSize: spinnerSize,
               spinnerTint: spinnerTint,
               spinnerColor: spinnerColor,
               theme: theme,
               colors: colors,
             );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AuraLoadingMessage extends StatelessWidget {
  new({
    required String message,
    required AuraSpinnerSize spinnerSize,
    required AuraTint? spinnerTint,
    required Color? spinnerColor,
    required AuraTheme theme,
    required AuraColorScheme colors,
  }) : _child = _AuraLoadingMessageBody(
         message: message,
         spinnerSize: spinnerSize,
         spinnerTint: spinnerTint,
         spinnerColor: spinnerColor,
         theme: theme,
         colors: colors,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AuraLoadingMessageBody extends StatelessWidget {
  new({
    required String message,
    required AuraSpinnerSize spinnerSize,
    required AuraTint? spinnerTint,
    required Color? spinnerColor,
    required AuraTheme theme,
    required AuraColorScheme colors,
  }) : _child = Column(
         mainAxisAlignment: .center,
         mainAxisSize: .min,
         children: [
           AuraSpinner(
             size: spinnerSize,
             tint: spinnerTint,
             color: spinnerColor,
           ),
           SizedBox(height: theme.fromSpacing(.md)),
           _AuraLoadingMessageText(
             message: message,
             color: colors.onSurfaceVariant,
             typography: theme.typography,
           ),
         ],
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
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
