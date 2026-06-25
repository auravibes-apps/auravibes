import 'package:auravibes_ui/src/colors/aura_computed_color.dart';
import 'package:auravibes_ui/src/colors/contrast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraComputedColor', () {
    test('brightness preset resolves to OKLCH lightness', () {
      final light = AuraComputedColor(
        hue: 180,
      );
      final dark = AuraComputedColor(
        hue: 180,
        brightness: AuraBrightness.dark,
      );
      expect(light.lightness, AuraBrightness.light.lightness);
      expect(dark.lightness, AuraBrightness.dark.lightness);
    });

    test('withLightness constructor uses explicit L', () {
      final c = AuraComputedColor.withLightness(
        hue: 200,
        lightness: 0.5,
      );
      expect(c.lightness, 0.5);
      expect(c.hue, 200);
    });

    test('inherits OKLCHColor.toColor round-trip', () {
      final c = AuraComputedColor(
        hue: 180,
        brightness: AuraBrightness.dark,
      );
      expect(c.toColor(), isA<Color>());
    });

    test(
      'onColor returns dark foreground for light surface meeting targetLc',
      () {
        final surface = AuraComputedColor(
          hue: 210,
        );
        final on = surface.onColor();
        final lc = apcaLc(foreground: on, background: surface.toColor());
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
        final surface = AuraComputedColor(
          hue: 210,
          brightness: AuraBrightness.dark,
        );
        final on = surface.onColor();
        final lc = apcaLc(foreground: on, background: surface.toColor());
        expect(
          lc,
          lessThanOrEqualTo(-60 + 1),
          reason: 'should meet Lc -60 (scan granularity tolerance)',
        );
      },
    );

    test('onColor higher target yields higher-magnitude Lc', () {
      final surface = AuraComputedColor(
        hue: 270,
        brightness: AuraBrightness.dark,
      );
      final on60 = surface.onColor();
      final on90 = surface.onColor(targetLc: 90);
      final lc60 = apcaLc(
        foreground: on60,
        background: surface.toColor(),
      ).abs();
      final lc90 = apcaLc(
        foreground: on90,
        background: surface.toColor(),
      ).abs();
      expect(lc90, greaterThanOrEqualTo(lc60));
    });
  });
}
