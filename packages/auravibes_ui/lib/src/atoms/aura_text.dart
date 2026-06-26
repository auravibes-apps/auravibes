// Required: UI package exposes top-level helpers and constants.
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A text widget that follows the Aura design system typography scale.
///
/// This widget provides consistent typography across the application by using
/// predefined text styles based on the design tokens.
class AuraText extends StatelessWidget {
  /// Creates a Aura text widget.
  const AuraText({
    required this.child,
    super.key,
    this.style = AuraTextStyle.body,
    this.textAlign,
    this.tint,
  });

  /// The text to display.
  final Widget child;

  /// The style variant to apply to the text.
  final AuraTextStyle style;

  /// Aligmnet.
  final TextAlign? textAlign;

  /// Optional accent tint.
  final AuraTint? tint;

  @override
  Widget build(BuildContext context) {
    final tint = this.tint;
    final textStyle =
        auraResolveTextStyle(
          style: style,
          colors: context.auraColors,
          typography: context.auraTheme.typography,
        ).copyWith(
          color: tint == null ? null : context.auraColors.colorFor(tint),
        );

    final iconData = IconThemeData(
      size: textStyle.fontSize,
      color: tint == null ? textStyle.color : context.auraColors.colorFor(tint),
    );

    return DefaultTextStyle.merge(
      style: textStyle,
      textAlign: textAlign,
      child: IconTheme(data: iconData, child: child),
    );
  }
}

/// Resolves [AuraTextStyle] to a concrete [TextStyle] using [colors] and
/// [typography].
TextStyle auraResolveTextStyle({
  required AuraTextStyle style,
  required AuraColorScheme colors,
  required AuraTypographyScale typography,
}) {
  final fontFamily = typography.bodyFontFamily;

  return switch (style) {
    AuraTextStyle.heading1 => TextStyle(
      color: colors.foreground,
      fontSize: typography.fontSize5Xl,
      fontWeight: typography.fontWeightBold,
      letterSpacing: typography.letterSpacingTight,
      height: typography.lineHeight5Xl,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.heading2 => TextStyle(
      color: colors.foreground,
      fontSize: typography.fontSize4Xl,
      fontWeight: typography.fontWeightBold,
      letterSpacing: typography.letterSpacingTight,
      height: typography.lineHeight4Xl,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.heading3 => TextStyle(
      color: colors.foreground,
      fontSize: typography.fontSize3Xl,
      fontWeight: typography.fontWeightSemibold,
      letterSpacing: typography.letterSpacingTight,
      height: typography.lineHeight3Xl,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.heading4 => TextStyle(
      color: colors.foreground,
      fontSize: typography.fontSize2Xl,
      fontWeight: typography.fontWeightSemibold,
      letterSpacing: typography.letterSpacingNormal,
      height: typography.lineHeight2Xl,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.heading5 => TextStyle(
      color: colors.foreground,
      fontSize: typography.fontSizeXl,
      fontWeight: typography.fontWeightSemibold,
      letterSpacing: typography.letterSpacingNormal,
      height: typography.lineHeightXl,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.heading6 => TextStyle(
      color: colors.foreground,
      fontSize: typography.fontSizeLg,
      fontWeight: typography.fontWeightSemibold,
      letterSpacing: typography.letterSpacingNormal,
      height: typography.lineHeightLg,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.bodyLarge => TextStyle(
      color: colors.foregroundOnSurface,
      fontSize: typography.fontSizeLg,
      fontWeight: typography.fontWeightRegular,
      letterSpacing: typography.letterSpacingNormal,
      height: typography.lineHeightLg,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.body => TextStyle(
      color: colors.foregroundOnSurface,
      fontSize: typography.fontSizeBase,
      fontWeight: typography.fontWeightRegular,
      letterSpacing: typography.letterSpacingNormal,
      height: typography.lineHeightBase,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.bodySmall => TextStyle(
      color: colors.mutedForeground,
      fontSize: typography.fontSizeSm,
      fontWeight: typography.fontWeightRegular,
      letterSpacing: typography.letterSpacingNormal,
      height: typography.lineHeightSm,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.caption => TextStyle(
      color: colors.mutedForeground,
      fontSize: typography.fontSizeXs,
      fontWeight: typography.fontWeightRegular,
      letterSpacing: typography.letterSpacingWide,
      height: typography.lineHeightXs,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.overline => TextStyle(
      color: colors.mutedForeground,
      fontSize: typography.fontSizeXs,
      fontWeight: typography.fontWeightMedium,
      letterSpacing: typography.letterSpacingWide,
      height: typography.lineHeightXs,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.button => TextStyle(
      fontSize: typography.fontSizeBase,
      fontWeight: typography.fontWeightMedium,
      letterSpacing: typography.letterSpacingWide,
      height: typography.lineHeightBase,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.code => TextStyle(
      color: colors.foregroundOnSurface,
      fontSize: typography.fontSizeSm,
      fontWeight: typography.fontWeightRegular,
      letterSpacing: typography.letterSpacingNormal,
      height: typography.lineHeightSm,
      fontFamily: typography.monoFontFamily,
    ),
  };
}

/// The style variant for [AuraText].
enum AuraTextStyle {
  /// Large heading text (48px).
  heading1,

  /// Medium heading text (36px).
  heading2,

  /// Small heading text (30px).
  heading3,

  /// Extra small heading text (24px).
  heading4,

  /// Tiny heading text (20px).
  heading5,

  /// Micro heading text (18px).
  heading6,

  /// Large body text (18px).
  bodyLarge,

  /// Default body text (16px).
  body,

  /// Small body text (14px).
  bodySmall,

  /// Caption text (12px).
  caption,

  /// Overline text (12px, uppercase).
  overline,

  /// Button text (16px, medium weight).
  button,

  /// Code text (14px, monospace).
  code,
}
