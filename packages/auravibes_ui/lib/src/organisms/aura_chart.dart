import 'dart:math' as math;

import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

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
}

/// A static chart rendered with Flutter drawing primitives and a text legend.
class AuraChart extends StatelessWidget {
  /// Creates a chart. An empty series draws no marks.
  const new({
    required this.labels,
    required this.series,
    required this.semanticLabel,
    super.key,
    this.type = AuraChartType.line,
    this.stacked = false,
    this.minY,
    this.maxY,
    this.xAxisTitle,
    this.yAxisTitle,
    this.unit,
    this.palette = const [],
  });

  /// Caller-localized labels, in reading order.
  final List<String> labels;

  /// Series sharing the same labels and vertical scale.
  final List<AuraChartSeries> series;

  /// Required localized summary including units, labels and relevant values.
  final String semanticLabel;

  /// Line or bar presentation.
  final AuraChartType type;

  /// Stacks bar series at each category.
  final bool stacked;

  /// Optional fixed lower vertical bound.
  final double? minY;

  /// Optional fixed upper vertical bound.
  final double? maxY;

  /// Optional caller-localized horizontal axis title.
  final String? xAxisTitle;

  /// Optional caller-localized vertical axis title.
  final String? yAxisTitle;

  /// Optional caller-localized value unit.
  final String? unit;

  /// Allowlisted semantic colors used for category slices or series.
  final List<AuraTint> palette;

  @override
  Widget build(BuildContext context) {
    _validateChart(
      semanticLabel: semanticLabel,
      labels: labels,
      series: series,
      type: type,
      minY: minY,
      maxY: maxY,
    );

    return Semantics(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        spacing: context.auraTheme.spacing.sm,
        children: [
          if (yAxisTitle case final title?)
            AuraText(child: Text(title), style: .caption),
          CustomPaint(
            painter: _AuraChartPainter(
              series: series,
              type: type,
              colors: _chartColors(context),
              axisColor: context.auraColors.outline,
              direction: Directionality.of(context),
              stacked: stacked,
              minY: minY,
              maxY: maxY,
            ),
            size: const Size(320, 180),
          ),
          if (labels.isNotEmpty)
            Row(
              crossAxisAlignment: .start,
              children: [
                for (final label in labels)
                  Expanded(
                    child: AuraText(
                      child: Text(label),
                      style: .caption,
                      textAlign: .center,
                    ),
                  ),
              ],
            ),
          Wrap(
            spacing: context.auraTheme.spacing.md,
            children: [
              for (final item in series)
                AuraText(
                  child: Text(_chartLegendLabel(item, unit)),
                  tint: item.tint,
                ),
            ],
          ),
          if (xAxisTitle case final title?)
            AuraText(child: Text(title), style: .caption, textAlign: .center),
        ],
      ),
      excludeSemantics: true,
      image: true,
      label: semanticLabel,
    );
  }

  List<Color> _chartColors(BuildContext context) {
    final tints = palette.isEmpty ? series.map((item) => item.tint) : palette;
    return [for (final tint in tints) context.auraColors.colorFor(tint)];
  }
}

void _validateChart({
  required String semanticLabel,
  required List<String> labels,
  required List<AuraChartSeries> series,
  required AuraChartType type,
  required double? minY,
  required double? maxY,
}) {
  if (_hasInvalidChart(
    semanticLabel: semanticLabel,
    labels: labels,
    series: series,
    type: type,
    minY: minY,
    maxY: maxY,
  )) {
    throw ArgumentError(
      'Charts require matching labels, finite values and a summary.',
    );
  }
}

bool _hasInvalidChart({
  required String semanticLabel,
  required List<String> labels,
  required List<AuraChartSeries> series,
  required AuraChartType type,
  required double? minY,
  required double? maxY,
}) {
  if (semanticLabel.trim().isEmpty) return true;
  if (minY != null && maxY != null && minY > maxY) return true;
  if (series.any((item) => _hasInvalidSeries(item, labels.length))) {
    return true;
  }
  return _hasInvalidPie(type, series);
}

bool _hasInvalidSeries(AuraChartSeries item, int labelCount) =>
    item.values.length != labelCount ||
    item.values.any((value) => !value.isFinite);

bool _hasInvalidPie(AuraChartType type, List<AuraChartSeries> series) {
  if (type != AuraChartType.pie && type != AuraChartType.donut) return false;
  if (series.length != 1) return true;
  return series.single.values.any((value) => value < 0);
}

String _chartLegendLabel(AuraChartSeries item, String? unit) {
  if (unit == null || unit.isEmpty) return item.label;
  return '${item.label} ($unit)';
}

bool _isPieChart(AuraChartType type) =>
    type == AuraChartType.pie || type == AuraChartType.donut;

typedef _CartesianLayout = ({
  double scale,
  double low,
  double high,
  double range,
  double inset,
  double plotHeight,
  double baseline,
});

double _normalizeValue(double value, double scale) =>
    scale == 0 ? 0.0 : value / scale;

double _chartLow(
  Iterable<double> normalized,
  double? fixedMinY,
  double divisor,
) {
  if (fixedMinY == null) return normalized.fold<double>(0, math.min);
  return fixedMinY / divisor;
}

double _chartHigh(
  Iterable<double> normalized,
  Iterable<double> stackedValues,
  double? fixedMaxY,
  double divisor,
) {
  if (fixedMaxY == null) {
    return [...normalized, ...stackedValues].fold<double>(0, math.max);
  }
  return fixedMaxY / divisor;
}

class _AuraChartPainter extends CustomPainter {
  const new({
    required this.series,
    required this.type,
    required this.colors,
    required this.axisColor,
    required this.direction,
    required this.stacked,
    required this.minY,
    required this.maxY,
  });

  final List<AuraChartSeries> series;
  final AuraChartType type;
  final List<Color> colors;
  final Color axisColor;
  final TextDirection direction;
  final bool stacked;
  final double? minY;
  final double? maxY;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.firstOrNull?.values.isEmpty ?? true) {
      return;
    }
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    if (_isPieChart(type)) {
      _paintPie(canvas, size);

      return;
    }
    _paintCartesian(canvas, size);
  }

  void _paintCartesian(Canvas canvas, Size size) {
    final layout = _cartesianLayout(size);
    canvas.drawLine(
      .new(0, layout.baseline),
      .new(size.width, layout.baseline),
      Paint()..color = axisColor,
    );
    for (final (seriesIndex, item) in series.indexed) {
      _paintSeries(canvas, size, item, seriesIndex, layout);
    }
  }

  _CartesianLayout _cartesianLayout(Size size) {
    // Normalize first so even opposite finite double extremes do not overflow.
    final values = series.expand((item) => item.values);
    final scale = values.fold<double>(0, (a, b) => math.max(a, b.abs()));
    final normalized = values.map((value) => _normalizeValue(value, scale));
    final divisor = scale == 0 ? 1.0 : scale;
    final low = _chartLow(normalized, minY, divisor);
    final stackedValues = _stackedValues(scale);
    final high = _chartHigh(normalized, stackedValues, maxY, divisor);
    final range = high == low ? 1.0 : high - low;
    final inset = math.min(2.0, size.height / 2);
    final plotHeight = size.height - inset * 2;
    return (
      scale: scale,
      low: low,
      high: high,
      range: range,
      inset: inset,
      plotHeight: plotHeight,
      baseline: inset + (high / range) * plotHeight,
    );
  }

  Iterable<double> _stackedValues(double scale) {
    if (!stacked || type != AuraChartType.bar) return const <double>[];
    final categoryCount = series.first.values.length;
    return [
      for (var index = 0; index < categoryCount; index++)
        series.fold<double>(
          0,
          (sum, item) => sum + _normalizeValue(item.values[index], scale),
        ),
    ];
  }

  void _paintSeries(
    Canvas canvas,
    Size size,
    AuraChartSeries item,
    int seriesIndex,
    _CartesianLayout layout,
  ) {
    final paint = Paint()
      ..color = colors[seriesIndex]
      ..strokeWidth = 2
      ..strokeCap = .round;
    final path = Path();
    final slot = size.width / item.values.length;
    for (final (index, sample) in item.values.indexed) {
      _paintSample(
        canvas,
        size,
        seriesIndex,
        index,
        sample,
        slot,
        paint,
        path,
        layout,
      );
    }
    if (type == AuraChartType.line) {
      canvas.drawPath(path, paint..style = .stroke);
    }
  }

  void _paintSample(
    Canvas canvas,
    Size size,
    int seriesIndex,
    int index,
    double sample,
    double slot,
    Paint paint,
    Path path,
    _CartesianLayout layout,
  ) {
    final value = _normalizeValue(sample, layout.scale);
    final position = (index + 0.5) * slot;
    final x = _chartX(size.width, position);
    final y =
        layout.inset + (layout.high - value) / layout.range * layout.plotHeight;
    if (type == AuraChartType.bar) {
      _paintBar(canvas, seriesIndex, index, slot, x, y, value, paint, layout);
      return;
    }
    _paintLinePoint(canvas, path, paint, index, x, y);
  }

  void _paintBar(
    Canvas canvas,
    int seriesIndex,
    int index,
    double slot,
    double x,
    double y,
    double value,
    Paint paint,
    _CartesianLayout layout,
  ) {
    final barWidth = stacked ? slot * 0.6 : slot * 0.6 / series.length;
    final offset = stacked ? 0.0 : (seriesIndex + 0.5) * barWidth - slot * 0.3;
    final barX = x + (direction == TextDirection.rtl ? -offset : offset);
    final stackOffset = _stackOffset(seriesIndex, index, layout.scale);
    final stackedY =
        layout.inset +
        (layout.high - (value + stackOffset)) /
            layout.range *
            layout.plotHeight;
    final stackBaseY =
        layout.inset +
        (layout.high - stackOffset) / layout.range * layout.plotHeight;
    final top = stacked ? stackedY : y;
    final bottom = stacked ? stackBaseY : layout.baseline;
    canvas.drawRect(
      .fromLTRB(
        barX - barWidth / 2,
        math.min(top, bottom),
        barX + barWidth / 2,
        math.max(top, bottom),
      ),
      paint,
    );
  }

  double _stackOffset(int seriesIndex, int index, double scale) {
    if (!stacked || scale == 0) return 0;
    return series
        .take(seriesIndex)
        .fold<double>(
          0,
          (sum, previous) =>
              sum + _normalizeValue(previous.values[index], scale),
        );
  }

  double _chartX(double width, double position) =>
      direction == TextDirection.rtl ? width - position : position;

  void _paintLinePoint(
    Canvas canvas,
    Path path,
    Paint paint,
    int index,
    double x,
    double y,
  ) {
    if (index == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
    canvas.drawCircle(.new(x, y), 2, paint);
  }

  @override
  bool shouldRepaint(_AuraChartPainter oldDelegate) => true;

  void _paintPie(Canvas canvas, Size size) {
    final values = series.single.values;
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      return;
    }

    final center = size.center(.zero);
    final radius = math.min(size.width, size.height) / 2;
    if (type == AuraChartType.donut) {
      canvas.saveLayer(Offset.zero & size, .new());
    }
    var start = -math.pi / 2;
    for (final (index, value) in values.indexed) {
      final sweep = value / total * math.pi * 2;
      canvas.drawArc(
        .fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        Paint()..color = colors[index % colors.length],
      );
      start += sweep;
    }
    if (type == AuraChartType.donut) {
      canvas
        ..drawCircle(center, radius * 0.5, Paint()..blendMode = .clear)
        ..restore();
    }
  }
}
