import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
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

  /// Aligmnet
  final TextAlign? textAlign;

  /// enum color options
  final AuraColorVariant? color;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final textStyle = _getTextStyle(
      auraColors,
    ).copyWith(color: context.auraColors.getColor(color));

    final iconData = IconThemeData(
      color: context.auraColors.getColor(color),
      size: textStyle.fontSize,
    );

    return DefaultTextStyle.merge(
      style: textStyle,
      child: IconTheme(data: iconData, child: child),
      textAlign: textAlign,
    );
  }

  TextStyle _getTextStyle(AuraColorScheme colors) {
    const fontFamily = DesignTypography.bodyFontFamily;

    return switch (style) {
      AuraTextStyle.heading1 => TextStyle(
        fontFamily: fontFamily,
        fontSize: DesignTypography.fontSize5Xl,
        fontWeight: DesignTypography.fontWeightBold,
        height: DesignTypography.lineHeight5Xl,
        letterSpacing: DesignTypography.letterSpacingTight,
        color: colors.onBackground,
      ),
      AuraTextStyle.heading2 => TextStyle(
        fontFamily: fontFamily,
        fontSize: DesignTypography.fontSize4Xl,
        fontWeight: DesignTypography.fontWeightBold,
        height: DesignTypography.lineHeight4Xl,
        letterSpacing: DesignTypography.letterSpacingTight,
        color: colors.onBackground,
      ),
      AuraTextStyle.heading3 => TextStyle(
        fontFamily: fontFamily,
        fontSize: DesignTypography.fontSize3Xl,
        fontWeight: DesignTypography.fontWeightSemibold,
        height: DesignTypography.lineHeight3Xl,
        letterSpacing: DesignTypography.letterSpacingTight,
        color: colors.onBackground,
      ),
      AuraTextStyle.heading4 => TextStyle(
        fontFamily: fontFamily,
        fontSize: DesignTypography.fontSize2Xl,
        fontWeight: DesignTypography.fontWeightSemibold,
        height: DesignTypography.lineHeight2Xl,
        letterSpacing: DesignTypography.letterSpacingNormal,
        color: colors.onBackground,
      ),
      AuraTextStyle.heading5 => TextStyle(
        fontFamily: fontFamily,
        fontSize: DesignTypography.fontSizeXl,
        fontWeight: DesignTypography.fontWeightSemibold,
        height: DesignTypography.lineHeightXl,
        letterSpacing: DesignTypography.letterSpacingNormal,
        color: colors.onBackground,
      ),
      AuraTextStyle.heading6 => TextStyle(
        fontFamily: fontFamily,
        fontSize: DesignTypography.fontSizeLg,
        fontWeight: DesignTypography.fontWeightSemibold,
        height: DesignTypography.lineHeightLg,
        letterSpacing: DesignTypography.letterSpacingNormal,
        color: colors.onBackground,
      ),
      AuraTextStyle.bodyLarge => TextStyle(
        fontFamily: fontFamily,
        fontSize: DesignTypography.fontSizeLg,
        fontWeight: DesignTypography.fontWeightRegular,
        height: DesignTypography.lineHeightLg,
        letterSpacing: DesignTypography.letterSpacingNormal,
        color: colors.onSurface,
      ),
      AuraTextStyle.body => TextStyle(
        fontFamily: fontFamily,
        fontSize: DesignTypography.fontSizeBase,
        fontWeight: DesignTypography.fontWeightRegular,
        height: DesignTypography.lineHeightBase,
        letterSpacing: DesignTypography.letterSpacingNormal,
        color: colors.onSurface,
      ),
      AuraTextStyle.bodySmall => TextStyle(
        fontFamily: fontFamily,
        fontSize: DesignTypography.fontSizeSm,
        fontWeight: DesignTypography.fontWeightRegular,
        height: DesignTypography.lineHeightSm,
        letterSpacing: DesignTypography.letterSpacingNormal,
        color: colors.onSurfaceVariant,
      ),
      AuraTextStyle.caption => TextStyle(
        fontFamily: fontFamily,
        fontSize: DesignTypography.fontSizeXs,
        fontWeight: DesignTypography.fontWeightRegular,
        height: DesignTypography.lineHeightXs,
        letterSpacing: DesignTypography.letterSpacingWide,
        color: colors.onSurfaceVariant,
      ),
      AuraTextStyle.overline => TextStyle(
        fontFamily: fontFamily,
        fontSize: DesignTypography.fontSizeXs,
        fontWeight: DesignTypography.fontWeightMedium,
        height: DesignTypography.lineHeightXs,
        letterSpacing: DesignTypography.letterSpacingWide,
        color: colors.onSurfaceVariant,
      ),
      AuraTextStyle.button => const TextStyle(
        fontFamily: fontFamily,
        fontSize: DesignTypography.fontSizeBase,
        fontWeight: DesignTypography.fontWeightMedium,
        height: DesignTypography.lineHeightBase,
        letterSpacing: DesignTypography.letterSpacingWide,
      ),
      AuraTextStyle.code => TextStyle(
        fontFamily: DesignTypography.monoFontFamily,
        fontSize: DesignTypography.fontSizeSm,
        fontWeight: DesignTypography.fontWeightRegular,
        height: DesignTypography.lineHeightSm,
        letterSpacing: DesignTypography.letterSpacingNormal,
        color: colors.onSurface,
      ),
    };
  }
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
