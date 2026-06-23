import 'package:auravibes_ui/src/colors/contrast.dart';
import 'package:auravibes_ui/src/colors/value_color.dart';
import 'package:flutter/widgets.dart';

typedef _OnColorCandidates = ({
  Color bestDark,
  Color bestLight,
  double maxPos,
  double minNeg,
  Color? passingDark,
  Color? passingLight,
});

/// Surface-lightness presets that drive the OKLCH `L` axis for computed colors.
///
/// `light` is a near-white surface; `dark` is a near-black surface. The presets
/// sit at perceptually typical surface tones, leaving headroom for compliant
/// foregrounds via [AuraComputedColor.onColor].
enum AuraBrightness {
  /// Light surface, OKLCH `L = 0.96`.
  light(0.96),

  /// Dark surface, OKLCH `L = 0.22`.
  dark(0.22);

  const AuraBrightness(this.lightness);

  /// OKLCH lightness this preset resolves to.
  final double lightness;
}

/// Computed Aura color expressed as OKLCH `hue + L + chroma`.
///
/// Extends [OKLCHColor] with WCAG 3.0 APCA contrast search so foreground ("on")
/// colors can be derived from a surface rather than hand-picked. Designed for
/// the Aura theme: callers supply a hue and a brightness/lightness, the class
/// produces a sRGB [Color] and a contrast-compliant foreground.
///
/// ```dart
/// final surface = AuraComputedColor(
///   hue: 180,
///   brightness: AuraBrightness.dark,
/// );
/// final text = surface.onColor(); // meets APCA Lc >= 60
/// ```
class AuraComputedColor extends OKLCHColor {
  /// Creates a computed Aura color from a hue and a brightness preset.
  AuraComputedColor({
    required super.hue,
    AuraBrightness brightness = AuraBrightness.light,
    super.chroma = 0.15,
  }) : super(lightness: brightness.lightness);

  /// Creates a computed Aura color from a hue and an explicit OKLCH lightness.
  AuraComputedColor.withLightness({
    required super.hue,
    required super.lightness,
    super.chroma = 0.15,
  });

  /// Foreground color that meets APCA [targetLc] against this surface.
  ///
  /// Scans the OKLCH `L` axis (keeping this color's hue and chroma) for the
  /// lightness that achieves the requested perceptual contrast and WCAG 2.x AA
  /// text contrast. Prefers the natural polarity (dark text on light surfaces,
  /// light text on dark); if that polarity cannot meet both targets, falls
  /// back to whichever polarity does, else returns the strongest-contrast
  /// candidate.
  Color onColor({double targetLc = 60, double targetWcagRatio = 4.5}) {
    final background = toColor();
    final candidates = _scanOnColorCandidates(
      background: background,
      targetLc: targetLc,
      targetWcagRatio: targetWcagRatio,
    );

    return _selectOnColor(candidates);
  }

  _OnColorCandidates _scanOnColorCandidates({
    required Color background,
    required double targetLc,
    required double targetWcagRatio,
  }) {
    var bestDark = const Color(0xFF000000);
    var bestLight = const Color(0xFFFFFFFF);
    Color? passingDark;
    Color? passingLight;
    var maxPos = -double.infinity;
    var minNeg = double.infinity;

    void check(Color candidate) {
      final lc = apcaLc(foreground: candidate, background: background);
      if (lc > maxPos) {
        maxPos = lc;
        bestDark = candidate;
      }
      if (lc < minNeg) {
        minNeg = lc;
        bestLight = candidate;
      }
      if (wcagContrastRatio(candidate, background) < targetWcagRatio) return;
      if (lc >= targetLc) passingDark = candidate;
      if (lc <= -targetLc) passingLight = candidate;
    }

    check(const Color(0xFF000000));
    check(const Color(0xFFFFFFFF));
    for (var l = 0.0; l <= 1.0001; l += 0.01) {
      check(copyWith(lightness: l).toColor());
    }

    return (
      bestDark: bestDark,
      bestLight: bestLight,
      maxPos: maxPos,
      minNeg: minNeg,
      passingDark: passingDark,
      passingLight: passingLight,
    );
  }

  Color _selectOnColor(_OnColorCandidates candidates) {
    final surfaceLight = lightness >= 0.5;
    if (surfaceLight) {
      final color = candidates.passingDark;
      if (color != null) return color;
    }
    if (!surfaceLight) {
      final color = candidates.passingLight;
      if (color != null) return color;
    }
    final dark = candidates.passingDark;
    if (dark != null) return dark;
    final light = candidates.passingLight;
    if (light != null) return light;

    return candidates.maxPos.abs() >= candidates.minNeg.abs()
        ? candidates.bestDark
        : candidates.bestLight;
  }
}
