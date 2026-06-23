import 'dart:math' as math;

import 'package:flutter/widgets.dart';

// APCA 0.0.98G reference constants (Myndex). WCAG 3.0 draft contrast model.
// https://github.com/Myndex/apca-w3
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
/// Implements WCAG 3.0 draft APCA 0.0.98G (Myndex). Asymmetric by design:
/// different exponents per polarity, addressing the light-vs-dark divergence
/// that WCAG 2.x ratios model symmetrically.
///
/// Returns a signed value:
///   - **Positive**: dark foreground on light background.
///   - **Negative**: light foreground on dark background.
///
/// Reference Lc targets (per APCA spec):
///   - Lc 90: maximum usable contrast.
///   - Lc 75: large body text / spot color.
///   - Lc 60: body text minimum recommended.
///   - Lc 45: large text (>= 18pt) minimum.
double apcaLc({required Color foreground, required Color background}) {
  var yT = _relativeLuminance(foreground);
  var yB = _relativeLuminance(background);

  // ponytail: soft clamp near black avoids singularity; standard APCA 0.0.98G.
  if (yT < _blkThrs) yT += (_blkThrs - yT) * _blkClmp;
  if (yB < _blkThrs) yB += (_blkThrs - yB) * _blkClmp;

  if ((yB - yT).abs() < _deltaYMin) return 0;

  double lc;
  if (yB > yT) {
    // Dark text on light background -> positive Lc.
    lc = (math.pow(yB, _normBgExp) - math.pow(yT, _normTxtExp)) * _scale;
    lc = lc < _loConThreshold ? lc * _loConScale : lc - _loConOffset;
  } else {
    // Light text on dark background -> negative Lc.
    lc = (math.pow(yB, _revBgExp) - math.pow(yT, _revTxtExp)) * _scale;
    lc = lc > -_loConThreshold ? lc * _loConScale : lc + _loConOffset;
  }

  lc *= 100;

  return lc.clamp(-108.0, 108.0);
}

/// WCAG 2.x contrast ratio, range [1.0, 21.0].
///
/// Reference thresholds:
///   - 4.5: text AA (1.4.3).
///   - 3.0: large text AA / non-text UI (1.4.11).
///   - 7.0: text AAA (1.4.6).
///   - 4.5: large text AAA (1.4.6).
double wcagContrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;

  return (hi + 0.05) / (lo + 0.05);
}
