part of 'aura_slider.dart';

/// A labeled point on an [AuraLabeledSlider] range.
class AuraSliderMark {
  /// Creates a mark at an in-range value.
  const new({required this.value, this.label});

  /// Mark position in the slider's units.
  final double value;

  /// Optional visible caller-localized label.
  final String? label;

  /// Whether this mark has a visible label.
  bool hasLabel() => label != null;
}
