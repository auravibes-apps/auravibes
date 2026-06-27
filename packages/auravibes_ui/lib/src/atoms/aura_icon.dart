// Required: UI components keep related private widgets together.
import 'package:auravibes_ui/src/atoms/aura_tooltip.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart'
    show AuraBorderRadius, AuraTint, DesignColors;
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
    this.tint,
    this.semanticLabel,
  });

  /// The icon to display.
  final IconData icon;

  /// The size of the icon.
  final AuraIconSize size;

  /// The tint of the icon.
  /// If null, uses the default color from the theme.
  final AuraTint? tint;

  /// A semantic label for the icon for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final tint = this.tint;
    final iconColor = tint == null
        ? _getDefaultColor(auraColors)
        : auraColors.colorFor(tint);
    final iconSize = _getIconSize();

    return Semantics(
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
      label: semanticLabel,
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
  // Null follows Flutter button semantics and disables the interaction.
  // ignore: unnecessary-nullable
  const AuraIconButton({
    required this.icon,
    this.onPressed,
    super.key,
    this.disabled = false,
    this.size = AuraIconSize.medium,
    this.tint,
    this.variant = AuraIconButtonVariant.ghost,
    this.semanticLabel,
    this.tooltip,
  }) : child = null;

  /// Creates an Aura icon button with custom icon content.
  // Null follows Flutter button semantics and disables the interaction.
  // ignore: unnecessary-nullable
  const AuraIconButton.custom({
    required this.child,
    this.onPressed,
    super.key,
    this.disabled = false,
    this.size = AuraIconSize.medium,
    this.tint,
    this.variant = AuraIconButtonVariant.ghost,
    this.semanticLabel,
    this.tooltip,
  }) : icon = null;

  /// The icon to display.
  final IconData? icon;

  /// Custom icon content to display.
  final Widget? child;

  /// The callback that is called when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the button is disabled.
  final bool disabled;

  /// The size of the icon.
  final AuraIconSize size;

  /// The tint of the icon.
  /// If null, uses the default color for the variant.
  final AuraTint? tint;

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

    final foregroundColor = _getIconColor(auraColors);
    final iconContent =
        child ??
        Icon(
          icon ?? (throw StateError('AuraIconButton requires icon or child')),
          size: iconSize,
          color: foregroundColor,
          semanticLabel: semanticLabel,
        );

    Widget button = SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: IconButton(
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        onPressed: disabled ? null : onPressed,
        constraints: BoxConstraints(
          minWidth: buttonSize,
          minHeight: buttonSize,
        ),
        style: IconButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: _getBackgroundColor(auraColors),
          elevation: variant == AuraIconButtonVariant.elevated ? 2 : 0,
          shape: RoundedRectangleBorder(
            side: variant == AuraIconButtonVariant.outlined
                ? BorderSide(color: auraColors.outline)
                : BorderSide.none,
            borderRadius: BorderRadius.circular(
              context.auraTheme.fromBorderRadius(_getBorderRadius()),
            ),
          ),
        ),
        icon: iconContent,
      ),
    );

    final tooltip = this.tooltip;
    if (tooltip != null) {
      button = AuraTooltip(
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

  AuraBorderRadius _getBorderRadius() {
    return switch (size) {
      AuraIconSize.extraSmall => .sm,
      AuraIconSize.small => .sm,
      AuraIconSize.medium => .md,
      AuraIconSize.large => .md,
      AuraIconSize.extraLarge => .lg,
      AuraIconSize.huge => .lg,
    };
  }

  Color _getIconColor(AuraColorScheme colors) {
    if (disabled) {
      return colors.onSurfaceVariant.withValues(alpha: 0.6);
    }

    final tint = this.tint;

    return switch (variant) {
      AuraIconButtonVariant.ghost =>
        tint == null ? colors.foregroundOnSurface : colors.colorFor(tint),
      AuraIconButtonVariant.filled => colors.onTint(tint ?? AuraTint.primary),
      AuraIconButtonVariant.outlined => colors.colorFor(
        tint ?? AuraTint.primary,
      ),
      AuraIconButtonVariant.elevated => colors.onTint(tint ?? AuraTint.primary),
    };
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    if (disabled) return DesignColors.transparent;

    return switch (variant) {
      AuraIconButtonVariant.ghost => DesignColors.transparent,
      AuraIconButtonVariant.filled => colors.colorFor(
        tint ?? AuraTint.primary,
      ),
      AuraIconButtonVariant.outlined => DesignColors.transparent,
      AuraIconButtonVariant.elevated => colors.colorFor(
        tint ?? AuraTint.primary,
      ),
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
