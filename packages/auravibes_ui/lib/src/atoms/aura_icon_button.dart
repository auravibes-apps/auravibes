import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_tooltip.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart'
    show AuraBorderRadius, AuraTint, DesignColors;
import 'package:flutter/material.dart';

/// A specialized icon button component following the Aura design system.
class AuraIconButton extends StatelessWidget {
  static const _extraSmallButtonSize = 24.0;
  static const _smallButtonSize = 32.0;
  static const _mediumButtonSize = 40.0;
  static const _largeButtonSize = 48.0;
  static const _extraLargeButtonSize = 56.0;
  static const _hugeButtonSize = 72.0;
  static const _extraSmallIconSize = 12.0;
  static const _smallIconSize = 16.0;
  static const _mediumIconSize = 20.0;
  static const _largeIconSize = 24.0;
  static const _extraLargeIconSize = 32.0;
  static const _hugeIconSize = 48.0;

  /// Creates an Aura icon button.
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
    final buttonSize = _getButtonSize().clamp(48.0, double.infinity);
    final iconSize = _getIconSize();
    final tooltip = this.tooltip;
    final effectiveSemanticLabel = semanticLabel ?? tooltip ?? 'Icon button';

    final foregroundColor = _getIconColor(auraColors);
    final iconContent =
        child ??
        Icon(
          icon ?? (throw StateError('AuraIconButton requires icon or child')),
          size: iconSize,
          color: foregroundColor,
          semanticLabel: effectiveSemanticLabel,
        );

    Widget button = SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: IconButton(
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        alignment: Alignment.center,
        onPressed: disabled ? null : onPressed,
        constraints: BoxConstraints(
          minWidth: buttonSize,
          minHeight: buttonSize,
        ),
        style: IconButton.styleFrom(
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
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

    if (tooltip != null) {
      button = AuraTooltip(message: tooltip, child: button);
    }

    return button;
  }

  double _getButtonSize() {
    return switch (size) {
      AuraIconSize.extraSmall => _extraSmallButtonSize,
      AuraIconSize.small => _smallButtonSize,
      AuraIconSize.medium => _mediumButtonSize,
      AuraIconSize.large => _largeButtonSize,
      AuraIconSize.extraLarge => _extraLargeButtonSize,
      AuraIconSize.huge => _hugeButtonSize,
    };
  }

  double _getIconSize() {
    return switch (size) {
      AuraIconSize.extraSmall => _extraSmallIconSize,
      AuraIconSize.small => _smallIconSize,
      AuraIconSize.medium => _mediumIconSize,
      AuraIconSize.large => _largeIconSize,
      AuraIconSize.extraLarge => _extraLargeIconSize,
      AuraIconSize.huge => _hugeIconSize,
    };
  }

  AuraBorderRadius _getBorderRadius() {
    return switch (size) {
      AuraIconSize.extraSmall || AuraIconSize.small => .sm,
      AuraIconSize.medium || AuraIconSize.large => .md,
      AuraIconSize.extraLarge || AuraIconSize.huge => .lg,
    };
  }

  Color _getIconColor(AuraColorScheme colors) {
    if (disabled) return colors.onSurfaceVariant.withValues(alpha: 0.6);

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
      AuraIconButtonVariant.ghost ||
      AuraIconButtonVariant.outlined => DesignColors.transparent,
      AuraIconButtonVariant.filled || AuraIconButtonVariant.elevated =>
        colors.colorFor(tint ?? AuraTint.primary),
    };
  }
}

/// The size of an [AuraIcon] or [AuraIconButton].
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

/// The visual variant of an [AuraIconButton].
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
