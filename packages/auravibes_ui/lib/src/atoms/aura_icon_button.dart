import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_tooltip.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart'
    show AuraBorderRadius, AuraTint, DesignColors;
import 'package:flutter/material.dart';

typedef _AuraIconButtonValues = ({
  double iconSize,
  Color foregroundColor,
  Color backgroundColor,
  AuraBorderRadius borderRadius,
});

const _minimumButtonSize = 48.0;

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
  const new({
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
  const new custom({
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

  /// Returns the outer button size for [size].
  static double buttonSizeFor(AuraIconSize size) {
    return switch (size) {
      .extraSmall => _extraSmallButtonSize,
      .small => _smallButtonSize,
      .medium => _mediumButtonSize,
      .large => _largeButtonSize,
      .extraLarge => _extraLargeButtonSize,
      .huge => _hugeButtonSize,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tooltip = this.tooltip;
    final button = _AuraIconButtonContent(button: this);

    if (tooltip == null) {
      return button;
    }

    return AuraTooltip(message: tooltip, child: button);
  }
}

extension on AuraIconButton {
  double _getIconSize() {
    return switch (size) {
      .extraSmall => AuraIconButton._extraSmallIconSize,
      .small => AuraIconButton._smallIconSize,
      .medium => AuraIconButton._mediumIconSize,
      .large => AuraIconButton._largeIconSize,
      .extraLarge => AuraIconButton._extraLargeIconSize,
      .huge => AuraIconButton._hugeIconSize,
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

    return _getEnabledIconColor(colors);
  }

  Color _getEnabledIconColor(AuraColorScheme colors) {
    final tint = this.tint;

    return _iconColorForVariant(variant, colors, tint);
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

Color _iconColorForVariant(
  AuraIconButtonVariant variant,
  AuraColorScheme colors,
  AuraTint? tint,
) => switch (variant) {
  .ghost => tint == null ? colors.foregroundOnSurface : colors.colorFor(tint),
  .filled || .elevated => colors.onTint(tint ?? AuraTint.primary),
  .outlined => colors.colorFor(tint ?? AuraTint.primary),
};

class const _AuraIconButtonContent({required final AuraIconButton button})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _AuraIconButtonControl(button: button, colors: context.auraColors);
}

class const _AuraIconButtonIcon({
  required final IconData? icon,
  required final double size,
  required final Color color,
  required final String semanticLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Icon(
    icon ?? (throw StateError('AuraIconButton requires icon or child')),
    size: size,
    color: color,
    semanticLabel: semanticLabel,
  );
}

class const _AuraIconButtonControl({
  required final AuraIconButton button,
  required final AuraColorScheme colors,
}) extends StatelessWidget {
  double get _buttonSize =>
      AuraIconButton.buttonSizeFor(button.size)
          .clamp(_minimumButtonSize, double.infinity);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _buttonSize,
    height: _buttonSize,
    child: _AuraIconButtonButton(button: button, colors: colors),
  );
}

class const _AuraIconButtonButton({
  required final AuraIconButton button,
  required final AuraColorScheme colors,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraIconButtonButtonData(
    button: button,
    colors: colors,
    theme: context.auraTheme,
  ).toWidget();
}

class _AuraIconButtonButtonData {
  new({
    required AuraIconButton button,
    required AuraColorScheme colors,
    required AuraTheme theme,
  }) : this.fromValues(
         button: button,
         colors: colors,
         theme: theme,
         values: _iconButtonValues(button, colors),
       );

  new fromValues({
    required AuraIconButton button,
    required AuraColorScheme colors,
    required AuraTheme theme,
    required _AuraIconButtonValues values,
  }) : _widget = IconButton(
         iconSize: values.iconSize,
         padding: EdgeInsets.zero,
         alignment: Alignment.center,
         onPressed: _iconButtonOnPressed(button),
         style: IconButton.styleFrom(
           alignment: Alignment.center,
           padding: EdgeInsets.zero,
           foregroundColor: values.foregroundColor,
           backgroundColor: values.backgroundColor,
           elevation: button.variant == AuraIconButtonVariant.elevated ? 2 : 0,
           shape: RoundedRectangleBorder(
             side: button.variant == AuraIconButtonVariant.outlined
                 ? BorderSide(color: colors.outline)
                 : BorderSide.none,
             borderRadius: BorderRadius.circular(
               theme.fromBorderRadius(values.borderRadius),
             ),
           ),
         ),
         icon: _AuraIconButtonIconContent(
           button: button,
           size: values.iconSize,
           color: values.foregroundColor,
         ),
       );

  final Widget _widget;

  Widget toWidget() => _widget;
}

_AuraIconButtonValues _iconButtonValues(
  AuraIconButton button,
  AuraColorScheme colors,
) => (
  iconSize: button._getIconSize(),
  foregroundColor: button._getIconColor(colors),
  backgroundColor: button._getBackgroundColor(colors),
  borderRadius: button._getBorderRadius(),
);

VoidCallback? _iconButtonOnPressed(AuraIconButton button) =>
    button.disabled ? null : button.onPressed;

class const _AuraIconButtonIconContent({
  required final AuraIconButton button,
  required final double size,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      button.child ??
      _AuraIconButtonIcon(
        icon: button.icon,
        size: size,
        color: color,
        semanticLabel: button.semanticLabel ?? button.tooltip ?? 'Icon button',
      );
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
