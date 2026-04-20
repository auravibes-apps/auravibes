import 'package:auravibes_ui/src/colors/matrix_transformations.dart';
import 'package:auravibes_ui/src/colors/oklch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ColorToOklch extension', () {
    test('converts red to OKLCH', () {
      const color = Color.fromARGB(255, 255, 0, 0);
      final oklch = color.toOklch();
      expect(oklch.lightness, greaterThan(0));
      expect(oklch.lightness, lessThan(1));
      expect(oklch.chroma, greaterThan(0));
    });

    test('converts white to OKLCH', () {
      const color = Color.fromARGB(255, 255, 255, 255);
      final oklch = color.toOklch();
      expect(oklch.lightness, closeTo(1, 0.1));
      expect(oklch.chroma, closeTo(0, 0.05));
    });

    test('converts black to OKLCH', () {
      const color = Color.fromARGB(255, 0, 0, 0);
      final oklch = color.toOklch();
      expect(oklch.lightness, closeTo(0, 0.1));
      expect(oklch.chroma, closeTo(0, 0.05));
    });
  });

  group('ValueColor', () {
    test('isValid returns true for valid OklabColor', () {
      final color = OklabColor(lightness: 0.5, a: 0.1, b: 0.1);
      expect(color.isValid, isTrue);
    });

    test('isValid returns false for out-of-range values', () {
      final color = OklabColor(lightness: 1.5, a: 0.1, b: 0.1);
      expect(color.isValid, isFalse);
    });

    test('isValid returns false for negative lightness', () {
      final color = OklabColor(lightness: -0.1, a: 0.1, b: 0.1);
      expect(color.isValid, isFalse);
    });
  });

  group('LinearSrgbColor', () {
    test('creates from components', () {
      final color = LinearSrgbColor(red: 0.5, green: 0.3, blue: 0.2);
      expect(color.red, 0.5);
      expect(color.green, 0.3);
      expect(color.blue, 0.2);
      expect(color.alpha, 1);
    });

    test('creates from vector', () {
      final color = LinearSrgbColor.fromVector(const Vector(0.5, 0.3, 0.2));
      expect(color.red, 0.5);
      expect(color.green, 0.3);
      expect(color.blue, 0.2);
    });

    test('vector returns correct values', () {
      final color = LinearSrgbColor(red: 0.5, green: 0.3, blue: 0.2);
      expect(color.vector.x, 0.5);
      expect(color.vector.y, 0.3);
      expect(color.vector.z, 0.2);
    });

    test('validLimits returns 0-1 range', () {
      final color = LinearSrgbColor(red: 0.5, green: 0.3, blue: 0.2);
      final (min, max) = color.validLimits;
      expect(min.x, 0);
      expect(max.x, 1);
    });

    test('toRgb converts linear to sRGB', () {
      final color = LinearSrgbColor(red: 0.5, green: 0.5, blue: 0.5);
      final rgb = color.toRgb();
      expect(rgb.red, greaterThan(0));
      expect(rgb.red, lessThanOrEqualTo(1));
    });

    test('toOkLab converts to Oklab', () {
      final color = LinearSrgbColor(red: 1, green: 0, blue: 0);
      final lab = color.toOkLab();
      expect(lab.lightness, greaterThan(0));
      expect(lab.lightness, lessThan(1));
    });

    test('_fn handles values below threshold', () {
      final color = LinearSrgbColor(red: 0, green: 0, blue: 0);
      final rgb = color.toRgb();
      expect(rgb.red, closeTo(0, 0.01));
    });
  });

  group('RgbColor', () {
    test('creates from components', () {
      final color = RgbColor(red: 1, green: 0.5, blue: 0);
      expect(color.red, 1);
      expect(color.green, 0.5);
      expect(color.blue, 0);
    });

    test('creates from Flutter Color', () {
      const flutterColor = Color.fromARGB(255, 128, 64, 32);
      final color = RgbColor.fromColor(flutterColor);
      expect(color.red, closeTo(128 / 255, 0.01));
      expect(color.green, closeTo(64 / 255, 0.01));
      expect(color.blue, closeTo(32 / 255, 0.01));
      expect(color.alpha, closeTo(1, 0.01));
    });

    test('toColor converts back to Flutter Color', () {
      final color = RgbColor(red: 1, green: 0.5, blue: 0.25, alpha: 0.8);
      final flutterColor = color.toColor();
      expect(flutterColor.r, closeTo(1, 0.01));
      expect(flutterColor.g, closeTo(0.5, 0.01));
      expect(flutterColor.b, closeTo(0.25, 0.01));
    });

    test('isBlack returns true for black', () {
      final color = RgbColor(red: 0, green: 0, blue: 0);
      expect(color.isBlack, isTrue);
    });

    test('isBlack returns false for non-black', () {
      final color = RgbColor(red: 0.1, green: 0, blue: 0);
      expect(color.isBlack, isFalse);
    });

    test('isWhite returns true for white', () {
      final color = RgbColor(red: 1, green: 1, blue: 1);
      expect(color.isWhite, isTrue);
    });

    test('isWhite returns false for non-white', () {
      final color = RgbColor(red: 0.9, green: 1, blue: 1);
      expect(color.isWhite, isFalse);
    });

    test('toLrgb converts to linear RGB', () {
      final color = RgbColor(red: 0.5, green: 0.5, blue: 0.5);
      final lrgb = color.toLrgb();
      expect(lrgb.red, greaterThan(0));
      expect(lrgb.red, lessThan(1));
    });

    test('toOklab converts to Oklab', () {
      final color = RgbColor(red: 1, green: 0, blue: 0);
      final lab = color.toOklab();
      expect(lab.lightness, greaterThan(0));
      expect(lab.lightness, lessThan(1));
    });

    test('_rgbToLinear handles low values', () {
      final color = RgbColor(red: 0.02, green: 0, blue: 0);
      final lrgb = color.toLrgb();
      expect(lrgb.red, greaterThan(0));
    });
  });

  group('OklabColor', () {
    test('creates from components', () {
      final color = OklabColor(lightness: 0.5, a: 0.1, b: -0.1);
      expect(color.lightness, 0.5);
      expect(color.a, 0.1);
      expect(color.b, -0.1);
    });

    test('creates from vector', () {
      final color = OklabColor.fromVector(const Vector(0.5, 0.1, -0.1));
      expect(color.lightness, 0.5);
      expect(color.a, 0.1);
      expect(color.b, -0.1);
    });

    test('fromVector clamps values', () {
      final color = OklabColor.fromVector(const Vector(1.5, 0.5, -0.5));
      expect(color.lightness, 1);
      expect(color.a, closeTo(0.4, 0.01));
      expect(color.b, closeTo(-0.4, 0.01));
    });

    test('toLch converts to OKLCH', () {
      final color = OklabColor(lightness: 0.5, a: 0.1, b: 0);
      final lch = color.toLch();
      expect(lch.lightness, 0.5);
      expect(lch.chroma, closeTo(0.1, 0.01));
    });

    test('toLch handles negative hue', () {
      final color = OklabColor(lightness: 0.5, a: -0.1, b: -0.1);
      final lch = color.toLch();
      expect(lch.hue, greaterThanOrEqualTo(0));
      expect(lch.hue, lessThan(360));
    });

    test('toLrgb converts to linear RGB', () {
      final color = OklabColor(lightness: 0.5, a: 0, b: 0);
      final lrgb = color.toLrgb();
      expect(lrgb.red, greaterThan(0));
    });

    test('toRgb converts to sRGB', () {
      final color = OklabColor(lightness: 0.5, a: 0, b: 0);
      final rgb = color.toRgb();
      expect(rgb.red, greaterThan(0));
      expect(rgb.red, lessThanOrEqualTo(1));
    });

    test('vector returns correct values', () {
      final color = OklabColor(lightness: 0.5, a: 0.1, b: -0.1);
      expect(color.vector.x, 0.5);
      expect(color.vector.y, 0.1);
      expect(color.vector.z, -0.1);
    });

    test('validLimits returns correct ranges', () {
      final color = OklabColor(lightness: 0.5, a: 0, b: 0);
      final (min, max) = color.validLimits;
      expect(min.x, 0);
      expect(max.x, 1);
      expect(min.y, -0.4);
      expect(max.y, 0.4);
    });
  });

  group('OKLCHShades', () {
    test('has all 9 values', () {
      expect(OKLCHShades.values, hasLength(9));
    });

    test('s100 is lightest', () {
      expect(OKLCHShades.s100.lightness, closeTo(0.97, 0.01));
      expect(OKLCHShades.s100.chroma, closeTo(0.02, 0.01));
    });

    test('s500 is mid shade', () {
      expect(OKLCHShades.s500.lightness, closeTo(0.60, 0.01));
      expect(OKLCHShades.s500.chroma, closeTo(0.27, 0.01));
    });

    test('s900 is darkest', () {
      expect(OKLCHShades.s900.lightness, closeTo(0.12, 0.01));
      expect(OKLCHShades.s900.chroma, closeTo(0.02, 0.01));
    });

    test('lightness decreases from s100 to s900', () {
      expect(
        OKLCHShades.s100.lightness,
        greaterThan(OKLCHShades.s200.lightness),
      );
      expect(
        OKLCHShades.s200.lightness,
        greaterThan(OKLCHShades.s300.lightness),
      );
      expect(
        OKLCHShades.s300.lightness,
        greaterThan(OKLCHShades.s400.lightness),
      );
      expect(
        OKLCHShades.s400.lightness,
        greaterThan(OKLCHShades.s500.lightness),
      );
      expect(
        OKLCHShades.s500.lightness,
        greaterThan(OKLCHShades.s600.lightness),
      );
      expect(
        OKLCHShades.s600.lightness,
        greaterThan(OKLCHShades.s700.lightness),
      );
      expect(
        OKLCHShades.s700.lightness,
        greaterThan(OKLCHShades.s800.lightness),
      );
      expect(
        OKLCHShades.s800.lightness,
        greaterThan(OKLCHShades.s900.lightness),
      );
    });
  });

  group('OKLCHColor', () {
    test('creates with default values', () {
      final color = OKLCHColor(hue: 180);
      expect(color.hue, 180);
      expect(color.lightness, 0);
      expect(color.chroma, 0);
      expect(color.alpha, 1);
    });

    test('creates with all values', () {
      final color = OKLCHColor(
        hue: 120,
        lightness: 0.5,
        chroma: 0.2,
        alpha: 0.8,
      );
      expect(color.hue, 120);
      expect(color.lightness, 0.5);
      expect(color.chroma, 0.2);
      expect(color.alpha, 0.8);
    });

    test('fromColor creates from Flutter Color', () {
      const flutterColor = Color.fromARGB(255, 0, 128, 0);
      final oklch = OKLCHColor.fromColor(flutterColor);
      expect(oklch.lightness, greaterThan(0));
      expect(oklch.lightness, lessThan(1));
    });

    test('toColor converts to Flutter Color', () {
      final color = OKLCHColor(hue: 0, lightness: 0.5, chroma: 0.2);
      final flutterColor = color.toColor();
      expect(flutterColor, isA<Color>());
    });

    test('textDescription returns formatted string', () {
      final color = OKLCHColor(hue: 120, lightness: 0.5, chroma: 0.2);
      expect(color.textDescription, contains('OKLCH'));
      expect(color.textDescription, contains('0.50'));
      expect(color.textDescription, contains('0.20'));
      expect(color.textDescription, contains('120.00'));
    });

    test('copyWith replaces values', () {
      final color = OKLCHColor(hue: 120, lightness: 0.5, chroma: 0.2);
      final copy = color.copyWith(lightness: 0.7);
      expect(copy.lightness, 0.7);
      expect(copy.hue, 120);
      expect(copy.chroma, 0.2);
    });

    test('copyWith keeps original values when null', () {
      final color = OKLCHColor(hue: 120, lightness: 0.5, chroma: 0.2);
      final copy = color.copyWith();
      expect(copy.lightness, 0.5);
      expect(copy.hue, 120);
      expect(copy.chroma, 0.2);
    });

    test('toOklab converts to Oklab', () {
      final color = OKLCHColor(hue: 0, lightness: 0.5, chroma: 0.2);
      final lab = color.toOklab();
      expect(lab.lightness, 0.5);
      expect(lab.a, closeTo(0.2, 0.01));
      expect(lab.b, closeTo(0, 0.01));
    });

    test('shade applies predefined shade', () {
      final color = OKLCHColor(hue: 240, lightness: 0.5, chroma: 0.2);
      final shaded = color.shade(OKLCHShades.s100);
      expect(shaded.lightness, OKLCHShades.s100.lightness);
      expect(shaded.chroma, OKLCHShades.s100.chroma);
      expect(shaded.hue, 240);
    });

    test('round-trip conversion preserves approximate values', () {
      const original = Color.fromARGB(255, 100, 150, 200);
      final oklch = original.toOklch();
      final converted = oklch.toColor();
      expect(converted.r, closeTo(original.r, 2));
      expect(converted.g, closeTo(original.g, 2));
      expect(converted.b, closeTo(original.b, 2));
    });
  });
}
