import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A selectable text widget that follows the Aura design system.
///
/// This widget allows users to select and copy text while maintaining
/// consistent typography styling from the Aura design system.
///
/// Example:
/// ```dart
/// AuraSelectableText(
///   'Copy this text',
///   style: AuraTextStyle.body,
/// )
/// ```
class AuraSelectableText extends StatelessWidget {
  /// Creates an Aura selectable text widget.
  const AuraSelectableText(
    this.data, {
    super.key,
    this.style = AuraTextStyle.body,
    this.colorVariant,
    this.textAlign,
    this.maxLines,
    this.onTap,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.onSelectionChanged,
    this.showCursor = false,
    this.autofocus = false,
    this.minLines,
  });

  /// The text to display.
  final String data;

  /// The style variant to apply to the text.
  final AuraTextStyle style;

  /// The color variant for the text.
  final AuraColorVariant? colorVariant;

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

  /// The maximum number of lines for the text to span.
  final int? maxLines;

  /// Called when the user taps on the text.
  final GestureTapCallback? onTap;

  /// How thick the cursor will be.
  final double cursorWidth;

  /// How tall the cursor will be.
  final double? cursorHeight;

  /// How rounded the cursor is.
  final Radius? cursorRadius;

  /// The color of the cursor.
  final Color? cursorColor;

  /// Called when the user changes the selection.
  final SelectionChangedCallback? onSelectionChanged;

  /// Whether to show cursor.
  final bool showCursor;

  /// Whether this text field should focus itself.
  final bool autofocus;

  /// The minimum number of lines to occupy when the content spans fewer lines.
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final textStyle = _getTextStyle(auraColors).copyWith(
      color: auraColors.getColor(colorVariant),
    );

    return SelectableText(
      data,
      style: textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      onTap: onTap,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorColor: cursorColor ?? auraColors.primary,
      onSelectionChanged: onSelectionChanged,
      showCursor: showCursor,
      autofocus: autofocus,
      minLines: minLines,
    );
  }

  /// Gets the text style based on the [AuraTextStyle] enum.
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
