import 'package:auravibes_ui/src/colors/aura_brightness.dart';
import 'package:auravibes_ui/src/colors/color_contrast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraComputedColor', () {
    test('brightness preset resolves to OKLCH lightness', () {
      final light = AuraComputedColor(hue: 180);
      final dark = AuraComputedColor(hue: 180, brightness: .dark);
      expect(light.lightness, AuraBrightness.light.lightness);
      expect(dark.lightness, AuraBrightness.dark.lightness);
    });

    test('withLightness constructor uses explicit L', () {
      final c = AuraComputedColor.withLightness(hue: 200, lightness: 0.5);
      expect(c.lightness, 0.5);
      expect(c.hue, 200);
    });

    test('gamut mapping preserves an in-gamut request', () {
      final color = AuraComputedColor.gamutMapped(
        hue: 180,
        lightness: 0.5,
        chroma: 0.03,
      );
      expect(color.chroma, 0.03);
      expect(color.toOklab().toLrgb().isValid, isTrue);
    });

    test('gamut search remains bounded for oversized finite chroma', () {
      final color = AuraComputedColor.gamutMapped(
        hue: 180,
        lightness: 0.5,
        chroma: 1e100,
      );
      expect(color.chroma, greaterThan(0));
      expect(color.toOklab().toLrgb().isValid, isTrue);
    });

    test('gamut mapping preserves L/hue and caps C per hue', () {
      final teal = AuraComputedColor.gamutMapped(
        hue: 180,
        lightness: 0.9,
        chroma: 0.2,
      );
      final red = AuraComputedColor.gamutMapped(
        hue: 30,
        lightness: 0.9,
        chroma: 0.2,
      );
      expect(teal.lightness, 0.9);
      expect(teal.hue, 180);
      expect(teal.chroma, lessThan(0.2));
      expect(teal.chroma, isNot(closeTo(red.chroma, 0.001)));
      expect(teal.toOklab().toLrgb().isValid, isTrue);
      expect(red.toOklab().toLrgb().isValid, isTrue);
    });

    test('gamut mapping normalizes hue and handles black/white', () {
      expect(
        AuraComputedColor.gamutMapped(
          hue: -60,
          lightness: 0.5,
          chroma: 0.1,
        ).hue,
        300,
      );
      expect(
        AuraComputedColor.gamutMapped(
          hue: 360,
          lightness: 0.5,
          chroma: 0.1,
        ).hue,
        0,
      );
      for (final lightness in [0.0, 1.0]) {
        expect(
          AuraComputedColor.gamutMapped(
            hue: 180,
            lightness: lightness,
            chroma: 0.2,
          ).chroma,
          0,
        );
      }
    });

    test('gamut mapping rejects invalid components', () {
      const invalid = [
        (hue: double.nan, lightness: 0.5, chroma: 0.1),
        (hue: double.infinity, lightness: 0.5, chroma: 0.1),
        (hue: 0.0, lightness: -0.1, chroma: 0.1),
        (hue: 0.0, lightness: 1.1, chroma: 0.1),
        (hue: 0.0, lightness: double.nan, chroma: 0.1),
        (hue: 0.0, lightness: 0.5, chroma: -0.1),
        (hue: 0.0, lightness: 0.5, chroma: double.infinity),
      ];
      for (final color in invalid) {
        expect(
          () => AuraComputedColor.gamutMapped(
            hue: color.hue,
            lightness: color.lightness,
            chroma: color.chroma,
          ),
          throwsArgumentError,
        );
      }
    });

    test('inherits OKLCHColor.toColor round-trip', () {
      final c = AuraComputedColor(hue: 180, brightness: .dark);
      expect(c.toColor(), isA<Color>());
    });

    test(
      'onColor returns dark foreground for light surface meeting targetLc',
      () {
        final surface = AuraComputedColor(hue: 210);
        final on = surface.onColor();
        final lc = ColorContrast.apcaLc(
          foreground: on,
          background: surface.toColor(),
        );
        expect(
          lc,
          greaterThanOrEqualTo(60 - 1),
          reason: 'should meet Lc 60 (scan granularity tolerance)',
        );
      },
    );

    test(
      'onColor returns light foreground for dark surface meeting targetLc',
      () {
        final surface = AuraComputedColor(hue: 210, brightness: .dark);
        final on = surface.onColor();
        final lc = ColorContrast.apcaLc(
          foreground: on,
          background: surface.toColor(),
        );
        expect(
          lc,
          lessThanOrEqualTo(-60 + 1),
          reason: 'should meet Lc -60 (scan granularity tolerance)',
        );
      },
    );

    test('onColor higher target yields higher-magnitude Lc', () {
      final surface = AuraComputedColor(hue: 270, brightness: .dark);
      final on60 = surface.onColor();
      final on90 = surface.onColor(targetLc: 90);
      final lc60 = ColorContrast.apcaLc(
        foreground: on60,
        background: surface.toColor(),
      ).abs();
      final lc90 = ColorContrast.apcaLc(
        foreground: on90,
        background: surface.toColor(),
      ).abs();
      expect(lc90, greaterThanOrEqualTo(lc60));
    });
  });
}
