// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A customizable button component following the Aura design system.
///
/// This button supports multiple variants, sizes, and states while maintaining
/// consistency with the design tokens.
class AuraButton extends StatelessWidget {
  /// Creates a Aura button.
  const new({
    required this.onPressed,
    required this.child,
    super.key,
    this.variant = AuraButtonVariant.primary,
    this.tint,
    this.size = AuraButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.disabled = false,
    this.semanticLabel,
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

  /// The tint of the button.
  final AuraTint? tint;

  /// A semantic label for the button.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => _AuraButtonLayout(
    button: this,
    colors: context.auraColors,
    typography: context.auraTheme.typography,
    radius: context.auraTheme.fromBorderRadius(.xl),
    disabled: disabled || !AuraInteractionScope.of(context).allowsActions,
  );
}

class const _AuraButtonLayout({
  required final AuraButton button,
  required final AuraColorScheme colors,
  required final AuraTypographyScale typography,
  required final double radius,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: button.isFullWidth ? double.infinity : null,
    child: _AuraButtonSurface(
      button: button,
      colors: colors,
      typography: typography,
      radius: radius,
      disabled: disabled,
    ),
  );
}

class const _AuraButtonSurface({
  required final AuraButton button,
  required final AuraColorScheme colors,
  required final AuraTypographyScale typography,
  required final double radius,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPressable(
    child: _AuraButtonPaddedContent(
      button: button,
      colors: colors,
      typography: typography,
      disabled: disabled,
    ),
    color: _buttonForegroundColor(button, colors, disabled: disabled),
    decoration: _buttonDecoration(button, colors, radius, disabled: disabled),
    onPressed: _buttonOnPressed(button, disabled),
    semanticLabel: button.semanticLabel,
    isButtonSemantics: true,
  );
}

VoidCallback? _buttonOnPressed(AuraButton button, bool disabled) =>
    disabled || button.isLoading ? null : button.onPressed;

class const _AuraButtonPaddedContent({
  required final AuraButton button,
  required final AuraColorScheme colors,
  required final AuraTypographyScale typography,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPadding(
    child: _AuraButtonContent(
      button: button,
      colors: colors,
      disabled: disabled,
      typography: typography,
    ),
    padding: _buttonPadding(button.variant, button.size),
  );
}

class const _AuraButtonContent({
  required final AuraButton button,
  required final AuraColorScheme colors,
  required final AuraTypographyScale typography,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    widthFactor: button.isFullWidth ? null : 1,
    heightFactor: 1,
    child: button.isLoading
        ? _AuraButtonLoading(button: button, colors: colors, disabled: disabled)
        : _AuraButtonLabel(
            button: button,
            colors: colors,
            typography: typography,
            disabled: disabled,
          ),
  );
}

class const _AuraButtonLoading({
  required final AuraButton button,
  required final AuraColorScheme colors,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraLoadingCircle(
    tint: button.tint ?? AuraTint.primary,
    size: 20,
    itemBuilder: (context, _) => DecoratedBox(
      decoration: BoxDecoration(
        color: _buttonForegroundColor(button, colors, disabled: disabled),
        shape: .circle,
      ),
    ),
  );
}

class const _AuraButtonLabel({
  required final AuraButton button,
  required final AuraColorScheme colors,
  required final AuraTypographyScale typography,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DefaultTextStyle(
    style: _buttonTextStyle(button, colors, typography, disabled: disabled),
    child: button.child,
  );
}

BoxDecoration _buttonDecoration(
  AuraButton button,
  AuraColorScheme colors,
  double radius, {
  required bool disabled,
}) => BoxDecoration(
  color: _buttonBackgroundColor(button, colors, disabled: disabled),
  border: _buttonBorder(button, colors, disabled: disabled),
  borderRadius: BorderRadius.all(.circular(radius)),
  boxShadow: _buttonBoxShadow(button, disabled: disabled),
);

Color _buttonBackgroundColor(
  AuraButton button,
  AuraColorScheme colors, {
  required bool disabled,
}) {
  if (disabled) {
    return button.variant == AuraButtonVariant.text
        ? DesignColors.transparent
        : colors.outlineVariant;
  }

  return switch (button.variant) {
    .primary || .elevated => colors.colorFor(button.tint ?? AuraTint.primary),
    .secondary => colors.secondary,
    .outlined || .ghost || .text => DesignColors.transparent,
  };
}

Color _buttonForegroundColor(
  AuraButton button,
  AuraColorScheme colors, {
  required bool disabled,
}) {
  if (disabled) return colors.onSurfaceVariant;

  final primaryColor = colors.colorFor(button.tint ?? AuraTint.primary);

  return switch (button.variant) {
    .primary || .elevated => colors.onTint(button.tint ?? AuraTint.primary),
    .secondary => colors.onTint(.secondary),
    .outlined || .ghost || .text => primaryColor,
  };
}

AuraEdgeInsetsGeometry _buttonPadding(
  AuraButtonVariant variant,
  AuraButtonSize size,
) {
  if (variant == AuraButtonVariant.text) {
    return const AuraEdgeInsetsGeometry.symmetric(
      horizontal: .sm,
      vertical: .xs,
    );
  }

  return switch (size) {
    .small => const AuraEdgeInsetsGeometry.symmetric(
      horizontal: .sm,
      vertical: .xs,
    ),
    .medium => const AuraEdgeInsetsGeometry.symmetric(
      horizontal: .md,
      vertical: .sm,
    ),
    .large => const AuraEdgeInsetsGeometry.symmetric(
      horizontal: .lg,
      vertical: .md,
    ),
  };
}

Border? _buttonBorder(
  AuraButton button,
  AuraColorScheme colors, {
  required bool disabled,
}) => button.variant == AuraButtonVariant.outlined
    ? Border.all(
        color: disabled
            ? colors.outlineVariant
            : colors.colorFor(button.tint ?? AuraTint.primary),
      )
    : null;

List<BoxShadow> _buttonBoxShadow(AuraButton button, {required bool disabled}) =>
    disabled || button.variant != AuraButtonVariant.elevated
    ? const []
    : [DesignShadows.sm];

TextStyle _buttonTextStyle(
  AuraButton button,
  AuraColorScheme colors,
  AuraTypographyScale typography, {
  required bool disabled,
}) => TextStyle(
  color: _buttonForegroundColor(button, colors, disabled: disabled),
  fontSize: _buttonFontSize(button.size, typography),
  fontWeight: _buttonFontWeight(button.size, typography),
  height: typography.lineHeightBase,
);

double _buttonFontSize(AuraButtonSize size, AuraTypographyScale typography) =>
    switch (size) {
      .small => typography.fontSizeSm,
      .medium => typography.fontSizeBase,
      .large => typography.fontSizeLg,
    };

FontWeight _buttonFontWeight(
  AuraButtonSize size,
  AuraTypographyScale typography,
) => switch (size) {
  .small || .medium => typography.fontWeightMedium,
  .large => typography.fontWeightSemibold,
};

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
