import 'dart:math' as math;

import 'package:flutter/widgets.dart';

// APCA 0.0.98G reference constants (Myndex). WCAG 3.0 draft contrast model.
// See https://github.com/Myndex/apca-w3.
const double _normBgExp = 0.56;
const double _normTxtExp = 0.57;
const double _revBgExp = 0.65;
const double _revTxtExp = 0.62;
const double _scale = 1.14;
const double _blkThrs = 0.022;
const double _blkClmp = 1.414;
const double _deltaYMin = 0.0005;
const double _loConThreshold = 0.1;
const double _loConOffset = 0.027;
const double _loConScale = 0.75;
const double _maxContrast = 108;
const double _wcagOffset = 0.05;

double _channelToLinear(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _relativeLuminance(Color c) =>
    _channelToLinear(c.r) * 0.2126 +
    _channelToLinear(c.g) * 0.7152 +
    _channelToLinear(c.b) * 0.0722;

/// APCA perceived contrast as Lc score.
///
/// Implements WCAG 3.0 draft APCA 0.0.98G (Myndex). Asymmetric by design.
/// Different exponents per polarity address the light-vs-dark divergence
/// that WCAG 2.x ratios model symmetrically.
///
/// Returns a signed value. Positive values represent dark foreground on a
/// light background. Negative values represent light foreground on a dark
/// background.
///
/// Reference Lc targets per the APCA specification are Lc 90 for maximum
/// usable contrast, Lc 75 for large body text or spot color, Lc 60 for the
/// body text minimum, and Lc 45 for large text at least 18pt.
abstract final class ColorContrast {
  /// Computes the APCA perceived contrast score.
  static double apcaLc({required Color foreground, required Color background}) {
    final textLuminance = _softClamp(_relativeLuminance(foreground));
    final backgroundLuminance = _softClamp(_relativeLuminance(background));

    return _contrastValue(
      textLuminance: textLuminance,
      backgroundLuminance: backgroundLuminance,
    );
  }

  /// Computes the WCAG 2.x contrast ratio, range [1.0, 21.0].
  ///
  /// Reference thresholds are 4.5 for text AA (1.4.3), 3.0 for large text AA
  /// or non-text UI (1.4.11), 7.0 for text AAA (1.4.6), and 4.5 for large
  /// text AAA (1.4.6).
  static double wcagContrastRatio(Color a, Color b) {
    final luminances = (a: _relativeLuminance(a), b: _relativeLuminance(b));

    return _wcagRatio(luminances);
  }
}

double _wcagRatio(({double a, double b}) luminances) {
  final higher = math.max(luminances.a, luminances.b);
  final lower = math.min(luminances.a, luminances.b);

  return (higher + _wcagOffset) / (lower + _wcagOffset);
}

double _softClamp(double luminance) {
  // Ponytail. Soft clamp near black avoids singularity. Standard APCA
  // 0.0.98G.
  if (luminance < _blkThrs) {
    return luminance + math.pow(_blkThrs - luminance, _blkClmp).toDouble();
  }

  return luminance;
}

double _contrastValue({
  required double textLuminance,
  required double backgroundLuminance,
}) {
  if ((backgroundLuminance - textLuminance).abs() < _deltaYMin) return 0;

  final value = _polarityContrast(
    textLuminance: textLuminance,
    backgroundLuminance: backgroundLuminance,
  );

  return _clampContrast(value * 100);
}

double _polarityContrast({
  required double textLuminance,
  required double backgroundLuminance,
}) => backgroundLuminance > textLuminance
    ? _positiveContrast(textLuminance, backgroundLuminance)
    : _negativeContrast(textLuminance, backgroundLuminance);

double _clampContrast(double value) => value.clamp(-_maxContrast, _maxContrast);

double _positiveContrast(double textLuminance, double backgroundLuminance) {
  final value =
      (math.pow(backgroundLuminance, _normBgExp).toDouble() -
          math.pow(textLuminance, _normTxtExp).toDouble()) *
      _scale;

  return value < _loConThreshold ? value * _loConScale : value - _loConOffset;
}

double _negativeContrast(double textLuminance, double backgroundLuminance) {
  final value =
      (math.pow(backgroundLuminance, _revBgExp).toDouble() -
          math.pow(textLuminance, _revTxtExp).toDouble()) *
      _scale;

  return value > -_loConThreshold ? value * _loConScale : value + _loConOffset;
}
// Public contrast helpers intentionally remain top-level.
