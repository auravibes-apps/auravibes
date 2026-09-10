import 'package:auravibes_ui/src/colors/aura_brightness.dart';
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
});

/// AuraColorScheme subclass whose 24 fields are derived from a single hue
/// and a brightness preset, via OKLCH + APCA (WCAG 3.0 draft).
///
/// Brand colors follow `primaryHue`; the secondary hue is the complement
/// (`primaryHue + 180`). Semantic hues default to HueColorValues. Surfaces
/// stay achromatic. Every `on*` color is searched on the OKLCH `L` axis to meet
/// APCA Lc 60 (body-text minimum) against its surface, picking the polarity
/// that achieves it.
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
  /// Computes a full 24-field scheme from [primaryHue] and [brightness].
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
) {
  final foreground = _computedForegroundValues(
    brand: palette.brand,
    surface: palette.surface,
    semantic: palette.semantic,
    isLight: isLight,
  );

  return (
    brand: palette.brand,
    surface: palette.surface,
    semantic: palette.semantic,
    foreground: foreground,
    shadow: _computedShadow,
    scrim: _computedScrim(isLight),
  );
}

const _computedShadow = Color(0xFF000000);
const _brandVariantLightLightness = 0.3;
const _brandVariantChroma = 0.15;
const _backgroundDarkLightness = 0.15;
const _outlineVariantDarkLightness = 0.3;
const _semanticLightLightness = 0.3;

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
  primary: _brandColor((
    hue: hue,
    isLight: isLight,
    lightLightness: 0.4,
    darkLightness: 0.78,
    chroma: 0.17,
  )),
  variant: _brandColor((
    hue: hue,
    isLight: isLight,
    lightLightness: _brandVariantLightLightness,
    darkLightness: 0.68,
    chroma: _brandVariantChroma,
  )),
);

AuraComputedColor _brandColor(_BrandColorRequest request) => _computedColor(
  request.hue,
  request.isLight ? request.lightLightness : request.darkLightness,
  request.chroma,
);

_ComputedSurfaceValues _computedSurfaceValues(double primaryHue, bool isLight) {
  AuraComputedColor neutral(double lightLightness, double darkLightness) =>
      _computedColor(primaryHue, isLight ? lightLightness : darkLightness, 0);

  return (
    surface: neutral(0.98, 0.18),
    surfaceVariant: neutral(0.96, 0.22),
    background: neutral(0.94, _backgroundDarkLightness),
    outline: neutral(0.65, 0.45),
    outlineVariant: neutral(0.8, _outlineVariantDarkLightness),
  );
}

_ComputedSemanticValues _computedSemanticValues(bool isLight) {
  AuraComputedColor semantic(double hue) =>
      _computedColor(hue, isLight ? _semanticLightLightness : 0.82, 0.2);

  return (
    error: semantic(HueColorValues.error),
    warning: semantic(HueColorValues.warning),
    success: semantic(HueColorValues.success),
    info: semantic(HueColorValues.info),
  );
}

_ComputedForegroundValues _computedForegroundValues({
  required _ComputedBrandValues brand,
  required _ComputedSurfaceValues surface,
  required _ComputedSemanticValues semantic,
  required bool isLight,
}) => (
  brand: _computedBrandForegrounds(brand),
  surface: _computedSurfaceForegrounds(surface, isLight),
  semantic: _computedSemanticForegrounds(semantic),
);

_ComputedBrandForegrounds _computedBrandForegrounds(
  _ComputedBrandValues brand,
) => (
  onPrimary: brand.primary.primary.onColor(),
  onSecondary: brand.secondary.primary.onColor(),
  onTertiary: brand.tertiary.primary.onColor(),
);

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
) => (
  onSurface: _computedForegroundColor(
    DesignColors.neutral900,
    surface.surface,
    isLight,
  ),
  onSurfaceVariant: _computedForegroundColor(
    DesignColors.neutral700,
    surface.surfaceVariant,
    isLight,
  ),
  onBackground: _computedForegroundColor(
    DesignColors.neutral900,
    surface.background,
    isLight,
  ),
);

Color _computedForegroundColor(
  Color lightColor,
  AuraComputedColor darkSurface,
  bool isLight,
) => isLight ? lightColor : darkSurface.onColor();

AuraComputedColor _computedColor(double hue, double lightness, double chroma) {
  var safeChroma = chroma;
  while (safeChroma > 0) {
    final candidate = AuraComputedColor.withLightness(
      hue: hue,
      lightness: lightness,
      chroma: safeChroma,
    );
    if (candidate.toOklab().toLrgb().isValid) return candidate;
    safeChroma -= 0.01;
  }

  return AuraComputedColor.withLightness(
    hue: hue,
    lightness: lightness,
    chroma: 0,
  );
}
