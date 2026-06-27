import 'package:auravibes_ui/src/colors/aura_computed_color.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

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
  factory AuraComputedColorScheme({
    required double primaryHue,
    required AuraBrightness brightness,
  }) {
    final isLight = brightness == AuraBrightness.light;

    double l(double lightL, double darkL) => isLight ? lightL : darkL;

    AuraComputedColor color(double hue, double lightness, double chroma) {
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

    AuraComputedColor brand(double lightL, double darkL, double chroma) =>
        color(
          primaryHue,
          l(lightL, darkL),
          chroma,
        );
    final primary = brand(0.4, 0.78, 0.17);
    final primaryVariant = brand(0.3, 0.68, 0.15);
    final secondaryHue = (primaryHue + 180) % 360;
    AuraComputedColor brandSecondary(
      double lightL,
      double darkL,
      double chroma,
    ) => color(
      secondaryHue,
      l(lightL, darkL),
      chroma,
    );
    final secondary = brandSecondary(0.4, 0.78, 0.17);
    final secondaryVariant = brandSecondary(0.3, 0.68, 0.15);
    final tertiaryHue = (primaryHue + 60) % 360;
    AuraComputedColor brandTertiary(
      double lightL,
      double darkL,
      double chroma,
    ) => color(
      tertiaryHue,
      l(lightL, darkL),
      chroma,
    );
    final tertiary = brandTertiary(0.4, 0.78, 0.17);
    final tertiaryVariant = brandTertiary(0.3, 0.68, 0.15);

    AuraComputedColor neutral(double lightL, double darkL) => color(
      primaryHue,
      l(lightL, darkL),
      0,
    );
    final surface = neutral(0.98, 0.18);
    final surfaceVariant = neutral(0.96, 0.22);
    final background = neutral(0.97, 0.15);
    final outline = neutral(0.65, 0.45);
    final outlineVariant = neutral(0.8, 0.3);

    AuraComputedColor semantic(double hue) => color(hue, l(0.3, 0.82), 0.2);
    final error = semantic(HueColorValues.error);
    final warning = semantic(HueColorValues.warning);
    final success = semantic(HueColorValues.success);
    final info = semantic(HueColorValues.info);

    Color on(AuraComputedColor c) => c.onColor();

    const shadow = Color(0xFF000000);
    final scrim = isLight ? const Color(0x80000000) : const Color(0xB3000000);

    return AuraComputedColorScheme._(
      primary: primary.toColor(),
      primaryVariant: primaryVariant.toColor(),
      onPrimary: on(primary),
      secondary: secondary.toColor(),
      secondaryVariant: secondaryVariant.toColor(),
      onSecondary: on(secondary),
      tertiary: tertiary.toColor(),
      tertiaryVariant: tertiaryVariant.toColor(),
      onTertiary: on(tertiary),
      surface: surface.toColor(),
      surfaceVariant: surfaceVariant.toColor(),
      onSurface: on(surface),
      onSurfaceVariant: on(surfaceVariant),
      background: background.toColor(),
      onBackground: on(background),
      error: error.toColor(),
      onError: on(error),
      warning: warning.toColor(),
      onWarning: on(warning),
      success: success.toColor(),
      onSuccess: on(success),
      info: info.toColor(),
      onInfo: on(info),
      outline: outline.toColor(),
      outlineVariant: outlineVariant.toColor(),
      shadow: shadow,
      scrim: scrim,
    );
  }
  const AuraComputedColorScheme._({
    required super.primary,
    required super.primaryVariant,
    required super.onPrimary,
    required super.secondary,
    required super.secondaryVariant,
    required super.onSecondary,
    required super.tertiary,
    required super.tertiaryVariant,
    required super.onTertiary,
    required super.surface,
    required super.surfaceVariant,
    required super.onSurface,
    required super.onSurfaceVariant,
    required super.background,
    required super.onBackground,
    required super.error,
    required super.onError,
    required super.warning,
    required super.onWarning,
    required super.success,
    required super.onSuccess,
    required super.info,
    required super.onInfo,
    required super.outline,
    required super.outlineVariant,
    required super.shadow,
    required super.scrim,
  });
}
