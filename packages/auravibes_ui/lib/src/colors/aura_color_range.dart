import 'package:auravibes_ui/src/colors/aura_brightness.dart';
import 'package:auravibes_ui/src/colors/value_color.dart';

/// Design targets in OKLCH, independent of hue. Contrast is checked separately.
class AuraColorRange {
  /// Near-white neutral canvas.
  static const lightCanvas = AuraColorRange(0.98, 1, 0, 0);

  /// Charcoal neutral canvas.
  static const darkCanvas = AuraColorRange(0.16, 0.24, 0, 0);

  /// Gray grouping on a near-white canvas.
  static const lightGroup = AuraColorRange(0.94, 0.97, 0, 0);

  /// Raised neutral grouping on a charcoal canvas.
  static const darkGroup = AuraColorRange(0.24, 0.3, 0, 0);

  /// Strong light-mode accent. Chroma is an upper bound, limited by gamut.
  static const lightAction = AuraColorRange(0.48, 0.6, 0, 0.24);

  /// Bright brand control fill, paired with dark labels.
  static const actionFill = AuraColorRange(0.8, 0.86, 0, 0.24);

  /// Light pastel container; foreground must be solved for this background.
  static const lightPastel = AuraColorRange(0.89, 0.95, 0.02, 0.08);

  /// Bright pastel accent on dark surfaces, paired with dark foregrounds.
  static const darkPastel = AuraColorRange(0.83, 0.95, 0.02, 0.14);

  static const _roundTripTolerance = 1e-6;

  /// Inclusive lightness/chroma bounds, not an accessibility guarantee.
  const new(
    this.minLightness,
    this.maxLightness,
    this.minChroma,
    this.maxChroma,
  ) : assert(
        minLightness >= 0 && minLightness <= maxLightness,
        'Invalid minimum L',
      ),
      assert(maxLightness <= 1, 'Maximum L exceeds 1'),
      assert(minChroma >= 0 && minChroma <= maxChroma, 'Invalid minimum C'),
      assert(maxChroma < double.infinity, 'Maximum C must be finite');

  /// Minimum OKLCH lightness.
  final double minLightness;

  /// Maximum OKLCH lightness.
  final double maxLightness;

  /// Minimum OKLCH chroma.
  final double minChroma;

  /// Maximum desired OKLCH chroma, before gamut mapping.
  final double maxChroma;

  /// Whether L/C satisfy this range, allowing conversion round-off only.
  bool contains(OKLCHColor color) =>
      color.lightness >= minLightness - _roundTripTolerance &&
      color.lightness <= maxLightness + _roundTripTolerance &&
      color.chroma >= minChroma - _roundTripTolerance &&
      color.chroma <= maxChroma + _roundTripTolerance;

  /// Validates a target and reduces chroma to fit sRGB, preserving L and hue.
  AuraComputedColor resolve({
    required double hue,
    required double lightness,
    required double chroma,
  }) {
    final target = AuraComputedColor.withLightness(
      hue: hue,
      lightness: lightness,
      chroma: chroma,
    );
    if (!contains(target)) throw ArgumentError('Color outside role range');

    final mapped = AuraComputedColor.gamutMapped(
      hue: hue,
      lightness: lightness,
      chroma: chroma,
    );
    if (!contains(mapped)) {
      throw ArgumentError('Role minimum chroma cannot fit sRGB at this L/hue');
    }

    return mapped;
  }
}
