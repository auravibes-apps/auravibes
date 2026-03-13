import 'package:auravibes_ui/src/atoms/auravibes_loading.dart';
import 'package:auravibes_ui/src/atoms/auravibes_padding.dart';
import 'package:auravibes_ui/src/atoms/auravibes_pressable.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A customizable button component following the Aura design system.
///
/// This button supports multiple variants, sizes, and states while maintaining
/// consistency with the design tokens.
class AuraButton extends StatelessWidget {
  /// Creates a Aura button.
  const AuraButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.variant = AuraButtonVariant.primary,
    this.colorVariant,
    this.size = AuraButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.disabled = false,
  });

  /// The callback that is called when the button is tapped.
  final VoidCallback onPressed;

  /// The widget to display inside the button.
  final Widget child;

  /// The visual variant of the button.
  final AuraButtonVariant variant;

  /// The size of the button.
  final AuraButtonSize size;

  /// Whether the button is in a loading state.
  final bool isLoading;

  /// Whether the button should take the full width of its parent.
  final bool isFullWidth;

  /// Whether the button is disabled.
  final bool disabled;

  /// The color variant of the button.
  final AuraColorVariant? colorVariant;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final auraTheme = context.auraTheme;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: AuraPressable(
        color: DesignColors.transparent,
        onPressed: (disabled || isLoading) ? null : onPressed,
        decoration: BoxDecoration(
          color: _getBackgroundColor(auraColors),
          borderRadius: BorderRadius.circular(auraTheme.borderRadius.xl),
          boxShadow: _getBoxShadow(),
          border: _getBorder(auraColors),
        ),
        child: AuraPadding(
          padding: _getPadding(),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: AuraLoadingCircle(
                      color: _getLoadingColor(auraColors),
                    ),
                  )
                : DefaultTextStyle(
                    style: _getTextStyle(auraColors, auraTheme.typography),
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    if (disabled) {
      if (variant == AuraButtonVariant.text) {
        // Text buttons should keep a transparent background even when disabled.
        return DesignColors.transparent;
      }
      return colors.outlineVariant;
    }

    return switch (variant) {
      AuraButtonVariant.primary =>
        colors.getColorOrNull(colorVariant) ?? colors.primary,
      AuraButtonVariant.secondary => colors.secondary,
      AuraButtonVariant.outlined => DesignColors.transparent,
      AuraButtonVariant.ghost => DesignColors.transparent,
      AuraButtonVariant.elevated =>
        colors.getColorOrNull(colorVariant) ?? colors.primary,
      AuraButtonVariant.text => DesignColors.transparent,
    };
  }

  Color _getForegroundColor(AuraColorScheme colors) {
    if (disabled) return colors.onSurfaceVariant;

    return switch (variant) {
      AuraButtonVariant.primary => colors.onPrimary,
      AuraButtonVariant.secondary => colors.onSecondary,
      AuraButtonVariant.outlined =>
        colors.getColorOrNull(colorVariant) ?? colors.primary,
      AuraButtonVariant.ghost =>
        colors.getColorOrNull(colorVariant) ?? colors.primary,
      AuraButtonVariant.elevated => colors.onPrimary,
      AuraButtonVariant.text =>
        colors.getColorOrNull(colorVariant) ?? colors.primary,
    };
  }

  Color _getLoadingColor(AuraColorScheme colors) {
    if (disabled) return colors.onSurfaceVariant;

    return switch (variant) {
      AuraButtonVariant.primary => colors.onPrimary,
      AuraButtonVariant.secondary => colors.onSecondary,
      AuraButtonVariant.outlined =>
        colors.getColorOrNull(colorVariant) ?? colors.primary,
      AuraButtonVariant.ghost =>
        colors.getColorOrNull(colorVariant) ?? colors.primary,
      AuraButtonVariant.elevated => colors.onPrimary,
      AuraButtonVariant.text => colors.onSurfaceVariant,
    };
  }

  AuraEdgeInsetsGeometry _getPadding() {
    return switch (size) {
      AuraButtonSize.small => const AuraEdgeInsetsGeometry.symmetric(
        horizontal: AuraSpacing.sm,
        vertical: AuraSpacing.xs,
      ),
      AuraButtonSize.medium => const AuraEdgeInsetsGeometry.symmetric(
        horizontal: AuraSpacing.md,
        vertical: AuraSpacing.sm,
      ),
      AuraButtonSize.large => const AuraEdgeInsetsGeometry.symmetric(
        horizontal: AuraSpacing.lg,
        vertical: AuraSpacing.md,
      ),
    };
  }

  Border? _getBorder(AuraColorScheme colors) {
    if (variant == AuraButtonVariant.outlined) {
      return Border.all(
        color: disabled
            ? colors.outlineVariant
            : colors.getColorOrNull(colorVariant) ?? colors.primary,
      );
    }
    return null;
  }

  List<BoxShadow> _getBoxShadow() {
    if (disabled) return [];
    if (variant == AuraButtonVariant.elevated) {
      return [DesignShadows.sm];
    }
    return [];
  }

  TextStyle _getTextStyle(
    AuraColorScheme colors,
    AuraTypographyTheme typography,
  ) {
    final fontSize = switch (size) {
      AuraButtonSize.small => typography.sizes.sm,
      AuraButtonSize.medium => typography.sizes.base,
      AuraButtonSize.large => typography.sizes.lg,
    };

    final fontWeight = switch (size) {
      AuraButtonSize.small => typography.weights.medium,
      AuraButtonSize.medium => typography.weights.medium,
      AuraButtonSize.large => typography.weights.semibold,
    };

    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: _getForegroundColor(colors),
      height: typography.lineHeights.base,
    );
  }
}

/// The visual variant of a [AuraButton].
enum AuraButtonVariant {
  /// A filled button with primary color background.
  primary,

  /// A filled button with secondary color background.
  secondary,

  /// A button with transparent background and border.
  outlined,

  /// A button with transparent background and no border.
  ghost,

  /// A button with elevation and shadow.
  elevated,

  /// A button with transparent background, no border, and minimal padding.
  /// Used for inline actions and dialog buttons.
  text,
}

/// The size of a [AuraButton].
enum AuraButtonSize {
  /// A small button.
  small,

  /// A medium button (default).
  medium,

  /// A large button.
  large,
}
