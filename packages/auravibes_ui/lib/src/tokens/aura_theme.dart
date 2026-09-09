// Required: Existing test and UI helpers keep compact return flow.
// Required: UI package exposes top-level helpers and constants.

import 'package:auravibes_ui/src/colors/value_color.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

typedef _SpacingCoreLerpValues = ({
  double none,
  double base,
  double xs,
  double sm,
  double md,
});

typedef _SpacingExtendedLerpValues = ({
  double lg,
  double xl,
  double xl2,
  double xl3,
});

typedef _SpacingLerpValues = ({
  _SpacingCoreLerpValues core,
  _SpacingExtendedLerpValues extended,
});

typedef _TypographyFonts = ({
  String headingFontFamily,
  String bodyFontFamily,
  String monoFontFamily,
});

typedef _TypographySmallSizes = ({
  double fontSizeXs,
  double fontSizeSm,
  double fontSizeBase,
  double fontSizeLg,
  double fontSizeXl,
});

typedef _TypographyLargeSizes = ({
  double fontSize2Xl,
  double fontSize3Xl,
  double fontSize4Xl,
  double fontSize5Xl,
});

typedef _TypographySizes = ({
  _TypographySmallSizes small,
  _TypographyLargeSizes large,
});

typedef _TypographyWeights = ({
  FontWeight fontWeightLight,
  FontWeight fontWeightRegular,
  FontWeight fontWeightMedium,
  FontWeight fontWeightSemibold,
  FontWeight fontWeightBold,
});

typedef _TypographySmallLineHeights = ({
  double lineHeightXs,
  double lineHeightSm,
  double lineHeightBase,
  double lineHeightLg,
  double lineHeightXl,
});

typedef _TypographyLargeLineHeights = ({
  double lineHeight2Xl,
  double lineHeight3Xl,
  double lineHeight4Xl,
  double lineHeight5Xl,
});

typedef _TypographyLineHeights = ({
  _TypographySmallLineHeights small,
  _TypographyLargeLineHeights large,
});

typedef _TypographyLetterSpacing = ({
  double letterSpacingTight,
  double letterSpacingNormal,
  double letterSpacingWide,
});

typedef _ColorTripletLerpValues = ({
  Color primary,
  Color primaryVariant,
  Color onPrimary,
});

typedef _BrandLerpValues = ({
  _ColorTripletLerpValues primary,
  _ColorTripletLerpValues secondary,
  _ColorTripletLerpValues tertiary,
});

typedef _StatusPrimaryLerpValues = ({
  _ColorPairLerpValues error,
  _ColorPairLerpValues warning,
});

typedef _StatusSecondaryLerpValues = ({
  _ColorPairLerpValues success,
  _ColorPairLerpValues info,
});

typedef _StatusLerpValues = ({
  _StatusPrimaryLerpValues primary,
  _StatusSecondaryLerpValues secondary,
});

typedef _ColorSchemeLerpValues = ({
  _BrandLerpValues brand,
  _SurfaceLerpValues surface,
  _StatusLerpValues status,
  _ChromeLerpValues chrome,
});

typedef _ColorPairLerpValues = ({Color value, Color onValue});

typedef _SurfaceLerpValues = ({
  _SurfaceCoreLerpValues core,
  _SurfaceBackgroundLerpValues background,
});

typedef _SurfaceCoreLerpValues = ({
  Color surface,
  Color surfaceVariant,
  Color onSurface,
  Color onSurfaceVariant,
});

typedef _SurfaceBackgroundLerpValues = ({Color background, Color onBackground});

typedef _BorderRadiusCoreLerpValues = ({double none, double sm, double md});

typedef _BorderRadiusExtendedLerpValues = ({double lg, double xl, double full});

typedef _BorderRadiusLerpValues = ({
  _BorderRadiusCoreLerpValues core,
  _BorderRadiusExtendedLerpValues extended,
});

typedef _ChromeLerpValues = ({
  Color outline,
  Color outlineVariant,
  Color shadow,
  Color scrim,
});

/// Aura theme extension that provides theme-aware design tokens.
///
/// Colors, spacing, border radius, and typography all live here so a subtree
/// `Theme` override can rescale them. Call sites select values via the
/// AuraSpacing / AuraBorderRadius enums (and AuraTextStyle for type), resolved
/// at build time through [fromSpacing] / [fromBorderRadius] / [typography].
@immutable
class AuraTheme extends ThemeExtension<AuraTheme> {
  static const _standardAnimation = AuraAnimationTheme._standard();

  /// Light theme variant.
  static final light = AuraTheme(
    colors: _lightColors,
    animation: _standardAnimation,
  );

  /// Dark theme variant.
  static final dark = AuraTheme(
    colors: _darkColors,
    animation: _standardAnimation,
  );

  static final _lightColors = AuraColorScheme._light();
  static final _darkColors = AuraColorScheme._dark();

  /// Creates a Aura theme extension.
  const new({
    required this.colors,
    required this.animation,
    this.spacing = const AuraSpacingScale._standard(),
    this.borderRadius = const AuraBorderRadiusScale._standard(),
    this.typography = const AuraTypographyScale._standard(),
  });

  /// Color scheme for the theme.
  final AuraColorScheme colors;

  /// Animation theme.
  final AuraAnimationTheme animation;

  /// Theme-owned spacing scale (rethemeable, lerp-able).
  final AuraSpacingScale spacing;

  /// Theme-owned border-radius scale (rethemeable, lerp-able).
  final AuraBorderRadiusScale borderRadius;

  /// Theme-owned typography scale (rethemeable, lerp-able).
  final AuraTypographyScale typography;

  @override
  AuraTheme copyWith({
    AuraColorScheme? colors,
    AuraAnimationTheme? animation,
    AuraSpacingScale? spacing,
    AuraBorderRadiusScale? borderRadius,
    AuraTypographyScale? typography,
  }) {
    return AuraTheme(
      colors: colors ?? this.colors,
      animation: animation ?? this.animation,
      spacing: spacing ?? this.spacing,
      borderRadius: borderRadius ?? this.borderRadius,
      typography: typography ?? this.typography,
    );
  }

  @override
  AuraTheme lerp(AuraTheme? other, double t) {
    if (other == null) return this;

    return AuraTheme(
      colors: colors.lerp(other.colors, t),
      animation: animation.lerp(other.animation, t),
      spacing: spacing.lerp(other.spacing, t),
      borderRadius: borderRadius.lerp(other.borderRadius, t),
      typography: typography.lerp(other.typography, t),
    );
  }

  /// Resolve an [AuraSpacing] enum to its concrete pixel value.
  double fromSpacing(AuraSpacing value) => spacing.resolve(value);

  /// Resolve an [AuraBorderRadius] enum to its concrete pixel value.
  double fromBorderRadius(AuraBorderRadius value) =>
      borderRadius.resolve(value);
}

/// Theme-owned spacing scale. It contains one [double] per [AuraSpacing] step.
///
/// Values are absent from the [AuraSpacing] enum on purpose. A subtree
/// `Theme` override can rescale spacing. [AuraSpacingScale._standard] carries
/// the design-system defaults (base unit 16px).
@immutable
class AuraSpacingScale {
  static const _noneValue = 0.0;
  static const _baseValue = 16.0;
  static const _extraSmallValue = 4.0;
  static const _smallValue = 8.0;
  static const _mediumValue = 16.0;
  static const _largeValue = 24.0;
  static const _extraLargeValue = 32.0;
  static const _extraLarge2Value = 48.0;
  static const _extraLarge3Value = 64.0;

  /// Creates a spacing scale.
  const new({
    this.none = _noneValue,
    this.base = _baseValue,
    this.xs = _extraSmallValue,
    this.sm = _smallValue,
    this.md = _mediumValue,
    this.lg = _largeValue,
    this.xl = _extraLargeValue,
    this.xl2 = _extraLarge2Value,
    this.xl3 = _extraLarge3Value,
  });

  new _fromLerpValues(_SpacingLerpValues values)
    : none = values.core.none,
      base = values.core.base,
      xs = values.core.xs,
      sm = values.core.sm,
      md = values.core.md,
      lg = values.extended.lg,
      xl = values.extended.xl,
      xl2 = values.extended.xl2,
      xl3 = values.extended.xl3;

  /// Design-system standard spacing scale.
  const new _standard()
    : none = _noneValue,
      base = _baseValue,
      xs = _extraSmallValue,
      sm = _smallValue,
      md = _mediumValue,
      lg = _largeValue,
      xl = _extraLargeValue,
      xl2 = _extraLarge2Value,
      xl3 = _extraLarge3Value;

  /// Value for [AuraSpacing.none].
  final double none;

  /// Value for [AuraSpacing.base].
  final double base;

  /// Value for [AuraSpacing.xs].
  final double xs;

  /// Value for [AuraSpacing.sm].
  final double sm;

  /// Value for [AuraSpacing.md].
  final double md;

  /// Value for [AuraSpacing.lg].
  final double lg;

  /// Value for [AuraSpacing.xl].
  final double xl;

  /// Value for [AuraSpacing.xl2].
  final double xl2;

  /// Value for [AuraSpacing.xl3].
  final double xl3;

  /// Resolve a spacing selector to its concrete pixel value.
  double resolve(AuraSpacing spacing) {
    return switch (spacing) {
      .none => none,
      .base => base,
      .xs => xs,
      .sm => sm,
      .md => md,
      .lg => lg,
      .xl => xl,
      .xl2 => xl2,
      .xl3 => xl3,
    };
  }

  /// Linearly interpolate between two spacing scales.
  AuraSpacingScale lerp(AuraSpacingScale other, double t) {
    if (t <= 0) return this;
    if (t >= 1) return other;

    return AuraSpacingScale._fromLerpValues(_lerpSpacingValues(this, other, t));
  }
}

/// Theme-owned border-radius scale: one [double] per [AuraBorderRadius] step.
@immutable
class AuraBorderRadiusScale {
  static const _noneValue = 0.0;
  static const _smallValue = 2.0;
  static const _mediumValue = 6.0;
  static const _largeValue = 8.0;
  static const _extraLargeValue = 16.0;
  static const _fullValue = 9999.0;

  /// Creates a border-radius scale.
  const new({
    this.none = _noneValue,
    this.sm = _smallValue,
    this.md = _mediumValue,
    this.lg = _largeValue,
    this.xl = _extraLargeValue,
    this.full = _fullValue,
  });

  new _fromLerpValues(_BorderRadiusLerpValues values)
    : none = values.core.none,
      sm = values.core.sm,
      md = values.core.md,
      lg = values.extended.lg,
      xl = values.extended.xl,
      full = values.extended.full;

  /// Design-system standard border-radius scale.
  const new _standard()
    : none = _noneValue,
      sm = _smallValue,
      md = _mediumValue,
      lg = _largeValue,
      xl = _extraLargeValue,
      full = _fullValue;

  /// Value for [AuraBorderRadius.none].
  final double none;

  /// Value for [AuraBorderRadius.sm].
  final double sm;

  /// Value for [AuraBorderRadius.md].
  final double md;

  /// Value for [AuraBorderRadius.lg].
  final double lg;

  /// Value for [AuraBorderRadius.xl].
  final double xl;

  /// Value for [AuraBorderRadius.full].
  final double full;

  /// Resolve a border-radius selector to its concrete pixel value.
  double resolve(AuraBorderRadius radius) {
    return switch (radius) {
      .none => none,
      .sm => sm,
      .md => md,
      .lg => lg,
      .xl => xl,
      .full => full,
    };
  }

  /// Linearly interpolate between two border-radius scales.
  AuraBorderRadiusScale lerp(AuraBorderRadiusScale other, double t) {
    if (t <= 0) return this;
    if (t >= 1) return other;

    return AuraBorderRadiusScale._fromLerpValues(
      _lerpBorderRadiusValues(this, other, t),
    );
  }
}

/// Theme-owned typography scale. It contains font sizes, weights, line heights,
/// spacings, and font families.
///
/// Font families are strings and do not interpolate; [lerp] picks the source
/// or target family at the halfway point (mirroring [AuraAnimationTheme]).
@immutable
class AuraTypographyScale {
  static const _xl5Line = 1.0;
  static const _smFont = 14.0;
  static const _baseFont = 16.0;
  static const _lgFont = 18.0;
  static const _xlFont = 20.0;
  static const _xl2Font = 24.0;
  static const _xl3Font = 30.0;
  static const _xl4Font = 36.0;
  static const _xl5Font = 48.0;
  static const _xsLine = 1.2;
  static const _smLine = 1.25;
  static const _baseLine = 1.5;
  static const _lgLine = 1.55;
  static const _xlLine = 1.6;
  static const _xl2Line = 1.3;
  static const _xl3Line = 1.2;
  static const _xl4Line = 1.1;
  static const _xsFont = 12.0;
  static const _normalLetterSpacing = 0.0;
  static const _wideLetterSpacing = 0.025;
  static const _tightLetterSpacing = -0.025;
  static const _halfway = 0.5;

  /// Creates a typography scale.
  const new({
    this.headingFontFamily = 'Inter',
    this.bodyFontFamily = 'Inter',
    this.monoFontFamily = 'JetBrains Mono',
    this.fontSizeXs = _xsFont,
    this.fontSizeSm = _smFont,
    this.fontSizeBase = _baseFont,
    this.fontSizeLg = _lgFont,
    this.fontSizeXl = _xlFont,
    this.fontSize2Xl = _xl2Font,
    this.fontSize3Xl = _xl3Font,
    this.fontSize4Xl = _xl4Font,
    this.fontSize5Xl = _xl5Font,
    this.fontWeightLight = FontWeight.w300,
    this.fontWeightRegular = FontWeight.w400,
    this.fontWeightMedium = FontWeight.w500,
    this.fontWeightSemibold = FontWeight.w600,
    this.fontWeightBold = FontWeight.w700,
    this.lineHeightXs = _xsLine,
    this.lineHeightSm = _smLine,
    this.lineHeightBase = _baseLine,
    this.lineHeightLg = _lgLine,
    this.lineHeightXl = _xlLine,
    this.lineHeight2Xl = _xl2Line,
    this.lineHeight3Xl = _xl3Line,
    this.lineHeight4Xl = _xl4Line,
    this.lineHeight5Xl = _xl5Line,
    this.letterSpacingTight = _tightLetterSpacing,
    this.letterSpacingNormal = _normalLetterSpacing,
    this.letterSpacingWide = _wideLetterSpacing,
  });

  new _fromLerpGroups({
    required _TypographyFonts fonts,
    required _TypographySizes sizes,
    required _TypographyWeights weights,
    required _TypographyLineHeights lineHeights,
    required _TypographyLetterSpacing letterSpacing,
  }) : headingFontFamily = fonts.headingFontFamily,
       bodyFontFamily = fonts.bodyFontFamily,
       monoFontFamily = fonts.monoFontFamily,
       fontSizeXs = sizes.small.fontSizeXs,
       fontSizeSm = sizes.small.fontSizeSm,
       fontSizeBase = sizes.small.fontSizeBase,
       fontSizeLg = sizes.small.fontSizeLg,
       fontSizeXl = sizes.small.fontSizeXl,
       fontSize2Xl = sizes.large.fontSize2Xl,
       fontSize3Xl = sizes.large.fontSize3Xl,
       fontSize4Xl = sizes.large.fontSize4Xl,
       fontSize5Xl = sizes.large.fontSize5Xl,
       fontWeightLight = weights.fontWeightLight,
       fontWeightRegular = weights.fontWeightRegular,
       fontWeightMedium = weights.fontWeightMedium,
       fontWeightSemibold = weights.fontWeightSemibold,
       fontWeightBold = weights.fontWeightBold,
       lineHeightXs = lineHeights.small.lineHeightXs,
       lineHeightSm = lineHeights.small.lineHeightSm,
       lineHeightBase = lineHeights.small.lineHeightBase,
       lineHeightLg = lineHeights.small.lineHeightLg,
       lineHeightXl = lineHeights.small.lineHeightXl,
       lineHeight2Xl = lineHeights.large.lineHeight2Xl,
       lineHeight3Xl = lineHeights.large.lineHeight3Xl,
       lineHeight4Xl = lineHeights.large.lineHeight4Xl,
       lineHeight5Xl = lineHeights.large.lineHeight5Xl,
       letterSpacingTight = letterSpacing.letterSpacingTight,
       letterSpacingNormal = letterSpacing.letterSpacingNormal,
       letterSpacingWide = letterSpacing.letterSpacingWide;

  /// Design-system standard typography scale.
  const new _standard()
    : headingFontFamily = 'Inter',
      bodyFontFamily = 'Inter',
      monoFontFamily = 'JetBrains Mono',
      fontSizeXs = _xsFont,
      fontSizeSm = _smFont,
      fontSizeBase = _baseFont,
      fontSizeLg = _lgFont,
      fontSizeXl = _xlFont,
      fontSize2Xl = _xl2Font,
      fontSize3Xl = _xl3Font,
      fontSize4Xl = _xl4Font,
      fontSize5Xl = _xl5Font,
      fontWeightLight = FontWeight.w300,
      fontWeightRegular = FontWeight.w400,
      fontWeightMedium = FontWeight.w500,
      fontWeightSemibold = FontWeight.w600,
      fontWeightBold = FontWeight.w700,
      lineHeightXs = _xsLine,
      lineHeightSm = _smLine,
      lineHeightBase = _baseLine,
      lineHeightLg = _lgLine,
      lineHeightXl = _xlLine,
      lineHeight2Xl = _xl2Line,
      lineHeight3Xl = _xl3Line,
      lineHeight4Xl = _xl4Line,
      lineHeight5Xl = _xl5Line,
      letterSpacingTight = -_wideLetterSpacing,
      letterSpacingNormal = _normalLetterSpacing,
      letterSpacingWide = _wideLetterSpacing;

  /// Font family for headings and display text.
  final String headingFontFamily;

  /// Font family for body text and content.
  final String bodyFontFamily;

  /// Monospace font family for code and technical content.
  final String monoFontFamily;

  // Font sizes (logical pixels).

  /// Extra small font size (12px).
  final double fontSizeXs;

  /// Small font size (14px).
  final double fontSizeSm;

  /// Base font size (16px).
  final double fontSizeBase;

  /// Large font size (18px).
  final double fontSizeLg;

  /// Extra large font size (20px).
  final double fontSizeXl;

  /// 2X large font size (24px).
  final double fontSize2Xl;

  /// 3X large font size (30px).
  final double fontSize3Xl;

  /// 4X large font size (36px).
  final double fontSize4Xl;

  /// Wide letter spacing (0.025).
  final double letterSpacingWide;

  // Font weights.

  /// Light font weight (300).
  final FontWeight fontWeightLight;

  /// Regular font weight (400).
  final FontWeight fontWeightRegular;

  /// Medium font weight (500).
  final FontWeight fontWeightMedium;

  /// Semibold font weight (600).
  final FontWeight fontWeightSemibold;

  /// Bold font weight (700).
  final FontWeight fontWeightBold;

  // Line heights.

  /// Extra small line height (1.2).
  final double lineHeightXs;

  /// Tight line height (1.25).
  final double lineHeightSm;

  /// Base line height (1.5).
  final double lineHeightBase;

  /// Large line height (1.55).
  final double lineHeightLg;

  /// Extra large line height (1.6).
  final double lineHeightXl;

  /// 2X large line height (1.3).
  final double lineHeight2Xl;

  /// 3X large line height (1.2).
  final double lineHeight3Xl;

  /// 4X large line height (1.1).
  final double lineHeight4Xl;

  /// 5X large line height (1.0).
  final double lineHeight5Xl;

  // Letter spacing.

  /// Tight letter spacing (-0.025).
  final double letterSpacingTight;

  /// Normal letter spacing (0).
  final double letterSpacingNormal;

  /// 5X large font size (48px).
  final double fontSize5Xl;

  /// Linearly interpolate between two typography scales.
  AuraTypographyScale lerp(AuraTypographyScale other, double t) {
    if (t <= 0) return this;
    if (t >= 1) return other;

    return AuraTypographyScale._fromLerpGroups(
      fonts: _lerpTypographyFonts(this, other, t),
      sizes: _lerpTypographySizes(this, other, t),
      weights: _lerpTypographyWeights(this, other, t),
      lineHeights: _lerpTypographyLineHeights(this, other, t),
      letterSpacing: _lerpTypographyLetterSpacing(this, other, t),
    );
  }
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

_SpacingLerpValues _lerpSpacingValues(
  AuraSpacingScale begin,
  AuraSpacingScale end,
  double t,
) => (
  core: _lerpSpacingCoreValues(begin, end, t),
  extended: _lerpSpacingExtendedValues(begin, end, t),
);

_SpacingCoreLerpValues _lerpSpacingCoreValues(
  AuraSpacingScale begin,
  AuraSpacingScale end,
  double t,
) => (
  none: _lerpDouble(begin.none, end.none, t),
  base: _lerpDouble(begin.base, end.base, t),
  xs: _lerpDouble(begin.xs, end.xs, t),
  sm: _lerpDouble(begin.sm, end.sm, t),
  md: _lerpDouble(begin.md, end.md, t),
);

_SpacingExtendedLerpValues _lerpSpacingExtendedValues(
  AuraSpacingScale begin,
  AuraSpacingScale end,
  double t,
) => (
  lg: _lerpDouble(begin.lg, end.lg, t),
  xl: _lerpDouble(begin.xl, end.xl, t),
  xl2: _lerpDouble(begin.xl2, end.xl2, t),
  xl3: _lerpDouble(begin.xl3, end.xl3, t),
);

_BorderRadiusLerpValues _lerpBorderRadiusValues(
  AuraBorderRadiusScale begin,
  AuraBorderRadiusScale end,
  double t,
) => (
  core: _lerpBorderRadiusCoreValues(begin, end, t),
  extended: _lerpBorderRadiusExtendedValues(begin, end, t),
);

_BorderRadiusCoreLerpValues _lerpBorderRadiusCoreValues(
  AuraBorderRadiusScale begin,
  AuraBorderRadiusScale end,
  double t,
) => (
  none: _lerpDouble(begin.none, end.none, t),
  sm: _lerpDouble(begin.sm, end.sm, t),
  md: _lerpDouble(begin.md, end.md, t),
);

_BorderRadiusExtendedLerpValues _lerpBorderRadiusExtendedValues(
  AuraBorderRadiusScale begin,
  AuraBorderRadiusScale end,
  double t,
) => (
  lg: _lerpDouble(begin.lg, end.lg, t),
  xl: _lerpDouble(begin.xl, end.xl, t),
  full: _lerpDouble(begin.full, end.full, t),
);

_SurfaceCoreLerpValues _lerpSurfaceCoreValues(
  AuraColorScheme begin,
  AuraColorScheme end,
  double t,
) => (
  surface: _lerpColor(begin.surface, end.surface, t),
  surfaceVariant: _lerpColor(begin.surfaceVariant, end.surfaceVariant, t),
  onSurface: _lerpColor(begin.onSurface, end.onSurface, t),
  onSurfaceVariant: _lerpColor(begin.onSurfaceVariant, end.onSurfaceVariant, t),
);

_SurfaceBackgroundLerpValues _lerpSurfaceBackgroundValues(
  AuraColorScheme begin,
  AuraColorScheme end,
  double t,
) => (
  background: _lerpColor(begin.background, end.background, t),
  onBackground: _lerpColor(begin.onBackground, end.onBackground, t),
);

_TypographyFonts _lerpTypographyFonts(
  AuraTypographyScale begin,
  AuraTypographyScale end,
  double t,
) => (
  headingFontFamily: t < AuraTypographyScale._halfway
      ? begin.headingFontFamily
      : end.headingFontFamily,
  bodyFontFamily: t < AuraTypographyScale._halfway
      ? begin.bodyFontFamily
      : end.bodyFontFamily,
  monoFontFamily: t < AuraTypographyScale._halfway
      ? begin.monoFontFamily
      : end.monoFontFamily,
);

_TypographySizes _lerpTypographySizes(
  AuraTypographyScale begin,
  AuraTypographyScale end,
  double t,
) => (
  small: _lerpTypographySmallSizes(begin, end, t),
  large: _lerpTypographyLargeSizes(begin, end, t),
);

_TypographySmallSizes _lerpTypographySmallSizes(
  AuraTypographyScale begin,
  AuraTypographyScale end,
  double t,
) => (
  fontSizeXs: _lerpDouble(begin.fontSizeXs, end.fontSizeXs, t),
  fontSizeSm: _lerpDouble(begin.fontSizeSm, end.fontSizeSm, t),
  fontSizeBase: _lerpDouble(begin.fontSizeBase, end.fontSizeBase, t),
  fontSizeLg: _lerpDouble(begin.fontSizeLg, end.fontSizeLg, t),
  fontSizeXl: _lerpDouble(begin.fontSizeXl, end.fontSizeXl, t),
);

_TypographyLargeSizes _lerpTypographyLargeSizes(
  AuraTypographyScale begin,
  AuraTypographyScale end,
  double t,
) => (
  fontSize2Xl: _lerpDouble(begin.fontSize2Xl, end.fontSize2Xl, t),
  fontSize3Xl: _lerpDouble(begin.fontSize3Xl, end.fontSize3Xl, t),
  fontSize4Xl: _lerpDouble(begin.fontSize4Xl, end.fontSize4Xl, t),
  fontSize5Xl: _lerpDouble(begin.fontSize5Xl, end.fontSize5Xl, t),
);

_TypographyWeights _lerpTypographyWeights(
  AuraTypographyScale begin,
  AuraTypographyScale end,
  double t,
) => (
  fontWeightLight: _lerpFontWeight(
    begin.fontWeightLight,
    end.fontWeightLight,
    t,
  ),
  fontWeightRegular: _lerpFontWeight(
    begin.fontWeightRegular,
    end.fontWeightRegular,
    t,
  ),
  fontWeightMedium: _lerpFontWeight(
    begin.fontWeightMedium,
    end.fontWeightMedium,
    t,
  ),
  fontWeightSemibold: _lerpFontWeight(
    begin.fontWeightSemibold,
    end.fontWeightSemibold,
    t,
  ),
  fontWeightBold: _lerpFontWeight(begin.fontWeightBold, end.fontWeightBold, t),
);

_TypographyLineHeights _lerpTypographyLineHeights(
  AuraTypographyScale begin,
  AuraTypographyScale end,
  double t,
) => (
  small: _lerpTypographySmallLineHeights(begin, end, t),
  large: _lerpTypographyLargeLineHeights(begin, end, t),
);

_TypographySmallLineHeights _lerpTypographySmallLineHeights(
  AuraTypographyScale begin,
  AuraTypographyScale end,
  double t,
) => (
  lineHeightXs: _lerpDouble(begin.lineHeightXs, end.lineHeightXs, t),
  lineHeightSm: _lerpDouble(begin.lineHeightSm, end.lineHeightSm, t),
  lineHeightBase: _lerpDouble(begin.lineHeightBase, end.lineHeightBase, t),
  lineHeightLg: _lerpDouble(begin.lineHeightLg, end.lineHeightLg, t),
  lineHeightXl: _lerpDouble(begin.lineHeightXl, end.lineHeightXl, t),
);

_TypographyLargeLineHeights _lerpTypographyLargeLineHeights(
  AuraTypographyScale begin,
  AuraTypographyScale end,
  double t,
) => (
  lineHeight2Xl: _lerpDouble(begin.lineHeight2Xl, end.lineHeight2Xl, t),
  lineHeight3Xl: _lerpDouble(begin.lineHeight3Xl, end.lineHeight3Xl, t),
  lineHeight4Xl: _lerpDouble(begin.lineHeight4Xl, end.lineHeight4Xl, t),
  lineHeight5Xl: _lerpDouble(begin.lineHeight5Xl, end.lineHeight5Xl, t),
);

_TypographyLetterSpacing _lerpTypographyLetterSpacing(
  AuraTypographyScale begin,
  AuraTypographyScale end,
  double t,
) => (
  letterSpacingTight: _lerpDouble(
    begin.letterSpacingTight,
    end.letterSpacingTight,
    t,
  ),
  letterSpacingNormal: _lerpDouble(
    begin.letterSpacingNormal,
    end.letterSpacingNormal,
    t,
  ),
  letterSpacingWide: _lerpDouble(
    begin.letterSpacingWide,
    end.letterSpacingWide,
    t,
  ),
);

FontWeight _lerpFontWeight(FontWeight a, FontWeight b, double t) {
  return FontWeight.lerp(a, b, t) ?? (t < AuraTypographyScale._halfway ? a : b);
}

_BrandLerpValues _lerpBrandValues(
  AuraColorScheme begin,
  AuraColorScheme end,
  double t,
) => (
  primary: _lerpPrimaryValues(begin, end, t),
  secondary: _lerpSecondaryValues(begin, end, t),
  tertiary: _lerpTertiaryValues(begin, end, t),
);

_ColorTripletLerpValues _lerpPrimaryValues(
  AuraColorScheme begin,
  AuraColorScheme end,
  double t,
) => _lerpColorTriplet(
  begin.primary,
  begin.primaryVariant,
  begin.onPrimary,
  end.primary,
  end.primaryVariant,
  end.onPrimary,
  t,
);

_ColorTripletLerpValues _lerpSecondaryValues(
  AuraColorScheme begin,
  AuraColorScheme end,
  double t,
) => _lerpColorTriplet(
  begin.secondary,
  begin.secondaryVariant,
  begin.onSecondary,
  end.secondary,
  end.secondaryVariant,
  end.onSecondary,
  t,
);

_ColorTripletLerpValues _lerpTertiaryValues(
  AuraColorScheme begin,
  AuraColorScheme end,
  double t,
) => _lerpColorTriplet(
  begin.tertiary,
  begin.tertiaryVariant,
  begin.onTertiary,
  end.tertiary,
  end.tertiaryVariant,
  end.onTertiary,
  t,
);

_ColorTripletLerpValues _lerpColorTriplet(
  Color primary,
  Color primaryVariant,
  Color onPrimary,
  Color otherPrimary,
  Color otherPrimaryVariant,
  Color otherOnPrimary,
  double t,
) => (
  primary: _lerpColor(primary, otherPrimary, t),
  primaryVariant: _lerpColor(primaryVariant, otherPrimaryVariant, t),
  onPrimary: _lerpColor(onPrimary, otherOnPrimary, t),
);

_SurfaceLerpValues _lerpSurfaceValues(
  AuraColorScheme begin,
  AuraColorScheme end,
  double t,
) => (
  core: _lerpSurfaceCoreValues(begin, end, t),
  background: _lerpSurfaceBackgroundValues(begin, end, t),
);

_ColorPairLerpValues _lerpPair(
  Color value,
  Color onValue,
  Color otherValue,
  Color otherOnValue,
  double t,
) => (
  value: _lerpColor(value, otherValue, t),
  onValue: _lerpColor(onValue, otherOnValue, t),
);

_ChromeLerpValues _lerpChromeValues(
  AuraColorScheme begin,
  AuraColorScheme end,
  double t,
) => (
  outline: _lerpColor(begin.outline, end.outline, t),
  outlineVariant: _lerpColor(begin.outlineVariant, end.outlineVariant, t),
  shadow: _lerpColor(begin.shadow, end.shadow, t),
  scrim: _lerpColor(begin.scrim, end.scrim, t),
);

_ColorSchemeLerpValues _lerpColorSchemeValues(
  AuraColorScheme begin,
  AuraColorScheme end,
  double t,
) => (
  brand: _lerpBrandValues(begin, end, t),
  surface: _lerpSurfaceValues(begin, end, t),
  status: _lerpStatusValues(begin, end, t),
  chrome: _lerpChromeValues(begin, end, t),
);

_StatusLerpValues _lerpStatusValues(
  AuraColorScheme begin,
  AuraColorScheme end,
  double t,
) => (
  primary: _lerpStatusPrimaryValues(begin, end, t),
  secondary: _lerpStatusSecondaryValues(begin, end, t),
);

_StatusPrimaryLerpValues _lerpStatusPrimaryValues(
  AuraColorScheme begin,
  AuraColorScheme end,
  double t,
) => (
  error: _lerpPair(begin.error, begin.onError, end.error, end.onError, t),
  warning: _lerpPair(
    begin.warning,
    begin.onWarning,
    end.warning,
    end.onWarning,
    t,
  ),
);

_StatusSecondaryLerpValues _lerpStatusSecondaryValues(
  AuraColorScheme begin,
  AuraColorScheme end,
  double t,
) => (
  success: _lerpPair(
    begin.success,
    begin.onSuccess,
    end.success,
    end.onSuccess,
    t,
  ),
  info: _lerpPair(begin.info, begin.onInfo, end.info, end.onInfo, t),
);

Color _lerpColor(Color begin, Color end, double t) =>
    Color.lerp(begin, end, t) ?? begin;

/// Color scheme that adapts to light and dark themes.
@immutable
class AuraColorScheme {
  static const _lightnessLight = 0.45;
  static const _lightnessDark = 0.4;
  static const _standardChroma = 0.2;

  /// Creates a [AuraColorScheme] with the specified colors.
  const new({
    required this.primary,
    required this.primaryVariant,
    required this.onPrimary,
    required this.secondary,
    required this.secondaryVariant,
    required this.onSecondary,
    required this.tertiary,
    required this.tertiaryVariant,
    required this.onTertiary,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.onError,
    required this.warning,
    required this.onWarning,
    required this.success,
    required this.onSuccess,
    required this.info,
    required this.onInfo,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
  });

  new _fromLerpGroups(_ColorSchemeLerpValues values)
    : primary = values.brand.primary.primary,
      primaryVariant = values.brand.primary.primaryVariant,
      onPrimary = values.brand.primary.onPrimary,
      secondary = values.brand.secondary.primary,
      secondaryVariant = values.brand.secondary.primaryVariant,
      onSecondary = values.brand.secondary.onPrimary,
      tertiary = values.brand.tertiary.primary,
      tertiaryVariant = values.brand.tertiary.primaryVariant,
      onTertiary = values.brand.tertiary.onPrimary,
      surface = values.surface.core.surface,
      surfaceVariant = values.surface.core.surfaceVariant,
      onSurface = values.surface.core.onSurface,
      onSurfaceVariant = values.surface.core.onSurfaceVariant,
      background = values.surface.background.background,
      onBackground = values.surface.background.onBackground,
      error = values.status.primary.error.value,
      onError = values.status.primary.error.onValue,
      warning = values.status.primary.warning.value,
      onWarning = values.status.primary.warning.onValue,
      success = values.status.secondary.success.value,
      onSuccess = values.status.secondary.success.onValue,
      info = values.status.secondary.info.value,
      onInfo = values.status.secondary.info.onValue,
      outline = values.chrome.outline,
      outlineVariant = values.chrome.outlineVariant,
      shadow = values.chrome.shadow,
      scrim = values.chrome.scrim;

  /// Creates a light color scheme.
  new _light()
    : primary = DesignColors.primaryBase,
      primaryVariant = DesignColors.primaryDark,
      onPrimary = DesignColors.primaryContrast,
      secondary = DesignColors.secondaryBase,
      secondaryVariant = DesignColors.secondaryDark,
      onSecondary = DesignColors.secondaryContrast,
      tertiary = DesignColors.accentBase,
      tertiaryVariant = DesignColors.accentDark,
      onTertiary = DesignColors.accentContrast,
      surface = DesignColors.neutral50,
      surfaceVariant = const Color(0xFFFFFFFF),
      onSurface = DesignColors.neutral900,
      onSurfaceVariant = DesignColors.neutral700,
      background = DesignColors.neutral100,
      onBackground = DesignColors.neutral900,
      error = OKLCHColor(
        hue: HueColorValues.error,
        lightness: _lightnessLight,
        chroma: _standardChroma,
      ).toColor(),
      onError = const Color(0xFFFFFFFF),
      warning = OKLCHColor(
        hue: HueColorValues.warning,
        lightness: _lightnessLight,
        chroma: _standardChroma,
      ).toColor(),
      onWarning = const Color(0xFFFFFFFF),
      success = OKLCHColor(
        hue: HueColorValues.success,
        lightness: _lightnessLight,
        chroma: _standardChroma,
      ).toColor(),
      onSuccess = const Color(0xFFFFFFFF),
      info = OKLCHColor(
        hue: HueColorValues.info,
        lightness: _lightnessLight,
        chroma: _standardChroma,
      ).toColor(),
      onInfo = const Color(0xFFFFFFFF),
      outline = DesignColors.neutral300,
      outlineVariant = DesignColors.neutral200,
      shadow = DesignColors.neutral900,
      scrim = const Color(0x80000000);

  /// Creates a dark color scheme.
  new _dark()
    : primary = DesignColors.primaryLight,
      primaryVariant = DesignColors.primaryBase,
      onPrimary = Colors.black,
      secondary = DesignColors.secondaryLight,
      secondaryVariant = DesignColors.secondaryBase,
      onSecondary = Colors.black,
      tertiary = DesignColors.accentLight,
      tertiaryVariant = DesignColors.accentBase,
      onTertiary = Colors.black,
      surface = DesignColors.neutral800,
      surfaceVariant = DesignColors.neutral700,
      onSurface = DesignColors.neutral100,
      onSurfaceVariant = DesignColors.neutral300,
      background = DesignColors.neutral900,
      onBackground = DesignColors.neutral100,
      error = OKLCHColor(
        hue: HueColorValues.error,
        lightness: _lightnessDark,
        chroma: _standardChroma,
      ).toColor(),
      onError = Colors.white,
      warning = OKLCHColor(
        hue: HueColorValues.warning,
        lightness: _lightnessDark,
        chroma: _standardChroma,
      ).toColor(),
      onWarning = Colors.white,
      success = OKLCHColor(
        hue: HueColorValues.success,
        lightness: _lightnessDark,
        chroma: _standardChroma,
      ).toColor(),
      onSuccess = Colors.white,
      info = OKLCHColor(
        hue: HueColorValues.info,
        lightness: _lightnessDark,
        chroma: _standardChroma,
      ).toColor(),
      onInfo = Colors.white,
      outline = DesignColors.neutral600,
      outlineVariant = DesignColors.neutral700,
      shadow = const Color(0xFF000000),
      scrim = const Color(0xB3000000);

  /// Variant of the tertiary color.
  final Color tertiaryVariant;

  /// Variant of the primary color for highlights.
  final Color primaryVariant;

  /// Color for text/icons on primary color.
  final Color onPrimary;

  /// Secondary color for accents.
  final Color secondary;

  /// Variant of the secondary color.
  final Color secondaryVariant;

  /// Color for text/icons on secondary color.
  final Color onSecondary;

  /// Tertiary color for accents.
  final Color tertiary;

  /// Primary color for main UI elements.
  final Color primary;

  /// Color for text/icons on tertiary color.
  final Color onTertiary;

  /// Background color for cards, sheets.
  final Color surface;

  /// Variant surface color.
  final Color surfaceVariant;

  /// Color for text/icons on surface.
  final Color onSurface;

  /// Color for text/icons on surface variants.
  final Color onSurfaceVariant;

  /// Background color for the app.
  final Color background;

  /// Color for text/icons on background.
  final Color onBackground;

  /// Error color.
  final Color error;

  /// Color for text/icons on error color.
  final Color onError;

  /// Warning color.
  final Color warning;

  /// Color for text/icons on warning color.
  final Color onWarning;

  /// Scrim color for overlays.
  final Color scrim;

  /// Color for text/icons on success color.
  final Color onSuccess;

  /// Info color.
  final Color info;

  /// Color for text/icons on info color.
  final Color onInfo;

  /// Outline color for borders.
  final Color outline;

  /// Variant outline color.
  final Color outlineVariant;

  /// Shadow color.
  final Color shadow;

  /// Success color.
  final Color success;

  /// Default foreground color.
  Color get foreground => onBackground;

  /// Default foreground color for surface elements.
  Color get foregroundOnSurface => onSurface;

  /// Muted foreground color for secondary text and icons.
  Color get mutedForeground => onSurfaceVariant;

  /// Linearly interpolate between two color schemes.
  AuraColorScheme lerp(AuraColorScheme other, double t) {
    return AuraColorScheme._fromLerpGroups(
      _lerpColorSchemeValues(this, other, t),
    );
  }

  /// Resolve a user-selectable tint.
  Color colorFor(AuraTint tint) {
    return switch (tint) {
      .primary => primary,
      .secondary => secondary,
      .tertiary => tertiary,
      .error => error,
      .warning => warning,
      .success => success,
      .info => info,
    };
  }

  /// Resolve readable foreground for a user-selectable tint.
  Color onTint(AuraTint tint) {
    return switch (tint) {
      .primary => onPrimary,
      .secondary => onSecondary,
      .tertiary => onTertiary,
      .error => onError,
      .warning => onWarning,
      .success => onSuccess,
      .info => onInfo,
    };
  }
}

/// Animation theme that provides consistent timing values.
///
/// Defines animation durations (fast, normal, slow) to ensure
/// cohesive motion design across the application.
@immutable
class AuraAnimationTheme {
  /// Creates an animation theme with the specified values.
  const new({
    this.fast = DesignDuration.fast,
    this.normal = DesignDuration.normal,
    this.slow = DesignDuration.slow,
  });

  /// Creates the standard animation theme.
  const new _standard()
    : fast = DesignDuration.fast,
      normal = DesignDuration.normal,
      slow = DesignDuration.slow;

  /// Fast animation duration (150ms) for quick transitions and
  /// micro-interactions.
  final Duration fast;

  /// Normal animation duration (200ms) for standard transitions and
  /// state changes.
  final Duration normal;

  /// Slow animation duration (300ms) for deliberate animations and
  /// page transitions.
  final Duration slow;

  /// Linearly interpolate between two animation themes.
  AuraAnimationTheme lerp(AuraAnimationTheme other, double t) {
    // Animation durations don't interpolate, return this or other based on t.
    return t < AuraTypographyScale._halfway ? this : other;
  }
}

/// Extension to get Aura theme from BuildContext.
extension AuraThemeExtension on BuildContext {
  /// Get the current Aura theme.
  AuraTheme get auraTheme =>
      Theme.of(this).extension<AuraTheme>() ?? AuraTheme.light;

  /// Get the current Aura color scheme.
  AuraColorScheme get auraColors => auraTheme.colors;
}
