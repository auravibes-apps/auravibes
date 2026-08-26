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
    var textLuminance = _relativeLuminance(foreground);
    var backgroundLuminance = _relativeLuminance(background);

    // Ponytail. Soft clamp near black avoids singularity. Standard APCA
    // 0.0.98G.
    if (textLuminance < _blkThrs) {
      textLuminance += math.pow(_blkThrs - textLuminance, _blkClmp).toDouble();
    }
    if (backgroundLuminance < _blkThrs) {
      backgroundLuminance += math
          .pow(_blkThrs - backgroundLuminance, _blkClmp)
          .toDouble();
    }

    if ((backgroundLuminance - textLuminance).abs() < _deltaYMin) return 0;

    double contrastValue;
    if (backgroundLuminance > textLuminance) {
      // Dark text on light background -> positive Lc.
      contrastValue =
          (math.pow(backgroundLuminance, _normBgExp) -
              math.pow(textLuminance, _normTxtExp)) *
          _scale;
      contrastValue = contrastValue < _loConThreshold
          ? contrastValue * _loConScale
          : contrastValue - _loConOffset;
    } else {
      // Light text on dark background -> negative Lc.
      contrastValue =
          (math.pow(backgroundLuminance, _revBgExp) -
              math.pow(textLuminance, _revTxtExp)) *
          _scale;
      contrastValue = contrastValue > -_loConThreshold
          ? contrastValue * _loConScale
          : contrastValue + _loConOffset;
    }

    contrastValue *= 100;

    const maxContrast = 108.0;

    return contrastValue.clamp(-maxContrast, maxContrast);
  }

  /// Computes the WCAG 2.x contrast ratio, range [1.0, 21.0].
  ///
  /// Reference thresholds are 4.5 for text AA (1.4.3), 3.0 for large text AA
  /// or non-text UI (1.4.11), 7.0 for text AAA (1.4.6), and 4.5 for large
  /// text AAA (1.4.6).
  static double wcagContrastRatio(Color a, Color b) {
    final luminanceA = _relativeLuminance(a);
    final luminanceB = _relativeLuminance(b);
    final higherLuminance = luminanceA > luminanceB ? luminanceA : luminanceB;
    final lowerLuminance = luminanceA > luminanceB ? luminanceB : luminanceA;

    const luminanceOffset = 0.05;

    return (higherLuminance + luminanceOffset) /
        (lowerLuminance + luminanceOffset);
  }
}
// Public contrast helpers intentionally remain top-level.
