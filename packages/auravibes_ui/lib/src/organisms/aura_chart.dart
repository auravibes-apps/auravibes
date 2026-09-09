import 'dart:math' as math;

import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

part 'aura_chart_type.dart';
part 'aura_chart_series.dart';

const _chartHalf = 2.0;
const _pointRadius = 2.0;
const _donutHoleFactor = 0.5;
const _slotCenter = 0.5;
const _barWidthFactor = 0.6;
const _barOffsetFactor = 0.3;
const _lineStrokeWidth = 2.0;
const _fullCircleMultiplier = 2.0;

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
    _validateChart(this);

    return _AuraChartContent(chart: this);
  }
}

class const _AuraChartContent({required final AuraChart chart})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chart = this.chart;

    return Semantics(
      child: _AuraChartColumn(chart: chart),
      excludeSemantics: true,
      image: true,
      label: chart.semanticLabel,
    );
  }
}

class const _AuraChartColumn({required final AuraChart chart})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    spacing: context.auraTheme.spacing.sm,
    children: [
      _AuraChartTop(chart: chart),
      _AuraChartBottom(chart: chart),
    ],
  );
}

class const _AuraChartTop({required final AuraChart chart})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    spacing: context.auraTheme.spacing.sm,
    children: [
      if (chart.yAxisTitle case final title?) _AuraChartAxisTitle(title: title),
      _AuraChartPlot(chart: chart),
    ],
  );
}

class const _AuraChartBottom({required final AuraChart chart})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraChartBottomColumn(chart: chart);
}

class _AuraChartBottomColumn extends StatelessWidget {
  new({required this.chart})
    : _children = [
        if (chart.labels.isNotEmpty) _AuraChartLabels(labels: chart.labels),
        _AuraChartLegend(series: chart.series, unit: chart.unit),
        if (chart.xAxisTitle case final title?)
          _AuraChartAxisTitle(title: title, centered: true),
      ];

  final AuraChart chart;
  final List<Widget> _children;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    spacing: context.auraTheme.spacing.sm,
    children: _children,
  );
}

class const _AuraChartAxisTitle({
  required final String title,
  final bool centered = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(title),
    style: .caption,
    textAlign: centered ? TextAlign.center : null,
  );
}

class const _AuraChartPlot({required final AuraChart chart})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _chartPainter(context, chart),
    size: const Size(320, 180),
  );
}

_AuraChartPainter _chartPainter(BuildContext context, AuraChart chart) =>
    _AuraChartPainter(
      series: chart.series,
      type: chart.type,
      colors: _chartColors(context, chart),
      axisColor: context.auraColors.outline,
      direction: Directionality.of(context),
      stacked: chart.stacked,
      minY: chart.minY,
      maxY: chart.maxY,
    );

class const _AuraChartLabels({required final List<String> labels})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
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
  );
}

class const _AuraChartLegend({
  required final List<AuraChartSeries> series,
  required final String? unit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: context.auraTheme.spacing.md,
    children: [
      for (final item in series)
        AuraText(child: Text(_chartLegendLabel(item, unit)), tint: item.tint),
    ],
  );
}

List<Color> _chartColors(BuildContext context, AuraChart chart) {
  final tints = chart.palette.isEmpty
      ? chart.series.map((item) => item.tint)
      : chart.palette;

  return [for (final tint in tints) context.auraColors.colorFor(tint)];
}

void _validateChart(AuraChart chart) {
  if (_hasInvalidChart(chart)) {
    throw ArgumentError(
      'Charts require matching labels, finite values and a summary.',
    );
  }
}

bool _hasInvalidChart(AuraChart chart) {
  return _hasInvalidChartLabel(chart) ||
      _hasInvalidChartBounds(chart) ||
      _hasInvalidChartSeries(chart) ||
      _hasInvalidPie(chart.type, chart.series);
}

bool _hasInvalidChartLabel(AuraChart chart) =>
    chart.semanticLabel.trim().isEmpty;

bool _hasInvalidChartBounds(AuraChart chart) =>
    switch ((minY: chart.minY, maxY: chart.maxY)) {
      (minY: final minY?, maxY: final maxY?) => minY > maxY,
      _ => false,
    };

bool _hasInvalidChartSeries(AuraChart chart) =>
    chart.series.any((item) => _hasInvalidSeries(item, chart.labels.length));

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

typedef _CartesianScale = ({
  double scale,
  double divisor,
  Iterable<double> normalized,
});

typedef _PieGeometry = ({Offset center, double radius});

typedef _ChartPaintRequest = ({
  Canvas canvas,
  Size size,
  List<AuraChartSeries> series,
  AuraChartType type,
  List<Color> colors,
  Color axisColor,
  TextDirection direction,
  bool stacked,
  double? minY,
  double? maxY,
});

typedef _ChartHighRequest = ({
  Iterable<double> normalized,
  Iterable<double> stackedValues,
  double? fixedMaxY,
  double divisor,
});

typedef _LayoutFromBoundsRequest = ({
  Size size,
  double scale,
  double low,
  double high,
});

typedef _StackedValuesRequest = ({
  List<AuraChartSeries> series,
  bool stacked,
  AuraChartType type,
  double scale,
});

typedef _PaintSeriesRequest = ({
  _ChartPaintRequest chart,
  AuraChartSeries item,
  int seriesIndex,
  _CartesianLayout layout,
});

typedef _BarGeometryRequest = ({
  double barX,
  double barWidth,
  double top,
  double bottom,
});

typedef _PieSliceRequest = ({
  _PieSlicesData data,
  int index,
  double start,
  double sweep,
});

typedef _PieArcRequest = ({
  Canvas canvas,
  Offset center,
  double radius,
  double start,
  double sweep,
  Color color,
});

typedef _SeriesPaintData = ({
  _ChartPaintRequest chart,
  AuraChartSeries item,
  int seriesIndex,
  _CartesianLayout layout,
  Paint paint,
  Path path,
  double slot,
});

typedef _ChartSamplePoint = ({double value, double x, double y});

typedef _BarPaintData = ({
  _SeriesPaintData series,
  int index,
  _ChartSamplePoint point,
});

typedef _BarGeometry = ({double left, double top, double right, double bottom});

typedef _PieSlicesData = ({
  _ChartPaintRequest chart,
  List<double> values,
  double total,
  Offset center,
  double radius,
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

double _chartHigh(_ChartHighRequest request) {
  final fixedMaxY = request.fixedMaxY;
  if (fixedMaxY case final value?) {
    return value / request.divisor;
  }

  return [
    ...request.normalized,
    ...request.stackedValues,
  ].fold<double>(0, math.max);
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
    if (_hasNoChartMarks(series, size)) return;
    _paintChart(_paintRequest(canvas, size));
  }

  @override
  bool shouldRepaint(_AuraChartPainter oldDelegate) => true;

  _ChartPaintRequest _paintRequest(Canvas canvas, Size size) => (
    canvas: canvas,
    size: size,
    series: series,
    type: type,
    colors: colors,
    axisColor: axisColor,
    direction: direction,
    stacked: stacked,
    minY: minY,
    maxY: maxY,
  );
}

void _paintChart(_ChartPaintRequest request) {
  if (_isPieChart(request.type)) {
    _paintPie(request);

    return;
  }

  _paintCartesian(request);
}

bool _hasNoChartMarks(List<AuraChartSeries> series, Size size) =>
    (series.firstOrNull?.values.isEmpty ?? true) ||
    size.width <= 0 ||
    size.height <= 0;

void _paintCartesian(_ChartPaintRequest request) {
  final layout = _cartesianLayout(request);
  _paintAxis(request, layout);
  for (final (seriesIndex, item) in request.series.indexed) {
    _paintSeries((
      chart: request,
      item: item,
      seriesIndex: seriesIndex,
      layout: layout,
    ));
  }
}

void _paintAxis(_ChartPaintRequest request, _CartesianLayout layout) {
  request.canvas.drawLine(
    .new(0, layout.baseline),
    .new(request.size.width, layout.baseline),
    Paint()..color = request.axisColor,
  );
}

_CartesianLayout _cartesianLayout(_ChartPaintRequest request) {
  // Normalize first so even opposite finite double extremes do not overflow.
  final values = request.series.expand((item) => item.values);
  final scale = _cartesianScale(values);

  return _cartesianLayoutFromScale(request, scale);
}

_CartesianLayout _cartesianLayoutFromScale(
  _ChartPaintRequest request,
  _CartesianScale scale,
) {
  final bounds = _cartesianBounds(request, scale);

  return _layoutFromBounds((
    size: request.size,
    scale: scale.scale,
    low: bounds.low,
    high: bounds.high,
  ));
}

typedef _CartesianBounds = ({double low, double high});

_CartesianBounds _cartesianBounds(
  _ChartPaintRequest request,
  _CartesianScale scale,
) {
  final low = _cartesianLow(request, scale);
  final high = _cartesianHigh(request, scale);

  return (low: low, high: high);
}

double _cartesianLow(_ChartPaintRequest request, _CartesianScale scale) =>
    _chartLow(scale.normalized, request.minY, scale.divisor);

double _cartesianHigh(_ChartPaintRequest request, _CartesianScale scale) =>
    _chartHigh((
      normalized: scale.normalized,
      stackedValues: _stackedValues((
        series: request.series,
        stacked: request.stacked,
        type: request.type,
        scale: scale.scale,
      )),
      fixedMaxY: request.maxY,
      divisor: scale.divisor,
    ));

_CartesianScale _cartesianScale(Iterable<double> values) {
  final scale = _chartScale(values);
  final divisor = scale == 0 ? 1.0 : scale;

  return (
    scale: scale,
    divisor: divisor,
    normalized: values.map((value) => _normalizeValue(value, scale)),
  );
}

_CartesianLayout _layoutFromBounds(_LayoutFromBoundsRequest request) {
  final geometry = _layoutGeometry(request.size, request.low, request.high);

  return (
    scale: request.scale,
    low: request.low,
    high: request.high,
    range: geometry.range,
    inset: geometry.inset,
    plotHeight: geometry.plotHeight,
    baseline: geometry.baseline,
  );
}

typedef _LayoutGeometry = ({
  double range,
  double inset,
  double plotHeight,
  double baseline,
});

_LayoutGeometry _layoutGeometry(Size size, double low, double high) {
  final range = _layoutRange(low, high);
  final inset = _layoutInset(size);
  final plotHeight = _layoutPlotHeight(size, inset);

  return (
    range: range,
    inset: inset,
    plotHeight: plotHeight,
    baseline: inset + (high / range) * plotHeight,
  );
}

double _layoutRange(double low, double high) => high == low ? 1.0 : high - low;

double _layoutInset(Size size) =>
    math.min(_chartHalf, size.height / _chartHalf);

double _layoutPlotHeight(Size size, double inset) =>
    size.height - inset * _chartHalf;

double _chartScale(Iterable<double> values) =>
    values.fold<double>(0, (a, b) => math.max(a, b.abs()));

Iterable<double> _stackedValues(_StackedValuesRequest request) {
  if (!_canStackValues(request)) return const <double>[];

  return _stackedCategoryValues(request);
}

bool _canStackValues(_StackedValuesRequest request) =>
    request.stacked && request.type == AuraChartType.bar;

Iterable<double> _stackedCategoryValues(_StackedValuesRequest request) {
  final categoryCount = request.series.first.values.length;

  return [
    for (var index = 0; index < categoryCount; index++)
      _stackedCategoryValue(request.series, index, request.scale),
  ];
}

double _stackedCategoryValue(
  List<AuraChartSeries> series,
  int index,
  double scale,
) {
  return series.fold<double>(
    0,
    (sum, item) => sum + _normalizeValue(item.values[index], scale),
  );
}

void _paintSeries(_PaintSeriesRequest request) {
  final data = _seriesPaintData(request);
  _paintSamples(data);
  if (request.chart.type == AuraChartType.line) {
    request.chart.canvas.drawPath(data.path, data.paint..style = .stroke);
  }
}

_SeriesPaintData _seriesPaintData(_PaintSeriesRequest request) {
  final chart = request.chart;

  return (
    chart: chart,
    item: request.item,
    seriesIndex: request.seriesIndex,
    layout: request.layout,
    paint: _seriesPaint(chart.colors[request.seriesIndex]),
    path: Path(),
    slot: _seriesSlot(chart.size, request.item),
  );
}

Paint _seriesPaint(Color color) => Paint()
  ..color = color
  ..strokeWidth = _lineStrokeWidth
  ..strokeCap = .round;

double _seriesSlot(Size size, AuraChartSeries item) =>
    size.width / item.values.length;

void _paintSamples(_SeriesPaintData data) {
  for (final (index, sample) in data.item.values.indexed) {
    _paintSample(data, index, sample);
  }
}

void _paintSample(_SeriesPaintData data, int index, double sample) {
  final point = _samplePoint(data, index, sample);
  if (data.chart.type == AuraChartType.bar) {
    _paintBar((series: data, index: index, point: point));

    return;
  }
  _paintLinePoint(data, index, point);
}

_ChartSamplePoint _samplePoint(
  _SeriesPaintData data,
  int index,
  double sample,
) {
  final value = _sampleValue(data, sample);
  final position = _samplePosition(data, index);

  return (
    value: value,
    x: _chartX(data.chart.size.width, position, data.chart.direction),
    y: _sampleY(data, value),
  );
}

double _sampleValue(_SeriesPaintData data, double sample) =>
    _normalizeValue(sample, data.layout.scale);

double _samplePosition(_SeriesPaintData data, int index) =>
    (index + _slotCenter) * data.slot;

double _sampleY(_SeriesPaintData data, double value) {
  final layout = data.layout;

  return layout.inset +
      (layout.high - value) / layout.range * layout.plotHeight;
}

void _paintBar(_BarPaintData data) {
  final geometry = _barGeometry(data);
  data.series.chart.canvas.drawRect(
    .fromLTRB(geometry.left, geometry.top, geometry.right, geometry.bottom),
    data.series.paint,
  );
}

_BarGeometry _barGeometry(_BarPaintData data) {
  final barWidth = _barWidth(data);
  final barX = _barX(data, barWidth);
  final stackOffset = _stackOffset(data);
  final top = _barTop(data, stackOffset);
  final bottom = _barBottom(data, stackOffset);

  return _orderedBarGeometry((
    barX: barX,
    barWidth: barWidth,
    top: top,
    bottom: bottom,
  ));
}

_BarGeometry _orderedBarGeometry(_BarGeometryRequest request) {
  return (
    left: request.barX - request.barWidth / _chartHalf,
    top: math.min(request.top, request.bottom),
    right: request.barX + request.barWidth / _chartHalf,
    bottom: math.max(request.top, request.bottom),
  );
}

double _barWidth(_BarPaintData data) {
  final series = data.series;
  final chart = series.chart;

  return chart.stacked
      ? series.slot * _barWidthFactor
      : series.slot * _barWidthFactor / chart.series.length;
}

double _barX(_BarPaintData data, double barWidth) {
  return data.point.x + _barDirectionalOffset(data, barWidth);
}

double _barDirectionalOffset(_BarPaintData data, double barWidth) {
  final chart = data.series.chart;
  final offset = _barOffset(data, barWidth);

  return chart.direction == TextDirection.rtl ? -offset : offset;
}

double _barOffset(_BarPaintData data, double barWidth) {
  final series = data.series;
  final chart = series.chart;

  return chart.stacked
      ? 0.0
      : (series.seriesIndex + _slotCenter) * barWidth -
            series.slot * _barOffsetFactor;
}

double _barTop(_BarPaintData data, double stackOffset) {
  if (!data.series.chart.stacked) return data.point.y;

  return _stackedBarY(data, stackOffset);
}

double _barBottom(_BarPaintData data, double stackOffset) {
  final series = data.series;
  if (!series.chart.stacked) return series.layout.baseline;
  final layout = series.layout;

  return layout.inset +
      (layout.high - stackOffset) / layout.range * layout.plotHeight;
}

double _stackedBarY(_BarPaintData data, double stackOffset) {
  final layout = data.series.layout;

  return layout.inset +
      (layout.high - (data.point.value + stackOffset)) /
          layout.range *
          layout.plotHeight;
}

double _stackOffset(_BarPaintData data) {
  final chart = data.series.chart;
  final scale = data.series.layout.scale;
  if (!chart.stacked || scale == 0) return 0;

  return _stackedOffset(chart, data, scale);
}

double _stackedOffset(
  _ChartPaintRequest chart,
  _BarPaintData data,
  double scale,
) {
  return chart.series
      .take(data.series.seriesIndex)
      .fold<double>(
        0,
        (sum, previous) =>
            sum + _normalizeValue(previous.values[data.index], scale),
      );
}

double _chartX(double width, double position, TextDirection direction) =>
    direction == TextDirection.rtl ? width - position : position;

void _paintLinePoint(
  _SeriesPaintData data,
  int index,
  _ChartSamplePoint point,
) {
  if (index == 0) {
    data.path.moveTo(point.x, point.y);
  } else {
    data.path.lineTo(point.x, point.y);
  }
  data.chart.canvas.drawCircle(
    .new(point.x, point.y),
    _pointRadius,
    data.paint,
  );
}

void _paintPie(_ChartPaintRequest request) {
  final values = request.series.single.values;
  final total = _pieTotal(values);
  if (total <= 0) return;

  final slices = _pieSlicesData(request, values, total);

  _beginPie(request);
  _drawPieSlices(slices);
  _endPie(request, slices);
}

_PieSlicesData _pieSlicesData(
  _ChartPaintRequest request,
  List<double> values,
  double total,
) {
  final geometry = _pieGeometry(request.size);

  return (
    chart: request,
    values: values,
    total: total,
    center: geometry.center,
    radius: geometry.radius,
  );
}

_PieGeometry _pieGeometry(Size size) => (
  center: size.center(.zero),
  radius: math.min(size.width, size.height) / _chartHalf,
);

void _beginPie(_ChartPaintRequest request) {
  if (request.type == AuraChartType.donut) {
    request.canvas.saveLayer(Offset.zero & request.size, .new());
  }
}

void _endPie(_ChartPaintRequest request, _PieSlicesData data) {
  if (request.type == AuraChartType.donut) {
    _clearDonutCenter(request, data.center, data.radius);
  }
}

double _pieTotal(List<double> values) =>
    values.fold<double>(0, (sum, value) => sum + value);

void _drawPieSlices(_PieSlicesData data) {
  var start = -math.pi / 2;
  for (final (index, value) in data.values.indexed) {
    final sweep = _pieSweep(value, data.total);
    _drawPieSlice((data: data, index: index, start: start, sweep: sweep));
    start += sweep;
  }
}

double _pieSweep(double value, double total) =>
    value / total * math.pi * _fullCircleMultiplier;

void _drawPieSlice(_PieSliceRequest request) {
  final data = request.data;

  _drawPieArc(_pieArcRequest(data, request));
}

_PieArcRequest _pieArcRequest(_PieSlicesData data, _PieSliceRequest request) =>
    (
      canvas: data.chart.canvas,
      center: data.center,
      radius: data.radius,
      start: request.start,
      sweep: request.sweep,
      color: data.chart.colors[request.index % data.chart.colors.length],
    );

void _drawPieArc(_PieArcRequest request) => request.canvas.drawArc(
  .fromCircle(center: request.center, radius: request.radius),
  request.start,
  request.sweep,
  true,
  Paint()..color = request.color,
);

void _clearDonutCenter(
  _ChartPaintRequest request,
  Offset center,
  double radius,
) {
  request.canvas
    ..drawCircle(center, radius * _donutHoleFactor, Paint()..blendMode = .clear)
    ..restore();
}
