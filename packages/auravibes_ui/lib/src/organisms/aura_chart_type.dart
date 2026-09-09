part of 'aura_chart.dart';

/// Supported chart presentations.
enum AuraChartType {
  /// Connected points in input order.
  line,

  /// Bars extending from zero.
  bar,

  /// Proportional slices from one non-negative series.
  pie,

  /// Proportional slices with a central cutout.
  donut,
}
