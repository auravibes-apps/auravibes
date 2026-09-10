import 'package:auravibes_ui/src/colors/color_contrast.dart';
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

class _OnColorCandidateScanner({
  required final AuraComputedColor source,
  required final Color background,
  required final double targetLc,
  required final double targetWcagRatio,
}) {
  Color bestDark = const Color(0xFF000000);
  Color bestLight = const Color(0xFFFFFFFF);
  Color? passingDark;
  Color? passingLight;
  double maxPos = -double.infinity;
  double minNeg = .infinity;

  _OnColorCandidates scan() {
    _checkBaseCandidates();
    _checkLightnessCandidates();

    return _result();
  }

  void _checkBaseCandidates() {
    _check(const Color(0xFF000000));
    _check(const Color(0xFFFFFFFF));
  }

  void _checkLightnessCandidates() {
    for (
      var lightnessValue = 0.0;
      lightnessValue <= 1.0001;
      lightnessValue += 0.01
    ) {
      _check(_colorAt(lightnessValue));
    }
  }

  Color _colorAt(double lightnessValue) =>
      source.copyWith(lightness: lightnessValue).toColor();

  _OnColorCandidates _result() => (
    bestDark: bestDark,
    bestLight: bestLight,
    maxPos: maxPos,
    minNeg: minNeg,
    passingDark: passingDark,
    passingLight: passingLight,
  );

  void _check(Color candidate) {
    final contrastValue = ColorContrast.apcaLc(
      foreground: candidate,
      background: background,
    );
    _updateExtremes(candidate, contrastValue);
    if (!_meetsWcag(candidate)) return;

    if (contrastValue >= targetLc) passingDark = candidate;
    if (contrastValue <= -targetLc) passingLight = candidate;
  }

  void _updateExtremes(Color candidate, double contrastValue) {
    if (contrastValue > maxPos) {
      maxPos = contrastValue;
      bestDark = candidate;
    }
    if (contrastValue < minNeg) {
      minNeg = contrastValue;
      bestLight = candidate;
    }
  }

  bool _meetsWcag(Color candidate) =>
      ColorContrast.wcagContrastRatio(candidate, background) >= targetWcagRatio;
}

/// Surface-lightness presets that drive the OKLCH `L` axis for computed colors.
///
/// `light` is a near-white surface; `dark` is a near-black surface. The presets
/// sit at perceptually typical surface tones, leaving headroom for compliant
/// foregrounds via [AuraComputedColor.onColor].
enum AuraBrightness(
  /// OKLCH lightness this preset resolves to.
  final double lightness,
) {
  /// Light surface, OKLCH `L = 0.96`.
  light(0.96),

  /// Dark surface, OKLCH `L = 0.22`.
  dark(0.22),
}

/// Computed Aura color expressed as OKLCH `hue + L + chroma`.
///
/// Extends [OKLCHColor] with WCAG 3.0 APCA contrast search so foreground ("on")
/// colors can be derived from a surface rather than hand-picked. Designed for
/// the Aura theme. Callers supply a hue and a brightness/lightness, and the
/// class produces a sRGB [Color] and a contrast-compliant foreground.
///
/// ```dart
/// final surface = AuraComputedColor(
///   hue: 180,
///   brightness: AuraBrightness.dark,
/// );
/// final text = surface.onColor(); // meets APCA Lc >= 60
/// ```
class AuraComputedColor extends OKLCHColor {
  static const _defaultChroma = 0.15;

  /// Creates a computed Aura color from a hue and a brightness preset.
  new({
    required super.hue,
    AuraBrightness brightness = AuraBrightness.light,
    super.chroma = _defaultChroma,
  }) : super(lightness: brightness.lightness);

  /// Creates a computed Aura color from a hue and an explicit OKLCH lightness.
  new withLightness({
    required super.hue,
    required super.lightness,
    super.chroma = _defaultChroma,
  });

  @override
  Color toColor() => super.toColor();

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
  }) => _OnColorCandidateScanner(
    source: this,
    background: background,
    targetLc: targetLc,
    targetWcagRatio: targetWcagRatio,
  ).scan();

  Color _selectOnColor(_OnColorCandidates candidates) =>
      _preferredCandidate(candidates) ?? _fallbackCandidate(candidates);

  Color? _preferredCandidate(_OnColorCandidates candidates) =>
      lightness >= 0.5 ? candidates.passingDark : candidates.passingLight;

  Color _fallbackCandidate(_OnColorCandidates candidates) {
    final dark = candidates.passingDark;
    if (dark != null) return dark;
    final light = candidates.passingLight;
    if (light != null) return light;

    return candidates.maxPos.abs() >= candidates.minNeg.abs()
        ? candidates.bestDark
        : candidates.bestLight;
  }
}
