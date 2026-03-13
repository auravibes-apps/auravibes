import 'package:auravibes_ui/src/atoms/auravibes_icon.dart';
import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable floating action button component following the Aura design
/// system.
///
/// This FAB supports different sizes, icons, extended variants with text,
/// and proper elevation and shadows.
class AuraFloatingActionButton extends StatelessWidget {
  /// Creates a Aura floating action button.
  const AuraFloatingActionButton({
    required this.onPressed,
    required this.icon,
    super.key,
    this.size = AuraFABSize.regular,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
    this.tooltip,
  }) : text = null;

  /// Creates an extended Aura floating action button with text.
  const AuraFloatingActionButton.extended({
    required this.onPressed,
    required this.icon,
    required this.text,
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
    this.tooltip,
  }) : size = AuraFABSize.extended;

  /// The callback that is called when the button is pressed.
  final VoidCallback? onPressed;

  /// The icon to display.
  final IconData icon;

  /// The text to display (only for extended variant).
  final String? text;

  /// The size of the FAB.
  final AuraFABSize size;

  /// The background color variant of the FAB. If null, uses the primary color.
  final AuraColorVariant? backgroundColor;

  /// The foreground color variant of the FAB.
  /// If null, uses the primary contrast color.
  final AuraColorVariant? foregroundColor;

  /// A semantic label for the FAB for accessibility.
  final String? semanticLabel;

  /// The tooltip message to display when the FAB is long-pressed.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final isExtended = size == AuraFABSize.extended;

    Widget fab = FloatingActionButton(
      onPressed: onPressed,
      backgroundColor:
          auraColors.getColorOrNull(backgroundColor) ?? auraColors.primary,
      foregroundColor:
          auraColors.getColorOrNull(foregroundColor) ?? auraColors.onPrimary,
      elevation: _getElevation(),
      focusElevation: _getFocusElevation(),
      hoverElevation: _getHoverElevation(),
      highlightElevation: _getHighlightElevation(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      child: isExtended
          ? _buildExtendedContent(auraColors)
          : _buildRegularContent(auraColors),
    );

    // Override size for mini and large variants
    if (size == AuraFABSize.mini || size == AuraFABSize.large) {
      fab = SizedBox(
        width: _getFABSize(),
        height: _getFABSize(),
        child: FloatingActionButton(
          onPressed: onPressed,
          backgroundColor:
              auraColors.getColorOrNull(backgroundColor) ?? auraColors.primary,
          foregroundColor:
              auraColors.getColorOrNull(foregroundColor) ??
              auraColors.onPrimary,
          elevation: _getElevation(),
          focusElevation: _getFocusElevation(),
          hoverElevation: _getHoverElevation(),
          highlightElevation: _getHighlightElevation(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          child: _buildRegularContent(auraColors),
        ),
      );
    }

    if (isExtended) {
      fab = FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor:
            auraColors.getColorOrNull(backgroundColor) ?? auraColors.primary,
        foregroundColor:
            auraColors.getColorOrNull(foregroundColor) ?? auraColors.onPrimary,
        elevation: _getElevation(),
        focusElevation: _getFocusElevation(),
        hoverElevation: _getHoverElevation(),
        highlightElevation: _getHighlightElevation(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        ),
        icon: AuraIcon(
          icon,
          color: foregroundColor,
        ),
        label: AuraText(
          child: Text(
            text!,
            style: TextStyle(
              color:
                  auraColors.getColorOrNull(foregroundColor) ??
                  auraColors.onPrimary,
              fontWeight: DesignTypography.fontWeightMedium,
            ),
          ),
        ),
      );
    }

    if (tooltip != null) {
      fab = Tooltip(
        message: tooltip,
        child: fab,
      );
    }

    if (semanticLabel != null) {
      fab = Semantics(
        label: semanticLabel,
        button: true,
        child: fab,
      );
    }

    return fab;
  }

  Widget _buildRegularContent(AuraColorScheme auraColors) {
    return AuraIcon(
      icon,
      size: _getIconSize(),
      color: foregroundColor ?? AuraColorVariant.onPrimary,
    );
  }

  Widget _buildExtendedContent(AuraColorScheme auraColors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuraIcon(
          icon,
          color: foregroundColor ?? AuraColorVariant.onPrimary,
        ),
        const SizedBox(width: DesignSpacing.sm),
        AuraText(
          child: Text(
            text!,
            style: TextStyle(
              color:
                  auraColors.getColorOrNull(foregroundColor) ??
                  auraColors.onPrimary,
              fontWeight: DesignTypography.fontWeightMedium,
            ),
          ),
        ),
      ],
    );
  }

  double _getFABSize() {
    return switch (size) {
      AuraFABSize.mini => 40.0,
      AuraFABSize.regular => 56.0,
      AuraFABSize.large => 72.0,
      AuraFABSize.extended => 56.0, // Height for extended
    };
  }

  AuraIconSize _getIconSize() {
    return switch (size) {
      AuraFABSize.mini => AuraIconSize.small,
      AuraFABSize.regular => AuraIconSize.medium,
      AuraFABSize.large => AuraIconSize.large,
      AuraFABSize.extended => AuraIconSize.medium,
    };
  }

  double _getBorderRadius() {
    return switch (size) {
      AuraFABSize.mini => DesignBorderRadius.lg,
      AuraFABSize.regular => DesignBorderRadius.xl,
      AuraFABSize.large => DesignBorderRadius.xl,
      AuraFABSize.extended => DesignBorderRadius.xl,
    };
  }

  double _getElevation() {
    return DesignElevation.md;
  }

  double _getFocusElevation() {
    return DesignElevation.lg;
  }

  double _getHoverElevation() {
    return DesignElevation.lg;
  }

  double _getHighlightElevation() {
    return DesignElevation.xl;
  }
}

/// The size of a [AuraFloatingActionButton].
enum AuraFABSize {
  /// Mini FAB (40x40).
  mini,

  /// Regular FAB (56x56) - default.
  regular,

  /// Large FAB (72x72).
  large,

  /// Extended FAB with text.
  extended,
}
