import 'package:auravibes_ui/src/colors/aura_computed_color.dart';
import 'package:auravibes_ui/src/colors/contrast.dart';
import 'package:auravibes_ui/src/colors/value_color.dart';
import 'package:auravibes_ui/src/tokens/aura_computed_color_scheme.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double hueDelta(double a, double b) {
  final d = (a - b).abs() % 360;

  return d > 180 ? 360 - d : d;
}

void main() {
  group('AuraComputedColorScheme', () {
    test('constructs AuraColorScheme and exposes key color roles', () {
      final s = AuraComputedColorScheme(
        primaryHue: 180,
        brightness: AuraBrightness.light,
      );
      expect(s, isA<AuraColorScheme>());
      expect(s.primary, isA<Color>());
      expect(s.surface, isA<Color>());
      expect(s.scrim, isA<Color>());
    });

    test('light scheme: on* meet APCA Lc 60 against their surface', () {
      final s = AuraComputedColorScheme(
        primaryHue: 200,
        brightness: AuraBrightness.light,
      );
      // Polarity-agnostic: the on color must clear the perceptual target
      // regardless of whether it is light-on-dark or dark-on-light.
      expect(
        apcaLc(foreground: s.onPrimary, background: s.primary).abs(),
        greaterThanOrEqualTo(60 - 1),
      );
      expect(
        apcaLc(foreground: s.onSurface, background: s.surface).abs(),
        greaterThanOrEqualTo(60 - 1),
      );
      expect(
        apcaLc(foreground: s.onBackground, background: s.background).abs(),
        greaterThanOrEqualTo(60 - 1),
      );
      expect(
        apcaLc(foreground: s.onError, background: s.error).abs(),
        greaterThanOrEqualTo(60 - 1),
      );
    });

    test('dark scheme: on* meet APCA Lc 60 against their surface', () {
      final s = AuraComputedColorScheme(
        primaryHue: 200,
        brightness: AuraBrightness.dark,
      );
      expect(
        apcaLc(foreground: s.onPrimary, background: s.primary).abs(),
        greaterThanOrEqualTo(60 - 1),
      );
      expect(
        apcaLc(foreground: s.onSurface, background: s.surface).abs(),
        greaterThanOrEqualTo(60 - 1),
      );
    });

    test('sampled hues meet WCAG AA for text roles', () {
      for (final brightness in AuraBrightness.values) {
        for (var hue = 0.0; hue <= 360; hue += 15) {
          final s = AuraComputedColorScheme(
            primaryHue: hue,
            brightness: brightness,
          );

          expect(
            wcagContrastRatio(s.onPrimary, s.primary),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            wcagContrastRatio(s.onSecondary, s.secondary),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            wcagContrastRatio(s.onSurface, s.surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            wcagContrastRatio(s.onSurfaceVariant, s.surfaceVariant),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            wcagContrastRatio(s.onBackground, s.background),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            wcagContrastRatio(s.onError, s.error),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            wcagContrastRatio(s.onWarning, s.warning),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            wcagContrastRatio(s.onSuccess, s.success),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            wcagContrastRatio(s.onInfo, s.info),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    });

    test('secondary hue is primary + 180 (complement)', () {
      const hue = 60.0;
      final s = AuraComputedColorScheme(
        primaryHue: hue,
        brightness: AuraBrightness.light,
      );
      final secondaryHue = OKLCHColor.fromColor(s.secondary).hue;
      // Allow sRGB round-trip drift, worst at blue hues (gamut clamping).
      expect(hueDelta(secondaryHue, hue + 180), lessThan(16));
    });

    test('semantic colors carry HueColorValues hues', () {
      final s = AuraComputedColorScheme(
        primaryHue: 0,
        brightness: AuraBrightness.light,
      );
      expect(
        hueDelta(OKLCHColor.fromColor(s.error).hue, HueColorValues.error),
        lessThan(8),
      );
      expect(
        hueDelta(OKLCHColor.fromColor(s.success).hue, HueColorValues.success),
        lessThan(8),
      );
    });

    test('surfaces stay achromatic', () {
      final s = AuraComputedColorScheme(
        primaryHue: 180,
        brightness: AuraBrightness.light,
      );
      expect(OKLCHColor.fromColor(s.surface).chroma, lessThan(0.001));
      expect(OKLCHColor.fromColor(s.background).chroma, lessThan(0.001));
    });

    test('light background is below surface elevation', () {
      final s = AuraComputedColorScheme(
        primaryHue: 180,
        brightness: AuraBrightness.light,
      );
      final background = OKLCHColor.fromColor(s.background);
      final surface = OKLCHColor.fromColor(s.surface);

      expect(background.lightness, lessThan(surface.lightness));
    });

    test('dark background is gray and below surface elevation', () {
      final s = AuraComputedColorScheme(
        primaryHue: 180,
        brightness: AuraBrightness.dark,
      );
      final background = OKLCHColor.fromColor(s.background);
      final surface = OKLCHColor.fromColor(s.surface);

      expect(s.background, isNot(Colors.black));
      expect(background.lightness, greaterThan(0.12));
      expect(background.lightness, lessThan(surface.lightness));
    });

    test('lerp from base AuraColorScheme still works (subclass unchanged)', () {
      final a = AuraComputedColorScheme(
        primaryHue: 180,
        brightness: AuraBrightness.light,
      );
      final b = AuraComputedColorScheme(
        primaryHue: 270,
        brightness: AuraBrightness.dark,
      );
      final mid = a.lerp(b, 0.5);
      expect(mid, isA<AuraColorScheme>());
      expect(mid.primary, isA<Color>());
    });
  });
}
