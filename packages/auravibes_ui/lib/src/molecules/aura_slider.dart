import 'dart:math' as math;

import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart' show AuraTint;
import 'package:flutter/widgets.dart';

part 'aura_slider_mark.dart';
part 'aura_labeled_slider.dart';

const _controlHeight = 48.0;
const _trackHeight = 4.0;
const _thumbRadius = 10.0;
const double _thumbDiameter = _thumbRadius * 2;
const _defaultPrecision = 2;
const _maximumPrecision = 20;
const _markLabelHeight = 20.0;
const _alignmentRange = 2.0;
const _focusRingOffset = 3.0;
const _focusRingStrokeWidth = 2.0;
const _half = 2.0;

typedef _SliderNormalizationRequest = ({
  double value,
  double min,
  double max,
  double step,
  int precision,
});

typedef _SliderPositionRequest = ({
  double value,
  double width,
  double min,
  double max,
});

typedef _SliderValueAtPositionRequest = ({
  double position,
  double width,
  double min,
  double max,
  double currentValue,
});

typedef _SliderBuildValues = ({
  bool enabled,
  double value,
  double increasedValue,
  double decreasedValue,
});

typedef _SliderPaintRequest = ({
  double value,
  Size size,
  double min,
  double max,
});

typedef _SliderPaintGeometry = ({
  double centerY,
  double trackStart,
  double trackEnd,
  double thumbX,
  double trackRadius,
});

typedef _SliderTrackBounds = ({double start, double end});

typedef _SliderFocusRingRequest = ({
  Canvas canvas,
  Size size,
  double thumbX,
  Color color,
});

class const _AuraSliderIncreaseIntent() extends Intent;

class const _AuraSliderDecreaseIntent() extends Intent;

/// A controlled, themed slider for selecting a numeric value.
class AuraSlider extends StatefulWidget {
  /// Creates a slider with [value] constrained to [min] and [max].
  const new({
    required this.value,
    required this.onChanged,
    super.key,
    this.min = 0,
    this.max = 1,
    this.step = 1,
    this.precision = _defaultPrecision,
    this.enabled = true,
    this.semanticLabel,
    this.tint = AuraTint.primary,
  }) : assert(min <= max, 'min must be less than or equal to max'),
       assert(step > 0, 'step must be greater than zero'),
       assert(precision >= 0, 'precision must not be negative'),
       assert(precision <= _maximumPrecision, 'precision must not exceed 20');

  /// Current controlled value.
  final double value;

  /// Inclusive lower bound for [value].
  final double min;

  /// Inclusive upper bound for [value].
  final double max;

  /// Selectable increment, anchored at [min].
  final double step;

  /// Number of decimal places used to round controlled and emitted values.
  final int precision;

  /// Called with the next value after user interaction.
  final ValueChanged<double>? onChanged;

  /// Whether the slider accepts user interaction.
  final bool enabled;

  /// Accessible label announced for the slider.
  final String? semanticLabel;

  /// Aura tint used for the active track and thumb.
  final AuraTint tint;

  @override
  State<AuraSlider> createState() => _AuraSliderState();
}

class _AuraSliderState extends State<AuraSlider> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return _AuraSliderStateView(state: this, values: _buildValues(context));
  }

  _SliderBuildValues _buildValues(BuildContext context) {
    final value = _normalizeWidgetValue(widget.value);

    return (
      enabled: _isEnabled(context),
      value: value,
      increasedValue: _normalizeWidgetValue(value + widget.step),
      decreasedValue: _normalizeWidgetValue(value - widget.step),
    );
  }

  bool _isEnabled(BuildContext context) =>
      widget.enabled &&
      AuraInteractionScope.of(context).allowsValueChanges &&
      widget.onChanged != null;

  void _setFocusHighlight(bool value) => setState(() => _isFocused = value);

  double _normalizeWidgetValue(double value) => _normalizeValue((
    value: value,
    min: widget.min,
    max: widget.max,
    step: widget.step,
    precision: widget.precision,
  ));

  void _changeValue(double nextValue) {
    final onChanged = widget.onChanged;
    if (!widget.enabled || onChanged == null) return;

    onChanged(_normalizeWidgetValue(nextValue));
  }

  void _increase() => _changeValue(widget.value + widget.step);

  void _decrease() => _changeValue(widget.value - widget.step);
}

class const _AuraSliderStateView({
  required final _AuraSliderState state,
  required final _SliderBuildValues values,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraSliderSemantics(
    child: _AuraSliderInteractionView(state: state, values: values),
    enabled: values.enabled,
    label: state.widget.semanticLabel,
    value: values.value,
    increasedValue: values.increasedValue,
    decreasedValue: values.decreasedValue,
    onIncrease: state._increase,
    onDecrease: state._decrease,
  );
}

class _AuraSliderInteractionView extends StatelessWidget {
  _AuraSliderInteractionView({
    required _AuraSliderState state,
    required _SliderBuildValues values,
  }) : _child = _AuraSliderInteraction(
         enabled: values.enabled,
         value: values.value,
         min: state.widget.min,
         max: state.widget.max,
         tint: state.widget.tint,
         isFocused: state._isFocused,
         onChanged: state._changeValue,
         onIncrease: state._increase,
         onDecrease: state._decrease,
         onShowFocusHighlight: state._setFocusHighlight,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraSliderSemantics({
  required final Widget child,
  required final bool enabled,
  required final String? label,
  required final double value,
  required final double increasedValue,
  required final double decreasedValue,
  required final VoidCallback onIncrease,
  required final VoidCallback onDecrease,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: child,
    enabled: enabled,
    slider: true,
    label: label,
    value: value.toString(),
    increasedValue: enabled ? increasedValue.toString() : null,
    decreasedValue: enabled ? decreasedValue.toString() : null,
    onIncrease: enabled ? onIncrease : null,
    onDecrease: enabled ? onDecrease : null,
  );
}

class const _AuraSliderInteraction({
  required final bool enabled,
  required final double value,
  required final double min,
  required final double max,
  required final AuraTint tint,
  required final bool isFocused,
  required final ValueChanged<double> onChanged,
  required final VoidCallback onIncrease,
  required final VoidCallback onDecrease,
  required final ValueChanged<bool> onShowFocusHighlight,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _AuraSliderInteractionFocus(interaction: this);
}

class _AuraSliderInteractionFocus extends StatelessWidget {
  _AuraSliderInteractionFocus({required _AuraSliderInteraction interaction})
    : _child = FocusableActionDetector(
        enabled: interaction.enabled,
        shortcuts: _sliderShortcuts,
        actions: _sliderActions(interaction.onIncrease, interaction.onDecrease),
        onShowFocusHighlight: interaction.onShowFocusHighlight,
        mouseCursor: interaction.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: _AuraSliderInteractionTrack(interaction: interaction),
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraSliderInteractionTrack({
  required final _AuraSliderInteraction interaction,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraSliderTrack(
    enabled: interaction.enabled,
    value: interaction.value,
    min: interaction.min,
    max: interaction.max,
    tint: interaction.tint,
    isFocused: interaction.isFocused,
    onChanged: interaction.onChanged,
  );
}

const _sliderShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(.arrowRight): _AuraSliderIncreaseIntent(),
  SingleActivator(.arrowUp): _AuraSliderIncreaseIntent(),
  SingleActivator(.arrowLeft): _AuraSliderDecreaseIntent(),
  SingleActivator(.arrowDown): _AuraSliderDecreaseIntent(),
};

Map<Type, Action<Intent>> _sliderActions(
  VoidCallback onIncrease,
  VoidCallback onDecrease,
) => {
  _AuraSliderIncreaseIntent: CallbackAction<_AuraSliderIncreaseIntent>(
    onInvoke: (_) {
      onIncrease();

      return null;
    },
  ),
  _AuraSliderDecreaseIntent: CallbackAction<_AuraSliderDecreaseIntent>(
    onInvoke: (_) {
      onDecrease();

      return null;
    },
  ),
};

class const _AuraSliderTrack({
  required final bool enabled,
  required final double value,
  required final double min,
  required final double max,
  required final AuraTint tint,
  required final bool isFocused,
  required final ValueChanged<double> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _buildLayout);

  Widget _buildLayout(BuildContext context, BoxConstraints constraints) =>
      _AuraSliderTrackLayout(
        width: constraints.maxWidth,
        enabled: enabled,
        value: value,
        min: min,
        max: max,
        activeColor: context.auraColors.colorFor(tint),
        inactiveColor: context.auraColors.outlineVariant,
        isFocused: isFocused,
        onChanged: onChanged,
      );
}

class _AuraSliderTrackLayout extends StatelessWidget {
  _AuraSliderTrackLayout({
    required double width,
    required bool enabled,
    required double value,
    required double min,
    required double max,
    required Color activeColor,
    required Color inactiveColor,
    required bool isFocused,
    required ValueChanged<double> onChanged,
  }) : _child = _AuraSliderGesture(
         enabled: enabled,
         width: width,
         min: min,
         max: max,
         value: value,
         onChanged: onChanged,
         child: _AuraSliderTrackCanvas(
           enabled: enabled,
           value: value,
           min: min,
           max: max,
           activeColor: activeColor,
           inactiveColor: inactiveColor,
           isFocused: isFocused,
           width: width,
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraSliderGesture({
  required final bool enabled,
  required final double width,
  required final double min,
  required final double max,
  required final double value,
  required final ValueChanged<double> onChanged,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: child,
    onTapDown: enabled ? _handleTap : null,
    onHorizontalDragUpdate: enabled ? _handleDrag : null,
    behavior: .opaque,
  );

  void _handleTap(TapDownDetails details) =>
      _handlePosition(details.localPosition.dx);

  void _handleDrag(DragUpdateDetails details) =>
      _handlePosition(details.localPosition.dx);

  void _handlePosition(double position) => onChanged(
    _valueAtPosition((
      position: position,
      width: width,
      min: min,
      max: max,
      currentValue: value,
    )),
  );
}

class _AuraSliderTrackCanvas extends StatelessWidget {
  _AuraSliderTrackCanvas({
    required bool enabled,
    required double value,
    required double min,
    required double max,
    required Color activeColor,
    required Color inactiveColor,
    required bool isFocused,
    required double width,
  }) : _child = SizedBox(
         height: _controlHeight,
         child: CustomPaint(
           painter: _AuraSliderPainter(
             value: value,
             min: min,
             max: max,
             activeColor: enabled ? activeColor : inactiveColor,
             inactiveColor: inactiveColor,
           ),
           foregroundPainter: enabled && isFocused
               ? _AuraSliderFocusRingPainter(
                   thumbX: _thumbPosition((
                     value: value,
                     width: width,
                     min: min,
                     max: max,
                   )),
                   color: activeColor,
                 )
               : null,
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

double _clampValue(double value, double min, double max) =>
    value.clamp(min, max);

String _formatSliderValue(double value, int precision) =>
    value.toStringAsFixed(precision);

double _normalizeValue(_SliderNormalizationRequest request) {
  final min = request.min;
  final max = request.max;
  final clamped = _clampValue(request.value, min, max);
  if (_isSliderBoundary(clamped, min, max)) return clamped;

  return _normalizeInteriorSliderValue(clamped, request);
}

bool _isSliderBoundary(double value, double min, double max) =>
    value == min || value == max;

double _normalizeInteriorSliderValue(
  double value,
  _SliderNormalizationRequest request,
) {
  final stepped = _steppedSliderValue(value, request);
  final rounded = _roundedSliderValue(stepped, request.precision);
  final bounded = _clampValue(rounded, request.min, request.max);

  return double.parse(_formatSliderValue(bounded, request.precision));
}

double _steppedSliderValue(double value, _SliderNormalizationRequest request) {
  final min = request.min;
  final step = request.step;

  return min + ((value - min) / step).round() * step;
}

double _roundedSliderValue(double value, int precision) {
  final scale = math.pow(10, precision).toDouble();

  return (value * scale).round() / scale;
}

double _thumbPosition(_SliderPositionRequest request) {
  final bounds = _sliderTrackBounds(request.width);
  final fraction = _sliderThumbFraction(request);

  return bounds.start + (bounds.end - bounds.start) * fraction;
}

_SliderTrackBounds _sliderTrackBounds(double width) => (
  start: width < _thumbDiameter ? width / _half : _thumbRadius,
  end: width < _thumbDiameter ? width / _half : width - _thumbRadius,
);

double _sliderThumbFraction(_SliderPositionRequest request) {
  final min = request.min;
  final max = request.max;
  if (min == max) return 0.5;

  return ((request.value - min) / (max - min)).clamp(0.0, 1.0);
}

double _valueAtPosition(_SliderValueAtPositionRequest request) {
  if (_isInvalidSliderPosition(request)) return request.currentValue;

  final fraction = _sliderValueFraction(request);

  return request.min + (request.max - request.min) * fraction;
}

bool _isInvalidSliderPosition(_SliderValueAtPositionRequest request) =>
    request.min == request.max ||
    !request.width.isFinite ||
    request.width <= _thumbDiameter;

double _sliderValueFraction(_SliderValueAtPositionRequest request) =>
    ((request.position - _thumbRadius) / (request.width - _thumbDiameter))
        .clamp(0.0, 1.0);

class const _AuraSliderPainter({
  required final double value,
  required final double min,
  required final double max,
  required final Color activeColor,
  required final Color inactiveColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _sliderPaintGeometry((
      value: value,
      size: size,
      min: min,
      max: max,
    ));
    _drawSliderTrack(canvas, geometry, inactiveColor);
    _drawSliderActiveTrack(canvas, geometry, activeColor);
    _drawSliderThumb(canvas, geometry, activeColor);
  }

  @override
  bool shouldRepaint(_AuraSliderPainter oldDelegate) =>
      value != oldDelegate.value ||
      min != oldDelegate.min ||
      max != oldDelegate.max ||
      activeColor != oldDelegate.activeColor ||
      inactiveColor != oldDelegate.inactiveColor;
}

class const _AuraSliderFocusRingPainter({
  required final double thumbX,
  required final Color color,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => _drawSliderFocusRing((
    canvas: canvas,
    size: size,
    thumbX: thumbX,
    color: color,
  ));

  @override
  bool shouldRepaint(_AuraSliderFocusRingPainter oldDelegate) =>
      thumbX != oldDelegate.thumbX || color != oldDelegate.color;
}

_SliderPaintGeometry _sliderPaintGeometry(_SliderPaintRequest request) {
  final bounds = _sliderTrackBounds(request.size.width);

  return _sliderPaintGeometryForBounds(request, bounds);
}

_SliderPaintGeometry _sliderPaintGeometryForBounds(
  _SliderPaintRequest request,
  _SliderTrackBounds bounds,
) {
  final size = request.size;
  final thumbX = _sliderPaintThumbX(request);

  return (
    centerY: size.height / _half,
    trackStart: bounds.start,
    trackEnd: bounds.end,
    thumbX: thumbX,
    trackRadius: _trackHeight / _half,
  );
}

double _sliderPaintThumbX(_SliderPaintRequest request) => _thumbPosition((
  value: request.value,
  width: request.size.width,
  min: request.min,
  max: request.max,
));

void _drawSliderTrack(
  Canvas canvas,
  _SliderPaintGeometry geometry,
  Color color,
) => canvas.drawRRect(
  _sliderTrackRRect(geometry, geometry.trackEnd),
  Paint()..color = color,
);

void _drawSliderActiveTrack(
  Canvas canvas,
  _SliderPaintGeometry geometry,
  Color color,
) {
  if (geometry.thumbX <= geometry.trackStart) return;

  canvas.drawRRect(
    _sliderTrackRRect(geometry, geometry.thumbX),
    Paint()..color = color,
  );
}

RRect _sliderTrackRRect(_SliderPaintGeometry geometry, double end) {
  final start = geometry.trackStart;
  final centerY = geometry.centerY;
  final radius = geometry.trackRadius;

  return RRect.fromRectAndRadius(
    .fromLTRB(start, centerY - radius, end, centerY + radius),
    .circular(radius),
  );
}

void _drawSliderThumb(
  Canvas canvas,
  _SliderPaintGeometry geometry,
  Color color,
) => canvas.drawCircle(
  .new(geometry.thumbX, geometry.centerY),
  _thumbRadius,
  Paint()..color = color,
);

void _drawSliderFocusRing(_SliderFocusRingRequest request) {
  request.canvas.drawCircle(
    .new(request.thumbX, request.size.height / _half),
    _thumbRadius + _focusRingOffset,
    _sliderFocusPaint(request.color),
  );
}

Paint _sliderFocusPaint(Color color) => Paint()
  ..color = color.withValues(alpha: 0.24)
  ..style = .stroke
  ..strokeWidth = _focusRingStrokeWidth;
