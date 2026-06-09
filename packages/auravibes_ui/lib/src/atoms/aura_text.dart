// ignore_for_file: prefer-static-class
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
    this.color,
  });

  /// The text to display.
  final Widget child;

  /// The style variant to apply to the text.
  final AuraTextStyle style;

  /// Aligmnet.
  final TextAlign? textAlign;

  /// Enum color options.
  final AuraColorVariant? color;

  @override
  Widget build(BuildContext context) {
    final textStyle = auraResolveTextStyle(
      style: style,
      colors: context.auraColors,
    ).copyWith(color: context.auraColors.getColorOrNull(color));

    final iconData = IconThemeData(
      size: textStyle.fontSize,
      color: context.auraColors.getColorOrNull(color) ?? textStyle.color,
    );

    return DefaultTextStyle.merge(
      style: textStyle,
      textAlign: textAlign,
      child: IconTheme(data: iconData, child: child),
    );
  }
}

/// Resolves [AuraTextStyle] to a concrete [TextStyle] using [colors].
TextStyle auraResolveTextStyle({
  required AuraTextStyle style,
  required AuraColorScheme colors,
}) {
  const fontFamily = DesignTypography.bodyFontFamily;

  return switch (style) {
    AuraTextStyle.heading1 => TextStyle(
      color: colors.onBackground,
      fontSize: DesignTypography.fontSize5Xl,
      fontWeight: DesignTypography.fontWeightBold,
      letterSpacing: DesignTypography.letterSpacingTight,
      height: DesignTypography.lineHeight5Xl,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.heading2 => TextStyle(
      color: colors.onBackground,
      fontSize: DesignTypography.fontSize4Xl,
      fontWeight: DesignTypography.fontWeightBold,
      letterSpacing: DesignTypography.letterSpacingTight,
      height: DesignTypography.lineHeight4Xl,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.heading3 => TextStyle(
      color: colors.onBackground,
      fontSize: DesignTypography.fontSize3Xl,
      fontWeight: DesignTypography.fontWeightSemibold,
      letterSpacing: DesignTypography.letterSpacingTight,
      height: DesignTypography.lineHeight3Xl,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.heading4 => TextStyle(
      color: colors.onBackground,
      fontSize: DesignTypography.fontSize2Xl,
      fontWeight: DesignTypography.fontWeightSemibold,
      letterSpacing: DesignTypography.letterSpacingNormal,
      height: DesignTypography.lineHeight2Xl,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.heading5 => TextStyle(
      color: colors.onBackground,
      fontSize: DesignTypography.fontSizeXl,
      fontWeight: DesignTypography.fontWeightSemibold,
      letterSpacing: DesignTypography.letterSpacingNormal,
      height: DesignTypography.lineHeightXl,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.heading6 => TextStyle(
      color: colors.onBackground,
      fontSize: DesignTypography.fontSizeLg,
      fontWeight: DesignTypography.fontWeightSemibold,
      letterSpacing: DesignTypography.letterSpacingNormal,
      height: DesignTypography.lineHeightLg,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.bodyLarge => TextStyle(
      color: colors.onSurface,
      fontSize: DesignTypography.fontSizeLg,
      fontWeight: DesignTypography.fontWeightRegular,
      letterSpacing: DesignTypography.letterSpacingNormal,
      height: DesignTypography.lineHeightLg,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.body => TextStyle(
      color: colors.onSurface,
      fontSize: DesignTypography.fontSizeBase,
      fontWeight: DesignTypography.fontWeightRegular,
      letterSpacing: DesignTypography.letterSpacingNormal,
      height: DesignTypography.lineHeightBase,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.bodySmall => TextStyle(
      color: colors.onSurfaceVariant,
      fontSize: DesignTypography.fontSizeSm,
      fontWeight: DesignTypography.fontWeightRegular,
      letterSpacing: DesignTypography.letterSpacingNormal,
      height: DesignTypography.lineHeightSm,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.caption => TextStyle(
      color: colors.onSurfaceVariant,
      fontSize: DesignTypography.fontSizeXs,
      fontWeight: DesignTypography.fontWeightRegular,
      letterSpacing: DesignTypography.letterSpacingWide,
      height: DesignTypography.lineHeightXs,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.overline => TextStyle(
      color: colors.onSurfaceVariant,
      fontSize: DesignTypography.fontSizeXs,
      fontWeight: DesignTypography.fontWeightMedium,
      letterSpacing: DesignTypography.letterSpacingWide,
      height: DesignTypography.lineHeightXs,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.button => const TextStyle(
      fontSize: DesignTypography.fontSizeBase,
      fontWeight: DesignTypography.fontWeightMedium,
      letterSpacing: DesignTypography.letterSpacingWide,
      height: DesignTypography.lineHeightBase,
      fontFamily: fontFamily,
    ),
    AuraTextStyle.code => TextStyle(
      color: colors.onSurface,
      fontSize: DesignTypography.fontSizeSm,
      fontWeight: DesignTypography.fontWeightRegular,
      letterSpacing: DesignTypography.letterSpacingNormal,
      height: DesignTypography.lineHeightSm,
      fontFamily: DesignTypography.monoFontFamily,
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
