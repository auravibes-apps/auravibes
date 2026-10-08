import 'package:auravibes_ui/src/colors/color_contrast.dart';
import 'package:auravibes_ui/src/colors/value_color.dart';
import 'package:flutter/widgets.dart';

const _onColorPolarityLightness = 0.5;

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
  static const _lightnessSteps = 100;

  Color bestDark = const Color(0xFF000000);
  Color bestLight = const Color(0xFFFFFFFF);
  Color? passingDark;
  Color? passingLight;
  double maxPos = -double.infinity;
  double minNeg = .infinity;

  _OnColorCandidates scan() {
    _checkBaseCandidates();
    // White is the last light candidate; black bounds positive APCA contrast.
    if (_validGamutComponents(source) &&
        passingLight != null &&
        (source.lightness < _onColorPolarityLightness || maxPos < targetLc)) {
      return _result();
    }
    passingDark = null;
    _checkLightnessCandidates();

    return _result();
  }

  void _checkBaseCandidates() {
    _check(const Color(0xFF000000));
    _check(const Color(0xFFFFFFFF));
  }

  void _checkLightnessCandidates() {
    for (var step = _lightnessSteps; step >= 0; step--) {
      _check(_colorAt(step / _lightnessSteps));
      if (source.lightness >= _onColorPolarityLightness
          ? passingDark != null
          : passingLight != null) {
        return;
      }
    }
  }

  Color _colorAt(double lightnessValue) => AuraComputedColor.gamutMapped(
    hue: source.hue,
    lightness: lightnessValue,
    chroma: source.chroma,
  ).toColor();

  _OnColorCandidates _result() => (
    bestDark: bestDark,
    bestLight: bestLight,
    maxPos: maxPos,
    minNeg: minNeg,
    passingDark: passingDark,
    passingLight: passingLight,
  );

  void _check(Color rawCandidate) {
    final candidate = Color(rawCandidate.toARGB32());
    final contrastValue = ColorContrast.apcaLc(
      foreground: candidate,
      background: background,
    );
    _updateExtremes(candidate, contrastValue);
    if (!_meetsWcag(candidate)) return;

    if (contrastValue >= targetLc) passingDark ??= candidate;
    if (contrastValue <= -targetLc) passingLight ??= candidate;
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
/// Extends [OKLCHColor] with WCAG 2.x and APCA contrast search for foregrounds.
/// Callers supply a hue and brightness/lightness. The gamutMapped method fits
/// sRGB; [onColor] searches for text targets, falling back when targets fail.
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
  static const _gamutSearchSteps = 24;
  static const _gamutHeadroom = 0.95;

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

  /// Keeps an sRGB target, or reduces chroma with 5% boundary headroom.
  ///
  /// Preserves lightness and normalized hue. Does not clip RGB channels to
  /// make an out-of-gamut chromatic target appear valid.
  static AuraComputedColor gamutMapped({
    required double hue,
    required double lightness,
    required double chroma,
  }) {
    final target = AuraComputedColor.withLightness(
      hue: hue,
      lightness: lightness,
      chroma: chroma,
    );
    if (!_validGamutComponents(target)) {
      throw ArgumentError('Expected finite hue/C, L in [0, 1], and C >= 0');
    }
    target.hue %= 360;
    target.chroma = _mappedChroma(target);

    return target;
  }

  /// Foreground color that meets APCA [targetLc] against this surface.
  ///
  /// Scans the OKLCH `L` axis, preserving hue and gamut-capping chroma, for the
  /// lightness that achieves the requested perceptual contrast and WCAG 2.x AA
  /// text contrast. Prefers the natural polarity (dark text on light surfaces,
  /// light text on dark); if that polarity cannot meet both targets, falls
  /// back to whichever polarity does, else returns the strongest-contrast
  /// candidate. Contrast checks use opaque 8-bit sRGB output.
  Color onColor({double targetLc = 60, double targetWcagRatio = 4.5}) {
    final background = Color(toColor().toARGB32());
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
      lightness >= _onColorPolarityLightness
      ? candidates.passingDark
      : candidates.passingLight;

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

bool _validGamutComponents(OKLCHColor color) =>
    color.hue.isFinite &&
    color.chroma.isFinite &&
    color.chroma >= 0 &&
    color.lightness >= 0 &&
    color.lightness <= 1;

double _mappedChroma(OKLCHColor color) {
  if (color.chroma == 0 || color.lightness == 0 || color.lightness == 1) {
    return 0;
  }
  if (color.toOklab().toLrgb().isValid) return color.chroma;

  return _maximumSrgbChroma(color) * AuraComputedColor._gamutHeadroom;
}

double _maximumSrgbChroma(OKLCHColor color) {
  var lower = 0.0;
  // C < 1 covers sRGB and bounds precision for oversized requests.
  var upper = color.chroma.clamp(0.0, 1.0);
  for (var step = 0; step < AuraComputedColor._gamutSearchSteps; step++) {
    final middle = (lower + upper) / 2;
    if (color.copyWith(chroma: middle).toOklab().toLrgb().isValid) {
      lower = middle;
    } else {
      upper = middle;
    }
  }

  return lower;
}
