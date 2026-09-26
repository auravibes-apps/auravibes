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
  const new({
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

  /// Optional text alignment.
  final TextAlign? textAlign;

  /// Optional accent tint.
  final AuraTint? tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;

    return _AuraTextContent(
      child: child,
      style: AuraTextStyles.resolve(
        style: style,
        colors: colors,
        typography: context.auraTheme.typography,
      ),
      colors: colors,
      tint: tint,
      textAlign: textAlign,
    );
  }
}

class const _AuraTextContent({
  required final Widget child,
  required final TextStyle style,
  required final AuraColorScheme colors,
  required final AuraTint? tint,
  required final TextAlign? textAlign,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tint = this.tint;
    final tintColor = tint == null ? null : colors.colorFor(tint);

    return _AuraTextPresentation(
      child: child,
      style: style.copyWith(color: tintColor),
      tintColor: tintColor,
      textAlign: textAlign,
    );
  }
}

class const _AuraTextPresentation({
  required final Widget child,
  required final TextStyle style,
  required final Color? tintColor,
  required final TextAlign? textAlign,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: style,
      textAlign: textAlign,
      child: IconTheme(data: _iconThemeData(style, tintColor), child: child),
    );
  }
}

IconThemeData _iconThemeData(TextStyle style, Color? tintColor) =>
    .new(size: style.fontSize, color: tintColor ?? style.color);

/// Static text-style resolvers.
abstract final class AuraTextStyles {
  /// Resolves [style] to a concrete [TextStyle] using [colors] and
  /// [typography].
  static TextStyle resolve({
    required AuraTextStyle style,
    required AuraColorScheme colors,
    required AuraTypographyScale typography,
  }) => _resolveTextStyle(_textResolveRequest(style, colors, typography));
}

typedef _AuraTextResolveRequest = ({
  AuraTextStyle style,
  AuraColorScheme colors,
  AuraTypographyScale typography,
  String fontFamily,
});

typedef _AuraTextStyleValues = ({
  Color? color,
  double fontSize,
  FontWeight fontWeight,
  double letterSpacing,
  double height,
  String fontFamily,
});

TextStyle _resolveTextStyle(_AuraTextResolveRequest request) =>
    switch (request.style) {
      .heading1 ||
      .heading2 ||
      .heading3 ||
      .heading4 ||
      .heading5 ||
      .heading6 => _resolveHeading(request),
      _ => _resolveBody(request),
    };

_AuraTextResolveRequest _textResolveRequest(
  AuraTextStyle style,
  AuraColorScheme colors,
  AuraTypographyScale typography,
) => (
  style: style,
  colors: colors,
  typography: typography,
  fontFamily: typography.bodyFontFamily,
);

TextStyle _resolveHeading(_AuraTextResolveRequest request) {
  return _textStyle(_headingStyleValues(request));
}

_AuraTextStyleValues _headingStyleValues(_AuraTextResolveRequest request) {
  final metrics = _headingMetrics(request.style, request.typography);

  return (
    color: request.colors.foreground,
    fontSize: metrics.fontSize,
    fontWeight: metrics.fontWeight,
    letterSpacing: metrics.letterSpacing,
    height: metrics.height,
    fontFamily: request.fontFamily,
  );
}

TextStyle _resolveBody(_AuraTextResolveRequest request) {
  if (request.style == .button) {
    return _buttonStyle(request.typography, request.fontFamily);
  }
  if (request.style == .code) {
    return _codeStyle(request.colors, request.typography);
  }

  return _contentStyle(request);
}

TextStyle _contentStyle(_AuraTextResolveRequest request) {
  return _textStyle(_contentStyleValues(request));
}

_AuraTextStyleValues _contentStyleValues(_AuraTextResolveRequest request) {
  final metrics = _bodyMetrics(request.style, request.typography);

  return (
    color: _bodyColor(request.style, request.colors),
    fontSize: metrics.fontSize,
    fontWeight: metrics.fontWeight,
    letterSpacing: metrics.letterSpacing,
    height: metrics.height,
    fontFamily: request.fontFamily,
  );
}

typedef _AuraTextMetrics = ({
  double fontSize,
  FontWeight fontWeight,
  double letterSpacing,
  double height,
});

_AuraTextMetrics _headingMetrics(
  AuraTextStyle style,
  AuraTypographyScale typography,
) => (
  fontSize: _headingFontSize(style, typography),
  fontWeight: _headingFontWeight(style, typography),
  letterSpacing: _headingLetterSpacing(style, typography),
  height: _headingLineHeight(style, typography),
);

_AuraTextMetrics _bodyMetrics(
  AuraTextStyle style,
  AuraTypographyScale typography,
) => (
  fontSize: _bodyFontSize(style, typography),
  fontWeight: _bodyFontWeight(style, typography),
  letterSpacing: _bodyLetterSpacing(style, typography),
  height: _bodyLineHeight(style, typography),
);

TextStyle _buttonStyle(AuraTypographyScale typography, String fontFamily) =>
    _textStyle((
      color: null,
      fontSize: typography.fontSizeBase,
      fontWeight: typography.fontWeightMedium,
      letterSpacing: typography.letterSpacingWide,
      height: typography.lineHeightBase,
      fontFamily: fontFamily,
    ));

TextStyle _codeStyle(AuraColorScheme colors, AuraTypographyScale typography) =>
    _textStyle((
      color: colors.foregroundOnSurface,
      fontSize: typography.fontSizeSm,
      fontWeight: typography.fontWeightRegular,
      letterSpacing: typography.letterSpacingNormal,
      height: typography.lineHeightSm,
      fontFamily: typography.monoFontFamily,
    ));

TextStyle _textStyle(_AuraTextStyleValues values) => TextStyle(
  color: values.color,
  fontSize: values.fontSize,
  fontWeight: values.fontWeight,
  letterSpacing: values.letterSpacing,
  height: values.height,
  fontFamily: values.fontFamily,
);

double _headingFontSize(AuraTextStyle style, AuraTypographyScale typography) =>
    switch (style) {
      .heading1 => typography.fontSize5Xl,
      .heading2 => typography.fontSize4Xl,
      .heading3 => typography.fontSize3Xl,
      .heading4 => typography.fontSize2Xl,
      .heading5 => typography.fontSizeXl,
      _ => typography.fontSizeLg,
    };

double _headingLineHeight(
  AuraTextStyle style,
  AuraTypographyScale typography,
) => switch (style) {
  .heading1 => typography.lineHeight5Xl,
  .heading2 => typography.lineHeight4Xl,
  .heading3 => typography.lineHeight3Xl,
  .heading4 => typography.lineHeight2Xl,
  .heading5 => typography.lineHeightXl,
  _ => typography.lineHeightLg,
};

FontWeight _headingFontWeight(
  AuraTextStyle style,
  AuraTypographyScale typography,
) => switch (style) {
  .heading1 || .heading2 => typography.fontWeightBold,
  _ => typography.fontWeightSemibold,
};

double _headingLetterSpacing(
  AuraTextStyle style,
  AuraTypographyScale typography,
) => switch (style) {
  .heading1 || .heading2 || .heading3 => typography.letterSpacingTight,
  _ => typography.letterSpacingNormal,
};

Color _bodyColor(AuraTextStyle style, AuraColorScheme colors) =>
    style == .bodyLarge || style == .body
    ? colors.foregroundOnSurface
    : colors.mutedForeground;

double _bodyFontSize(AuraTextStyle style, AuraTypographyScale typography) =>
    switch (style) {
      .bodyLarge => typography.fontSizeLg,
      .body => typography.fontSizeBase,
      .bodySmall => typography.fontSizeSm,
      _ => typography.fontSizeXs,
    };

FontWeight _bodyFontWeight(
  AuraTextStyle style,
  AuraTypographyScale typography,
) => style == .overline
    ? typography.fontWeightMedium
    : typography.fontWeightRegular;

double _bodyLetterSpacing(
  AuraTextStyle style,
  AuraTypographyScale typography,
) => style == .caption || style == .overline
    ? typography.letterSpacingWide
    : typography.letterSpacingNormal;

double _bodyLineHeight(AuraTextStyle style, AuraTypographyScale typography) =>
    switch (style) {
      .bodyLarge => typography.lineHeightLg,
      .body => typography.lineHeightBase,
      .bodySmall => typography.lineHeightSm,
      _ => typography.lineHeightXs,
    };

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
// Public style resolver intentionally remains top-level.
