import 'package:auravibes_ui/src/colors/aura_brightness.dart';
import 'package:auravibes_ui/src/colors/color_contrast.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('early selection retains invalid chroma rejection', () {
    final source = AuraComputedColor.withLightness(
      hue: 186,
      lightness: 0.2,
      chroma: -0.03,
    );
    expect(source.onColor, throwsArgumentError);
  });

  test('optimized search matches exhaustive foreground selection', () {
    for (final hue in [0.0, 60.0, 121.0, 186.0, 240.0, 300.0, 360.0]) {
      for (final lightness in [0.0, 0.2, 0.49, 0.5, 0.8, 0.96, 1.0]) {
        for (final chroma in [0.0, 0.03, 0.2]) {
          final surface = AuraComputedColor.gamutMapped(
            hue: hue,
            lightness: lightness,
            chroma: chroma,
          );
          for (final target in [
            (lc: 40.0, ratio: 3.0),
            (lc: 60.0, ratio: 4.5),
            (lc: 120.0, ratio: 7.0),
          ]) {
            expect(
              surface.onColor(
                targetLc: target.lc,
                targetWcagRatio: target.ratio,
              ),
              _exhaustiveOnColor(surface, target.lc, target.ratio),
              reason: 'h=$hue, L=$lightness, C=$chroma, target=$target',
            );
          }
        }
      }
    }
  });
}

Color _exhaustiveOnColor(AuraComputedColor source, double lc, double ratio) {
  final background = Color(source.toColor().toARGB32());
  var bestDark = const Color(0xFF000000);
  var bestLight = const Color(0xFFFFFFFF);
  Color? dark;
  Color? light;
  var maxPositive = -double.infinity;
  var minNegative = double.infinity;
  final candidates = [
    bestDark,
    bestLight,
    for (var step = 0; step <= 100; step++)
      AuraComputedColor.gamutMapped(
        hue: source.hue,
        lightness: step / 100,
        chroma: source.chroma,
      ).toColor(),
  ];
  for (final raw in candidates) {
    final color = Color(raw.toARGB32());
    final contrast = ColorContrast.apcaLc(
      foreground: color,
      background: background,
    );
    if (contrast > maxPositive) {
      maxPositive = contrast;
      bestDark = color;
    }
    if (contrast < minNegative) {
      minNegative = contrast;
      bestLight = color;
    }
    if (ColorContrast.wcagContrastRatio(color, background) < ratio) continue;
    if (contrast >= lc) dark = color;
    if (contrast <= -lc) light = color;
  }

  return (source.lightness >= 0.5 ? dark : light) ??
      dark ??
      light ??
      (maxPositive.abs() >= minNegative.abs() ? bestDark : bestLight);
}
