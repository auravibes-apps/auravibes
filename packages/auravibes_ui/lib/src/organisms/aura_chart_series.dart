part of 'aura_chart.dart';

/// One named series with a semantic accent.
class AuraChartSeries {
  /// Creates a series. Values must be finite and match the chart labels.
  const new({
    required this.label,
    required this.values,
    this.tint = AuraTint.primary,
  });

  /// Caller-localized series name.
  final String label;

  /// Samples at equally spaced labeled positions.
  final List<double> values;

  /// Series accent.
  final AuraTint tint;

  /// Whether the series contains samples.
  bool hasValues() => values.isNotEmpty;
}
