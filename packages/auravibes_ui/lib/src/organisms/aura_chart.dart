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
    final fixedMinY = minY;
    final fixedMaxY = maxY;
    final valueUnit = unit;
    if (semanticLabel.trim().isEmpty ||
        (fixedMinY != null && fixedMaxY != null && fixedMinY > fixedMaxY) ||
        series.any(
          (item) =>
              item.values.length != labels.length ||
              item.values.any((value) => !value.isFinite),
        ) ||
        ((type == AuraChartType.pie || type == AuraChartType.donut) &&
            (series.length != 1 ||
                series.single.values.any((value) => value < 0)))) {
      throw ArgumentError(
        'Charts require matching labels, finite values and a summary.',
      );
    }

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
              colors: [
                for (final tint
                    in palette.isEmpty
                        ? series.map((item) => item.tint)
                        : palette)
                  context.auraColors.colorFor(tint),
              ],
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
                  child: Text(
                    valueUnit == null || valueUnit.isEmpty
                        ? item.label
                        : '${item.label} ($valueUnit)',
                  ),
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
    if (type == AuraChartType.pie || type == AuraChartType.donut) {
      _paintPie(canvas, size);

      return;
    }
    final values = series.expand((item) => item.values);
    // Normalize first so even opposite finite double extremes do not overflow.
    final scale = values.fold<double>(0, (a, b) => math.max(a, b.abs()));
    final normalized = values.map((value) => scale == 0 ? 0.0 : value / scale);
    final divisor = scale == 0 ? 1.0 : scale;
    final fixedMinY = minY;
    final fixedMaxY = maxY;
    final low = fixedMinY == null
        ? normalized.fold<double>(0, math.min)
        : fixedMinY / divisor;
    final categoryCount = series.firstOrNull?.values.length ?? 0;
    double normalizedValue(double value) => scale == 0 ? 0.0 : value / scale;
    final stackedValues = stacked && type == AuraChartType.bar
        ? [
            for (var index = 0; index < categoryCount; index++)
              series.fold<double>(
                0,
                (sum, item) => sum + normalizedValue(item.values[index]),
              ),
          ]
        : const <double>[];
    final high = fixedMaxY == null
        ? [...normalized, ...stackedValues].fold<double>(0, math.max)
        : fixedMaxY / divisor;
    final range = high == low ? 1.0 : high - low;
    final inset = math.min(2, size.height / 2);
    final plotHeight = size.height - inset * 2;
    final baseline = inset + (high / range) * plotHeight;
    canvas.drawLine(
      .new(0, baseline),
      .new(size.width, baseline),
      Paint()..color = axisColor,
    );
    for (final (seriesIndex, item) in series.indexed) {
      final paint = Paint()
        ..color = colors[seriesIndex]
        ..strokeWidth = 2
        ..strokeCap = .round;
      final path = Path();
      final slot = size.width / item.values.length;
      for (final (index, sample) in item.values.indexed) {
        final value = normalizedValue(sample);
        final position = (index + 0.5) * slot;
        final x = direction == TextDirection.rtl
            ? size.width - position
            : position;
        final y = inset + (high - value) / range * plotHeight;
        if (type == AuraChartType.bar) {
          final barWidth = stacked ? slot * 0.6 : slot * 0.6 / series.length;
          final offset = stacked
              ? 0.0
              : (seriesIndex + 0.5) * barWidth - slot * 0.3;
          final barX = x + (direction == TextDirection.rtl ? -offset : offset);
          var stackOffset = 0.0;
          if (stacked && scale != 0) {
            stackOffset = series
                .take(seriesIndex)
                .fold<double>(
                  0,
                  (sum, item) => sum + normalizedValue(item.values[index]),
                );
          }
          final stackedY =
              inset + (high - (value + stackOffset)) / range * plotHeight;
          final stackBaseY = inset + (high - stackOffset) / range * plotHeight;
          canvas.drawRect(
            .fromLTRB(
              barX - barWidth / 2,
              math.min(stacked ? stackedY : y, stacked ? stackBaseY : baseline),
              barX + barWidth / 2,
              math.max(stacked ? stackedY : y, stacked ? stackBaseY : baseline),
            ),
            paint,
          );
        } else {
          if (index == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
          canvas.drawCircle(.new(x, y), 2, paint);
        }
      }
      if (type == AuraChartType.line) {
        canvas.drawPath(path, paint..style = .stroke);
      }
    }
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
