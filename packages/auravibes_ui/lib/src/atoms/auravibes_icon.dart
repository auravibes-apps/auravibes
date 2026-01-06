import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable icon component following the Aura design system.
///
/// This icon widget provides consistent sizing, theming, and accessibility
/// features across the application.
class AuraIcon extends StatelessWidget {
  /// Creates a Aura icon.
  const AuraIcon(
    this.icon, {
    super.key,
    this.size = AuraIconSize.medium,
    this.color,
    this.semanticLabel,
  });

  /// The icon to display.
  final IconData icon;

  /// The size of the icon.
  final AuraIconSize size;

  /// The color of the icon. If null, uses the default color from the theme.
  final Color? color;

  /// A semantic label for the icon for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final iconColor = color ?? _getDefaultColor(auraColors);
    final iconSize = _getIconSize();

    return Semantics(
      label: semanticLabel,
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
    );
  }

  double _getIconSize() {
    return switch (size) {
      AuraIconSize.extraSmall => 12.0,
      AuraIconSize.small => 16.0,
      AuraIconSize.medium => 20.0,
      AuraIconSize.large => 24.0,
      AuraIconSize.extraLarge => 32.0,
      AuraIconSize.huge => 48.0,
    };
  }

  Color _getDefaultColor(AuraColorScheme colors) {
    return colors.onSurface;
  }
}

/// A specialized icon button component following the Aura design system.
///
/// This provides a consistent way to create interactive icons with proper
/// touch targets and accessibility features.
class AuraIconButton extends StatelessWidget {
  /// Creates a Aura icon button.
  const AuraIconButton({
    required this.icon,
    this.onPressed,
    super.key,
    this.disabled = false,
    this.size = AuraIconSize.medium,
    this.color,
    this.backgroundColor,
    this.variant = AuraIconButtonVariant.ghost,
    this.semanticLabel,
    this.tooltip,
  });

  /// The icon to display.
  final IconData icon;

  /// The callback that is called when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the button is disabled.
  final bool disabled;

  /// The size of the icon.
  final AuraIconSize size;

  /// The color of the icon. If null, uses the default color for the variant.
  final Color? color;

  /// The background color of the button. If null, uses the default for the
  /// variant.
  final Color? backgroundColor;

  /// The visual variant of the icon button.
  final AuraIconButtonVariant variant;

  /// A semantic label for the button for accessibility.
  final String? semanticLabel;

  /// The tooltip message to display when the button is long-pressed.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final buttonSize = _getButtonSize();
    final iconSize = _getIconSize();

    Widget button = SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: IconButton(
        onPressed: disabled ? null : onPressed,
        icon: AuraIcon(
          icon,
          size: size,
          color: color ?? _getIconColor(auraColors),
          semanticLabel: semanticLabel,
        ),
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: buttonSize,
          minHeight: buttonSize,
        ),
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor ?? _getBackgroundColor(auraColors),
          foregroundColor: color ?? _getIconColor(auraColors),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
            side: variant == AuraIconButtonVariant.outlined
                ? BorderSide(
                    color: auraColors.outline,
                  )
                : BorderSide.none,
          ),
          elevation: variant == AuraIconButtonVariant.elevated ? 2 : 0,
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }

  double _getButtonSize() {
    return switch (size) {
      AuraIconSize.extraSmall => 24.0,
      AuraIconSize.small => 32.0,
      AuraIconSize.medium => 40.0,
      AuraIconSize.large => 48.0,
      AuraIconSize.extraLarge => 56.0,
      AuraIconSize.huge => 72.0,
    };
  }

  double _getIconSize() {
    return switch (size) {
      AuraIconSize.extraSmall => 12.0,
      AuraIconSize.small => 16.0,
      AuraIconSize.medium => 20.0,
      AuraIconSize.large => 24.0,
      AuraIconSize.extraLarge => 32.0,
      AuraIconSize.huge => 48.0,
    };
  }

  double _getBorderRadius() {
    return switch (size) {
      AuraIconSize.extraSmall => DesignBorderRadius.sm,
      AuraIconSize.small => DesignBorderRadius.sm,
      AuraIconSize.medium => DesignBorderRadius.md,
      AuraIconSize.large => DesignBorderRadius.md,
      AuraIconSize.extraLarge => DesignBorderRadius.lg,
      AuraIconSize.huge => DesignBorderRadius.lg,
    };
  }

  Color _getIconColor(AuraColorScheme colors) {
    if (disabled) {
      return colors.onSurfaceVariant.withValues(alpha: 0.6);
    }

    return switch (variant) {
      AuraIconButtonVariant.ghost => colors.onSurface,
      AuraIconButtonVariant.filled => colors.onPrimary,
      AuraIconButtonVariant.outlined => colors.primary,
      AuraIconButtonVariant.elevated => colors.onPrimary,
    };
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    if (disabled) return Colors.transparent;

    return switch (variant) {
      AuraIconButtonVariant.ghost => Colors.transparent,
      AuraIconButtonVariant.filled => colors.primary,
      AuraIconButtonVariant.outlined => Colors.transparent,
      AuraIconButtonVariant.elevated => colors.primary,
    };
  }
}

/// The size of a [AuraIcon] or [AuraIconButton].
enum AuraIconSize {
  /// Extra small icon (12px).
  extraSmall,

  /// Small icon (16px).
  small,

  /// Medium icon (20px) - default.
  medium,

  /// Large icon (24px).
  large,

  /// Extra large icon (32px).
  extraLarge,

  /// Huge icon (48px).
  huge,
}

/// The visual variant of a [AuraIconButton].
enum AuraIconButtonVariant {
  /// A button with transparent background.
  ghost,

  /// A button with filled background.
  filled,

  /// A button with transparent background and border.
  outlined,

  /// A button with filled background and elevation.
  elevated,
}
