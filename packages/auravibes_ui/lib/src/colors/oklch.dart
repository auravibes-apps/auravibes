import 'dart:core';
import 'dart:math' as math;

import 'package:auravibes_ui/src/colors/matrix_transformations.dart';
import 'package:flutter/widgets.dart';

extension on num {
  num fit(num min, num max) => math.min(max, math.max(min, this));
  bool isBetween(num min, num max) => this >= min && this <= max;
}

extension ColorToOklch on Color {
  /// Converts a Flutter [Color] to an [OKLCHColor].
  OKLCHColor toOklch() {
    final rgbColor = RgbColor.fromColor(this);
    final lab = rgbColor.toOklab();
    final lch = lab.toLch();

    return lch;
  }
}

/// Abstract base class for color representations that can be validated.
abstract class ValueColor {
  /// Creates a new [ValueColor] instance.
  const ValueColor();

  /// The vector representation of this color.
  Vector get vector;

  /// The valid limits for this color space.
  (Vector, Vector) get validLimits;

  /// Whether this color has valid component values.
  bool get isValid {
    final (validLimits1, validLimits2) = validLimits;

    return vector.x.isBetween(validLimits1.x, validLimits2.x) &&
        vector.y.isBetween(validLimits1.y, validLimits2.y) &&
        vector.z.isBetween(validLimits1.z, validLimits2.z);
  }
}

/// Represents a color in linear RGB color space.
class LinearSrgbColor extends ValueColor {
  /// Creates a linear RGB color from component values.
  LinearSrgbColor({
    required this.red,
    required this.green,
    required this.blue,
    this.alpha = 1,
  });

  /// Creates a linear RGB color from a vector.
  LinearSrgbColor.fromVector(Vector vector, {this.alpha = 1})
    : red = vector.x.toDouble(),
      green = vector.y.toDouble(),
      blue = vector.z.toDouble();

  /// The red component in range [0, 1].
  double red;

  /// The green component in range [0, 1].
  double green;

  /// The blue component in range [0, 1].
  double blue;

  /// The alpha (opacity) component in range [0, 1].
  double alpha;

  double _fn(double val) {
    final sign = val < 0 ? -1 : 1;
    final abs = val.abs();

    if (val >= 0.0031308) {
      return sign * (1.055 * math.pow(abs, 1.0 / 2.4)) - 0.055;
    }

    return 12.92 * val;
  }

  /// Converts to sRGB color space.
  RgbColor toRgb() => RgbColor(
    red: _fn(red).fit(0, 1).toDouble(),
    blue: _fn(blue).fit(0, 1).toDouble(),
    green: _fn(green).fit(0, 1).toDouble(),
    alpha: alpha,
  );

  /// Converts to Oklab color space.
  OklabColor toOkLab() {
    final lms = vector.transform(lrgbToLms).cbrt();
    final oklab = lms.transform(lmsToOklab);
    final oklabColor = OklabColor.fromVector(oklab, alpha: alpha);

    return oklabColor;
  }

  @override
  Vector get vector => Vector(red, green, blue);

  @override
  (Vector, Vector) get validLimits => (
    const Vector(0, 0, 0),
    const Vector(1, 1, 1),
  );
}

/// Represents a color in sRGB color space.
class RgbColor {
  /// Creates an sRGB color from component values.
  RgbColor({
    required this.red,
    required this.green,
    required this.blue,
    this.alpha = 1,
  });

  /// Creates an sRGB color from a Flutter Color.
  RgbColor.fromColor(Color color)
    : red = color.r / 255,
      green = color.g / 255,
      blue = color.b / 255,
      alpha = color.a / 255;

  /// The red component in range [0, 1].
  double red;

  /// The green component in range [0, 1].
  double green;

  /// The blue component in range [0, 1].
  double blue;

  /// The alpha (opacity) component in range [0, 1].
  double alpha;

  /// Converts to a Flutter Color.
  Color toColor() => Color.from(
    alpha: alpha.fit(0, 1).toDouble(),
    red: red.fit(0, 1).toDouble(),
    green: green.fit(0, 1).toDouble(),
    blue: blue.fit(0, 1).toDouble(),
  );

  /// Whether this color is black.
  bool get isBlack => green == 0 && red == 0 && blue == 0;

  /// Whether this color is white.
  bool get isWhite => green == 1 && red == 1 && blue == 1;

  /// Converts to linear RGB color space.
  LinearSrgbColor toLrgb() => LinearSrgbColor(
    red: _rgbToLinear(red),
    blue: _rgbToLinear(blue),
    green: _rgbToLinear(green),
    alpha: alpha,
  );

  double _rgbToLinear(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  /// Converts to Oklab color space.
  OklabColor toOklab() {
    final lrgb = toLrgb();
    final lab = lrgb.toOkLab();

    return lab;
  }
}

/// Represents a color in Oklab color space.
class OklabColor extends ValueColor {
  /// Creates an Oklab color from component values.
  OklabColor({
    required this.lightness,
    required this.a,
    required this.b,
    this.alpha = 1,
  });

  /// Creates an Oklab color from a vector.
  OklabColor.fromVector(Vector vector, {this.alpha = 1})
    : lightness = vector.x.fit(0, 1).toDouble(),
      a = vector.y.fit(-.4, .4).toDouble(),
      b = vector.z.fit(-.4, .4).toDouble();

  /// The lightness component in range [0, 1].
  double lightness;

  /// The a (green-red) component.
  double a;

  /// The b (blue-yellow) component.
  double b;

  /// The alpha (opacity) component in range [0, 1].
  double alpha;

  /// Converts to OKLCH color space.
  OKLCHColor toLch() {
    final hue = (math.atan2(b, a) * 180) / math.pi;

    return OKLCHColor(
      lightness: lightness,
      chroma: math.sqrt(math.pow(a, 2) + math.pow(b, 2)),
      hue: hue >= 0 ? hue : hue + 360,
    );
  }

  @override
  Vector get vector => Vector(lightness, a, b);

  /// Converts to linear RGB color space.
  LinearSrgbColor toLrgb() {
    final lms = vector.transform(oklabToLms).cubed();
    final lrgb = lms.transform(lmsTolrgb);

    return LinearSrgbColor.fromVector(lrgb, alpha: alpha);
  }

  /// Converts to sRGB color space.
  RgbColor toRgb() => toLrgb().toRgb();

  /// Returns the valid limits for Oklab color space components.
  ///
  /// The a component (green-red axis) uses range [-0.4, 0.4].
  /// The b component (blue-yellow axis) uses range [-0.4, 0.4].
  /// These limits represent the gamut of colors that can be
  /// displayed in sRGB, derived from the mathematical
  /// transformation between sRGB and Oklab color spaces.
  /// Values outside this range represent colors that cannot be
  /// rendered in standard sRGB displays.
  @override
  (Vector, Vector) get validLimits => (
    const Vector(0, -0.4, -0.4),
    const Vector(1, 0.4, 0.4),
  );
}

/// Predefined shades for OKLCH colors with varying lightness and chroma.
///
/// The numeric suffix follows a familiar 100–900 scale, where
/// [OKLCHShades.s100] is the lightest shade and [OKLCHShades.s900]
/// is the darkest.
enum OKLCHShades {
  /// Lightest shade (highest lightness, lowest chroma).
  ///
  /// Use for backgrounds or subtle tints.
  s100,

  /// Very light shade.
  ///
  /// Slightly darker and more saturated than [OKLCHShades.s100].
  s200,

  /// Light shade.
  ///
  /// Typically used for hover states, borders, or light accents.
  s300,

  /// Light-to-mid shade.
  ///
  /// Darker and more saturated than [OKLCHShades.s300].
  s400,

  /// Mid shade (balanced lightness and chroma).
  ///
  /// Often used as the primary color value.
  s500,

  /// Mid-to-dark shade.
  ///
  /// Darker and more saturated than [OKLCHShades.s500].
  s600,

  /// Dark shade.
  ///
  /// Suitable for strong accents or pressed states.
  s700,

  /// Very dark shade.
  ///
  /// Approaches background/ink colors for high contrast.
  s800,

  /// Darkest shade (lowest lightness, low chroma).
  ///
  /// Use for text or the most prominent dark elements.
  s900;
  /// The chroma value for this shade.
  double get chroma => switch (this) {
    OKLCHShades.s100 || OKLCHShades.s900 => 0.02,
    OKLCHShades.s200 || OKLCHShades.s800 => 0.05,
    OKLCHShades.s300 || OKLCHShades.s700 => 0.12,
    OKLCHShades.s400 || OKLCHShades.s600 => 0.19,
    OKLCHShades.s500 => 0.27,
  };

  /// The lightness value for this shade.
  double get lightness => switch (this) {
    OKLCHShades.s100 => 0.97,
    OKLCHShades.s200 => 0.89,
    OKLCHShades.s300 => 0.80,
    OKLCHShades.s400 => 0.71,
    OKLCHShades.s500 => 0.60,
    OKLCHShades.s600 => 0.49,
    OKLCHShades.s700 => 0.38,
    OKLCHShades.s800 => 0.25,
    OKLCHShades.s900 => 0.12,
  };
}

/// The OKLCHColor class represents colors in the OKLCH color space.
/// OKLCH is a perceptually uniform color space, which can be useful for
/// various color processing tasks in Flutter applications.
class OKLCHColor {
  /// Main constructor for creating an OKLCHColor object.
  OKLCHColor({
    required this.hue,
    this.lightness = 0,
    this.chroma = 0,
    this.alpha = 1,
  });

  /// Factory constructor that creates an OKLCHColor instance
  /// from a Flutter Color object.
  factory OKLCHColor.fromColor(Color color) {
    final rgbColor = RgbColor.fromColor(color);
    final lab = rgbColor.toOklab();
    final lch = lab.toLch();

    return lch;
  }

  /// Lightness component of the OKLCH color model.
  double lightness;

  /// Chroma component, indicating the color intensity or purity.
  double chroma;

  /// Hue component, defining the type of color (like blue, green, etc.).
  double hue;

  /// Alpha (opacity) value of the color. Defaults to 1.0 (fully opaque).
  double alpha;

  /// Converts the OKLCH color to a Flutter Color object using RGB values.
  Color toColor() {
    final lab = toOklab();
    final lrgb = lab.toLrgb();
    final rgb = lrgb.toRgb();

    return rgb.toColor();
  }

  /// Gives a textual representation of the OKLCH color,
  /// displaying lightness, chroma, and hue values.
  String get textDescription =>
      'OKLCH(${lightness.toStringAsFixed(2)}, '
      '${chroma.toStringAsFixed(2)}, ${hue.toStringAsFixed(2)})';

  /// Creates a copy of this OKLCH color with optionally replaced values.
  OKLCHColor copyWith({
    double? lightness,
    double? chroma,
    double? hue,
    double? alpha,
  }) => OKLCHColor(
    lightness: lightness ?? this.lightness,
    chroma: chroma ?? this.chroma,
    hue: hue ?? this.hue,
    alpha: alpha ?? this.alpha,
  );

  /// Converts OKLCH to Oklab color space.
  OklabColor toOklab() {
    final a = chroma * math.cos((math.pi / 180) * hue);
    final b = chroma * math.sin((math.pi / 180) * hue);

    return OklabColor(lightness: lightness, a: a, b: b, alpha: alpha);
  }

  /// Returns a shade of this color with the specified predefined shade.
  OKLCHColor shade(OKLCHShades shadesValue) =>
      copyWith(lightness: shadesValue.lightness, chroma: shadesValue.chroma);
}
