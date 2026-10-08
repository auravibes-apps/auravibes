import 'package:auravibes_ui/src/colors/aura_brightness.dart';
import 'package:auravibes_ui/src/colors/aura_color_range.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

typedef _ComputedBrandValues = ({
  _ComputedBrandPair primary,
  _ComputedBrandPair secondary,
  _ComputedBrandPair tertiary,
});

typedef _ComputedSurfaceValues = ({
  AuraComputedColor surface,
  AuraComputedColor surfaceVariant,
  AuraComputedColor background,
  AuraComputedColor outline,
  AuraComputedColor outlineVariant,
});

typedef _ComputedSemanticValues = ({
  AuraComputedColor error,
  AuraComputedColor warning,
  AuraComputedColor success,
  AuraComputedColor info,
});

typedef _ComputedBrandForegrounds = ({
  Color onPrimary,
  Color onSecondary,
  Color onTertiary,
});

typedef _ComputedSurfaceForegrounds = ({
  Color onSurface,
  Color onSurfaceVariant,
  Color onBackground,
});

typedef _ComputedSemanticForegrounds = ({
  Color onError,
  Color onWarning,
  Color onSuccess,
  Color onInfo,
});

typedef _ComputedForegroundValues = ({
  _ComputedBrandForegrounds brand,
  _ComputedSurfaceForegrounds surface,
  _ComputedSemanticForegrounds semantic,
});

typedef _ComputedForegroundRequest = ({
  _ComputedBrandValues brand,
  _ComputedSurfaceValues surface,
  _ComputedSemanticValues semantic,
  bool isLight,
});

typedef _ComputedPaletteValues = ({
  _ComputedBrandValues brand,
  _ComputedSurfaceValues surface,
  _ComputedSemanticValues semantic,
});

typedef _ComputedSchemeValues = ({
  _ComputedBrandValues brand,
  _ComputedSurfaceValues surface,
  _ComputedSemanticValues semantic,
  _ComputedForegroundValues foreground,
  Color shadow,
  Color scrim,
});

typedef _BrandColorRequest = ({
  double hue,
  bool isLight,
  double lightLightness,
  double darkLightness,
  double chroma,
  AuraColorRange range,
});

/// AuraColorScheme derived from a hue and brightness via OKLCH role ranges.
///
/// Brand colors follow `primaryHue`; the secondary hue is the complement
/// (`primaryHue + 180`). Semantic hues default to HueColorValues. Surfaces
/// stay neutral. Light mode uses near-white canvas with darker grouping;
/// dark mode raises groups above charcoal and uses pastel accents. Foregrounds
/// target WCAG 2.x 4.5 and absolute APCA Lc 60. Font size/weight need evaluation.
///
/// Lives alongside the base light/dark factories; those and AuraTheme.light /
/// AuraTheme.dark are unchanged.
///
/// ```dart
/// final scheme = AuraComputedColorScheme(
///   primaryHue: 180,
///   brightness: AuraBrightness.dark,
/// );
/// ```
class AuraComputedColorScheme extends AuraColorScheme {
  /// Computes color roles from [primaryHue] and [brightness].
  factory({required double primaryHue, required AuraBrightness brightness}) =>
      AuraComputedColorScheme._fromValues(
        _computedSchemeValues(primaryHue, brightness),
      );

  new _fromValues(_ComputedSchemeValues values)
    : super(
        primary: values.brand.primary.primary.toColor(),
        primaryVariant: values.brand.primary.variant.toColor(),
        onPrimary: values.foreground.brand.onPrimary,
        secondary: values.brand.secondary.primary.toColor(),
        secondaryVariant: values.brand.secondary.variant.toColor(),
        onSecondary: values.foreground.brand.onSecondary,
        tertiary: values.brand.tertiary.primary.toColor(),
        tertiaryVariant: values.brand.tertiary.variant.toColor(),
        onTertiary: values.foreground.brand.onTertiary,
        surface: values.surface.surface.toColor(),
        surfaceVariant: values.surface.surfaceVariant.toColor(),
        onSurface: values.foreground.surface.onSurface,
        onSurfaceVariant: values.foreground.surface.onSurfaceVariant,
        background: values.surface.background.toColor(),
        onBackground: values.foreground.surface.onBackground,
        error: values.semantic.error.toColor(),
        onError: values.foreground.semantic.onError,
        warning: values.semantic.warning.toColor(),
        onWarning: values.foreground.semantic.onWarning,
        success: values.semantic.success.toColor(),
        onSuccess: values.foreground.semantic.onSuccess,
        info: values.semantic.info.toColor(),
        onInfo: values.foreground.semantic.onInfo,
        outline: values.surface.outline.toColor(),
        outlineVariant: values.surface.outlineVariant.toColor(),
        shadow: values.shadow,
        scrim: values.scrim,
      );

  @override
  String toString() => 'AuraComputedColorScheme(primary: $primary)';
}

_ComputedSchemeValues _computedSchemeValues(
  double primaryHue,
  AuraBrightness brightness,
) {
  final isLight = brightness == AuraBrightness.light;
  final palette = _computedPaletteValues(primaryHue, isLight);

  return _computedSchemeValuesFromPalette(palette, isLight);
}

_ComputedPaletteValues _computedPaletteValues(
  double primaryHue,
  bool isLight,
) => (
  brand: _computedBrandValues(primaryHue, isLight),
  surface: _computedSurfaceValues(primaryHue, isLight),
  semantic: _computedSemanticValues(isLight),
);

_ComputedSchemeValues _computedSchemeValuesFromPalette(
  _ComputedPaletteValues palette,
  bool isLight,
) => _computedSchemeWithForeground(
  palette,
  _computedForegroundValues((
    brand: palette.brand,
    surface: palette.surface,
    semantic: palette.semantic,
    isLight: isLight,
  )),
  isLight,
);

_ComputedSchemeValues _computedSchemeWithForeground(
  _ComputedPaletteValues palette,
  _ComputedForegroundValues foreground,
  bool isLight,
) => (
  brand: palette.brand,
  surface: palette.surface,
  semantic: palette.semantic,
  foreground: foreground,
  shadow: _computedShadow,
  scrim: _computedScrim(isLight),
);

const _computedShadow = Color(0xFF000000);
const _brandVariantLightLightness = 0.48;
const _brandVariantChroma = 0.15;
const _backgroundDarkLightness = 0.2;
const _outlineLightness = 0.6;
const _outlineVariantDarkLightness = 0.58;

Color _computedScrim(bool isLight) =>
    isLight ? const Color(0x80000000) : const Color(0xB3000000);

_ComputedBrandValues _computedBrandValues(double primaryHue, bool isLight) {
  final secondaryHue = (primaryHue + 180) % 360;
  final tertiaryHue = (primaryHue + 60) % 360;
  final primary = _computedBrandPair(primaryHue, isLight);
  final secondary = _computedBrandPair(secondaryHue, isLight);
  final tertiary = _computedBrandPair(tertiaryHue, isLight);

  return (primary: primary, secondary: secondary, tertiary: tertiary);
}

typedef _ComputedBrandPair = ({
  AuraComputedColor primary,
  AuraComputedColor variant,
});

_ComputedBrandPair _computedBrandPair(double hue, bool isLight) => (
  primary: _brandColor(_primaryBrandRequest(hue, isLight)),
  variant: _brandColor(_variantBrandRequest(hue, isLight)),
);

_BrandColorRequest _primaryBrandRequest(double hue, bool isLight) => (
  hue: hue,
  isLight: isLight,
  lightLightness: 0.5,
  darkLightness: 0.86,
  chroma: isLight ? 0.17 : 0.12,
  range: isLight ? AuraColorRange.lightAction : AuraColorRange.darkPastel,
);

_BrandColorRequest _variantBrandRequest(double hue, bool isLight) => (
  hue: hue,
  isLight: isLight,
  lightLightness: _brandVariantLightLightness,
  darkLightness: 0.83,
  chroma: isLight ? _brandVariantChroma : 0.1,
  range: isLight ? AuraColorRange.lightAction : AuraColorRange.darkPastel,
);

AuraComputedColor _brandColor(_BrandColorRequest request) =>
    request.range.resolve(
      hue: request.hue,
      lightness: request.isLight
          ? request.lightLightness
          : request.darkLightness,
      chroma: request.chroma,
    );

_ComputedSurfaceValues _computedSurfaceValues(double primaryHue, bool isLight) {
  AuraComputedColor neutral(double lightLightness, double darkLightness) =>
      _computedColor(primaryHue, isLight ? lightLightness : darkLightness, 0);

  return (
    surface: neutral(0.97, 0.26),
    surfaceVariant: neutral(0.95, 0.3),
    background: neutral(0.99, _backgroundDarkLightness),
    outline: neutral(_outlineLightness, _outlineLightness),
    outlineVariant: neutral(0.62, _outlineVariantDarkLightness),
  );
}

_ComputedSemanticValues _computedSemanticValues(bool isLight) {
  AuraComputedColor semantic(double hue) =>
      _brandColor(_primaryBrandRequest(hue, isLight));

  return (
    error: semantic(HueColorValues.error),
    warning: semantic(HueColorValues.warning),
    success: semantic(HueColorValues.success),
    info: semantic(HueColorValues.info),
  );
}

_ComputedForegroundValues _computedForegroundValues(
  _ComputedForegroundRequest request,
) => (
  brand: _computedBrandForegrounds(request.brand, request.isLight),
  surface: _computedSurfaceForegrounds(request.surface, request.isLight),
  semantic: _computedSemanticForegrounds(request.semantic),
);

_ComputedBrandForegrounds _computedBrandForegrounds(
  _ComputedBrandValues brand,
  bool isLight,
) => (
  onPrimary: _computedBrandForeground(brand.primary, isLight),
  onSecondary: _computedBrandForeground(brand.secondary, isLight),
  onTertiary: _computedBrandForeground(brand.tertiary, isLight),
);

Color _computedBrandForeground(_ComputedBrandPair brand, bool isLight) =>
    // Shared foreground must also work on the darker dark-mode variant.
    (isLight ? brand.primary : brand.variant).onColor();

_ComputedSemanticForegrounds _computedSemanticForegrounds(
  _ComputedSemanticValues semantic,
) => (
  onError: semantic.error.onColor(),
  onWarning: semantic.warning.onColor(),
  onSuccess: semantic.success.onColor(),
  onInfo: semantic.info.onColor(),
);

_ComputedSurfaceForegrounds _computedSurfaceForegrounds(
  _ComputedSurfaceValues surface,
  bool isLight,
) => _computedSurfaceForegroundValues(surface, isLight);

_ComputedSurfaceForegrounds _computedSurfaceForegroundValues(
  _ComputedSurfaceValues surface,
  bool isLight,
) => (
  onSurface: _computedSurfaceForeground(surface.surface, isLight),
  onSurfaceVariant: _computedSurfaceVariantForeground(
    surface.surfaceVariant,
    isLight,
  ),
  onBackground: _computedSurfaceForeground(surface.background, isLight),
);

Color _computedSurfaceForeground(AuraComputedColor surface, bool isLight) =>
    _computedForegroundColor(DesignColors.neutral900, surface, isLight);

Color _computedSurfaceVariantForeground(
  AuraComputedColor surface,
  bool isLight,
) => _computedForegroundColor(DesignColors.neutral700, surface, isLight);

Color _computedForegroundColor(
  Color lightColor,
  AuraComputedColor darkSurface,
  bool isLight,
) => isLight ? lightColor : darkSurface.onColor();

AuraComputedColor _computedColor(double hue, double lightness, double chroma) =>
    AuraComputedColor.gamutMapped(
      hue: hue,
      lightness: lightness,
      chroma: chroma,
    );
