// Required: Existing test and UI helpers keep compact return flow.
// Required: UI package exposes top-level helpers and constants.

import 'package:auravibes_ui/src/colors/value_color.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// Aura theme extension that provides theme-aware design tokens.
///
/// Colors, spacing, border radius, and typography all live here so a subtree
/// `Theme` override can rescale them. Call sites select values via the
/// AuraSpacing / AuraBorderRadius enums (and AuraTextStyle for type), resolved
/// at build time through [fromSpacing] / [fromBorderRadius] / [typography].
@immutable
class AuraTheme extends ThemeExtension<AuraTheme> {
  /// Creates a Aura theme extension.
  const AuraTheme({
    required this.colors,
    required this.animation,
    this.spacing = const AuraSpacingScale._standard(),
    this.borderRadius = const AuraBorderRadiusScale._standard(),
    this.typography = const AuraTypographyScale._standard(),
  });

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
  static const _standardAnimation = AuraAnimationTheme._standard();

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

/// Theme-owned spacing scale: one [double] per [AuraSpacing] step.
///
/// Values are absent from the [AuraSpacing] enum on purpose so a subtree
/// `Theme` override can rescale spacing. [AuraSpacingScale._standard] carries
/// the design-system defaults (base unit 16px).
@immutable
class AuraSpacingScale {
  /// Creates a spacing scale.
  const AuraSpacingScale({
    this.none = 0,
    this.base = 16,
    this.xs = 4,
    this.sm = 8,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xl2 = 48,
    this.xl3 = 64,
  });

  /// Design-system standard spacing scale.
  const AuraSpacingScale._standard()
    : none = 0,
      base = 16,
      xs = 4,
      sm = 8,
      md = 16,
      lg = 24,
      xl = 32,
      xl2 = 48,
      xl3 = 64;

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

    return AuraSpacingScale(
      none: _lerpDouble(none, other.none, t),
      base: _lerpDouble(base, other.base, t),
      xs: _lerpDouble(xs, other.xs, t),
      sm: _lerpDouble(sm, other.sm, t),
      md: _lerpDouble(md, other.md, t),
      lg: _lerpDouble(lg, other.lg, t),
      xl: _lerpDouble(xl, other.xl, t),
      xl2: _lerpDouble(xl2, other.xl2, t),
      xl3: _lerpDouble(xl3, other.xl3, t),
    );
  }
}

/// Theme-owned border-radius scale: one [double] per [AuraBorderRadius] step.
@immutable
class AuraBorderRadiusScale {
  /// Creates a border-radius scale.
  const AuraBorderRadiusScale({
    this.none = 0,
    this.sm = 2,
    this.md = 6,
    this.lg = 8,
    this.xl = 16,
    this.full = 9999,
  });

  /// Design-system standard border-radius scale.
  const AuraBorderRadiusScale._standard()
    : none = 0,
      sm = 2,
      md = 6,
      lg = 8,
      xl = 16,
      full = 9999;

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

    return AuraBorderRadiusScale(
      none: _lerpDouble(none, other.none, t),
      sm: _lerpDouble(sm, other.sm, t),
      md: _lerpDouble(md, other.md, t),
      lg: _lerpDouble(lg, other.lg, t),
      xl: _lerpDouble(xl, other.xl, t),
      full: _lerpDouble(full, other.full, t),
    );
  }
}

/// Theme-owned typography scale: font sizes, weights, line heights, letter
/// spacings, and font families.
///
/// Font families are strings and do not interpolate; [lerp] picks the source
/// or target family at the halfway point (mirroring [AuraAnimationTheme]).
@immutable
class AuraTypographyScale {
  /// Creates a typography scale.
  const AuraTypographyScale({
    this.headingFontFamily = 'Inter',
    this.bodyFontFamily = 'Inter',
    this.monoFontFamily = 'JetBrains Mono',
    this.fontSizeXs = 12,
    this.fontSizeSm = 14,
    this.fontSizeBase = 16,
    this.fontSizeLg = 18,
    this.fontSizeXl = 20,
    this.fontSize2Xl = 24,
    this.fontSize3Xl = 30,
    this.fontSize4Xl = 36,
    this.fontSize5Xl = 48,
    this.fontWeightLight = FontWeight.w300,
    this.fontWeightRegular = FontWeight.w400,
    this.fontWeightMedium = FontWeight.w500,
    this.fontWeightSemibold = FontWeight.w600,
    this.fontWeightBold = FontWeight.w700,
    this.lineHeightXs = 1.2,
    this.lineHeightSm = 1.25,
    this.lineHeightBase = 1.5,
    this.lineHeightLg = 1.55,
    this.lineHeightXl = 1.6,
    this.lineHeight2Xl = 1.3,
    this.lineHeight3Xl = 1.2,
    this.lineHeight4Xl = 1.1,
    this.lineHeight5Xl = 1,
    this.letterSpacingTight = -0.025,
    this.letterSpacingNormal = 0,
    this.letterSpacingWide = 0.025,
  });

  /// Design-system standard typography scale.
  const AuraTypographyScale._standard()
    : headingFontFamily = 'Inter',
      bodyFontFamily = 'Inter',
      monoFontFamily = 'JetBrains Mono',
      fontSizeXs = 12,
      fontSizeSm = 14,
      fontSizeBase = 16,
      fontSizeLg = 18,
      fontSizeXl = 20,
      fontSize2Xl = 24,
      fontSize3Xl = 30,
      fontSize4Xl = 36,
      fontSize5Xl = 48,
      fontWeightLight = FontWeight.w300,
      fontWeightRegular = FontWeight.w400,
      fontWeightMedium = FontWeight.w500,
      fontWeightSemibold = FontWeight.w600,
      fontWeightBold = FontWeight.w700,
      lineHeightXs = 1.2,
      lineHeightSm = 1.25,
      lineHeightBase = 1.5,
      lineHeightLg = 1.55,
      lineHeightXl = 1.6,
      lineHeight2Xl = 1.3,
      lineHeight3Xl = 1.2,
      lineHeight4Xl = 1.1,
      lineHeight5Xl = 1,
      letterSpacingTight = -0.025,
      letterSpacingNormal = 0,
      letterSpacingWide = 0.025;

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

  /// 5X large font size (48px).
  final double fontSize5Xl;

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

  /// Wide letter spacing (0.025).
  final double letterSpacingWide;

  /// Linearly interpolate between two typography scales.
  AuraTypographyScale lerp(AuraTypographyScale other, double t) {
    if (t <= 0) return this;
    if (t >= 1) return other;

    return AuraTypographyScale(
      headingFontFamily: t < 0.5 ? headingFontFamily : other.headingFontFamily,
      bodyFontFamily: t < 0.5 ? bodyFontFamily : other.bodyFontFamily,
      monoFontFamily: t < 0.5 ? monoFontFamily : other.monoFontFamily,
      fontSizeXs: _lerpDouble(fontSizeXs, other.fontSizeXs, t),
      fontSizeSm: _lerpDouble(fontSizeSm, other.fontSizeSm, t),
      fontSizeBase: _lerpDouble(fontSizeBase, other.fontSizeBase, t),
      fontSizeLg: _lerpDouble(fontSizeLg, other.fontSizeLg, t),
      fontSizeXl: _lerpDouble(fontSizeXl, other.fontSizeXl, t),
      fontSize2Xl: _lerpDouble(fontSize2Xl, other.fontSize2Xl, t),
      fontSize3Xl: _lerpDouble(fontSize3Xl, other.fontSize3Xl, t),
      fontSize4Xl: _lerpDouble(fontSize4Xl, other.fontSize4Xl, t),
      fontSize5Xl: _lerpDouble(fontSize5Xl, other.fontSize5Xl, t),
      fontWeightLight: _lerpFontWeight(
        fontWeightLight,
        other.fontWeightLight,
        t,
      ),
      fontWeightRegular: _lerpFontWeight(
        fontWeightRegular,
        other.fontWeightRegular,
        t,
      ),
      fontWeightMedium: _lerpFontWeight(
        fontWeightMedium,
        other.fontWeightMedium,
        t,
      ),
      fontWeightSemibold: _lerpFontWeight(
        fontWeightSemibold,
        other.fontWeightSemibold,
        t,
      ),
      fontWeightBold: _lerpFontWeight(
        fontWeightBold,
        other.fontWeightBold,
        t,
      ),
      lineHeightXs: _lerpDouble(lineHeightXs, other.lineHeightXs, t),
      lineHeightSm: _lerpDouble(lineHeightSm, other.lineHeightSm, t),
      lineHeightBase: _lerpDouble(lineHeightBase, other.lineHeightBase, t),
      lineHeightLg: _lerpDouble(lineHeightLg, other.lineHeightLg, t),
      lineHeightXl: _lerpDouble(lineHeightXl, other.lineHeightXl, t),
      lineHeight2Xl: _lerpDouble(lineHeight2Xl, other.lineHeight2Xl, t),
      lineHeight3Xl: _lerpDouble(lineHeight3Xl, other.lineHeight3Xl, t),
      lineHeight4Xl: _lerpDouble(lineHeight4Xl, other.lineHeight4Xl, t),
      lineHeight5Xl: _lerpDouble(lineHeight5Xl, other.lineHeight5Xl, t),
      letterSpacingTight: _lerpDouble(
        letterSpacingTight,
        other.letterSpacingTight,
        t,
      ),
      letterSpacingNormal: _lerpDouble(
        letterSpacingNormal,
        other.letterSpacingNormal,
        t,
      ),
      letterSpacingWide: _lerpDouble(
        letterSpacingWide,
        other.letterSpacingWide,
        t,
      ),
    );
  }
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

FontWeight _lerpFontWeight(FontWeight a, FontWeight b, double t) {
  return FontWeight.lerp(a, b, t) ?? (t < 0.5 ? a : b);
}

/// Color scheme that adapts to light and dark themes.
@immutable
class AuraColorScheme {
  /// Creates a [AuraColorScheme] with the specified colors.
  const AuraColorScheme({
    required this.primary,
    required this.primaryVariant,
    required this.onPrimary,
    required this.secondary,
    required this.secondaryVariant,
    required this.onSecondary,
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

  /// Creates a light color scheme.
  AuraColorScheme._light()
    : primary = DesignColors.primaryBase,
      primaryVariant = DesignColors.primaryDark,
      onPrimary = DesignColors.primaryContrast,
      secondary = DesignColors.secondaryBase,
      secondaryVariant = DesignColors.secondaryDark,
      onSecondary = DesignColors.secondaryContrast,
      surface = DesignColors.neutral50,
      surfaceVariant = const Color(0xFFFFFFFF),
      onSurface = DesignColors.neutral900,
      onSurfaceVariant = DesignColors.neutral700,
      background = DesignColors.neutral100,
      onBackground = DesignColors.neutral900,
      error = OKLCHColor(
        hue: HueColorValues.error,
        lightness: 0.6,
        chroma: 0.2,
      ).toColor(),
      onError = const Color(0xFFFFFFFF),
      warning = OKLCHColor(
        hue: HueColorValues.warning,
        lightness: 0.6,
        chroma: 0.2,
      ).toColor(),
      onWarning = const Color(0xFFFFFFFF),
      success = OKLCHColor(
        hue: HueColorValues.success,
        lightness: 0.6,
        chroma: 0.2,
      ).toColor(),
      onSuccess = const Color(0xFFFFFFFF),
      info = OKLCHColor(
        hue: HueColorValues.info,
        lightness: 0.6,
        chroma: 0.2,
      ).toColor(),
      onInfo = const Color(0xFFFFFFFF),
      outline = DesignColors.neutral300,
      outlineVariant = DesignColors.neutral200,
      shadow = DesignColors.neutral900,
      scrim = const Color(0x80000000);

  /// Creates a dark color scheme.
  AuraColorScheme._dark()
    : primary = DesignColors.primaryLight,
      primaryVariant = DesignColors.primaryBase,
      onPrimary = Colors.black,
      secondary = DesignColors.secondaryLight,
      secondaryVariant = DesignColors.secondaryBase,
      onSecondary = Colors.black,
      surface = DesignColors.neutral800,
      surfaceVariant = DesignColors.neutral700,
      onSurface = DesignColors.neutral100,
      onSurfaceVariant = DesignColors.neutral300,
      background = DesignColors.neutral900,
      onBackground = DesignColors.neutral100,
      error = OKLCHColor(
        hue: HueColorValues.error,
        lightness: 0.4,
        chroma: 0.2,
      ).toColor(),
      onError = Colors.black,
      warning = OKLCHColor(
        hue: HueColorValues.warning,
        lightness: 0.4,
        chroma: 0.2,
      ).toColor(),
      onWarning = Colors.black,
      success = OKLCHColor(
        hue: HueColorValues.success,
        lightness: 0.4,
        chroma: 0.2,
      ).toColor(),
      onSuccess = Colors.black,
      info = OKLCHColor(
        hue: HueColorValues.info,
        lightness: 0.4,
        chroma: 0.2,
      ).toColor(),
      onInfo = Colors.black,
      outline = DesignColors.neutral600,
      outlineVariant = DesignColors.neutral700,
      shadow = const Color(0xFF000000),
      scrim = const Color(0xB3000000);

  /// Primary color for main UI elements.
  final Color primary;

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

  /// Success color.
  final Color success;

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

  /// Scrim color for overlays.
  final Color scrim;

  /// Linearly interpolate between two color schemes.
  AuraColorScheme lerp(AuraColorScheme other, double t) {
    return AuraColorScheme(
      primary: _lerpColor(primary, other.primary, t),
      primaryVariant: _lerpColor(primaryVariant, other.primaryVariant, t),
      onPrimary: _lerpColor(onPrimary, other.onPrimary, t),
      secondary: _lerpColor(secondary, other.secondary, t),
      secondaryVariant: _lerpColor(
        secondaryVariant,
        other.secondaryVariant,
        t,
      ),
      onSecondary: _lerpColor(onSecondary, other.onSecondary, t),
      surface: _lerpColor(surface, other.surface, t),
      surfaceVariant: _lerpColor(surfaceVariant, other.surfaceVariant, t),
      onSurface: _lerpColor(onSurface, other.onSurface, t),
      onSurfaceVariant: _lerpColor(
        onSurfaceVariant,
        other.onSurfaceVariant,
        t,
      ),
      background: _lerpColor(background, other.background, t),
      onBackground: _lerpColor(onBackground, other.onBackground, t),
      error: _lerpColor(error, other.error, t),
      onError: _lerpColor(onError, other.onError, t),
      warning: _lerpColor(warning, other.warning, t),
      onWarning: _lerpColor(onWarning, other.onWarning, t),
      success: _lerpColor(success, other.success, t),
      onSuccess: _lerpColor(onSuccess, other.onSuccess, t),
      info: _lerpColor(info, other.info, t),
      onInfo: _lerpColor(onInfo, other.onInfo, t),
      outline: _lerpColor(outline, other.outline, t),
      outlineVariant: _lerpColor(outlineVariant, other.outlineVariant, t),
      shadow: _lerpColor(shadow, other.shadow, t),
      scrim: _lerpColor(scrim, other.scrim, t),
    );
  }

  Color _lerpColor(Color begin, Color end, double t) {
    return Color.lerp(begin, end, t) ?? begin;
  }

  /// Get color by variant nullable.
  Color? getColorOrNull(AuraColorVariant? variant) {
    if (variant == null) return null;

    return getColor(variant);
  }

  /// Get color by variant.
  Color getColor(AuraColorVariant variant) {
    return switch (variant) {
      AuraColorVariant.primary => primary,
      AuraColorVariant.onSurface => onSurface,
      AuraColorVariant.error => error,
      AuraColorVariant.onError => onError,
      AuraColorVariant.onSurfaceVariant => onSurfaceVariant,
      AuraColorVariant.surfaceVariant => surfaceVariant,
      AuraColorVariant.onPrimary => onPrimary,
      AuraColorVariant.secondary => secondary,
      AuraColorVariant.success => success,
      AuraColorVariant.warning => warning,
      AuraColorVariant.info => info,
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
  const AuraAnimationTheme({
    this.fast = DesignDuration.fast,
    this.normal = DesignDuration.normal,
    this.slow = DesignDuration.slow,
  });

  /// Creates the standard animation theme.
  const AuraAnimationTheme._standard()
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
    return t < 0.5 ? this : other;
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
