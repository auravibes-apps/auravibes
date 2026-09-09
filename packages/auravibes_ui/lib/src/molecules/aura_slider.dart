import 'dart:math' as math;

import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart' show AuraTint;
import 'package:flutter/widgets.dart';

const _controlHeight = 48.0;
const _trackHeight = 4.0;
const _thumbRadius = 10.0;
const double _thumbDiameter = _thumbRadius * 2;
const _defaultPrecision = 2;
const _maximumPrecision = 20;
const _markLabelHeight = 20.0;
const _alignmentRange = 2.0;
const _focusRingOffset = 3.0;
const _half = 2.0;

class const _AuraSliderIncreaseIntent() extends Intent;

class const _AuraSliderDecreaseIntent() extends Intent;

/// A labeled point on an [AuraLabeledSlider] range.
class AuraSliderMark {
  /// Creates a mark at an in-range value.
  const new({required this.value, this.label});

  /// Mark position in the slider's units.
  final double value;

  /// Optional visible caller-localized label.
  final String? label;
}

/// A slider with a visible label, current value, and range bounds.
class AuraLabeledSlider extends StatelessWidget {
  /// Creates a labeled slider while keeping [AuraSlider] available alone.
  const new({
    required this.value,
    required this.onChanged,
    super.key,
    this.min = 0,
    this.max = 1,
    this.step = 1,
    this.precision = _defaultPrecision,
    this.enabled = true,
    this.label,
    this.semanticLabel,
    this.tint = AuraTint.primary,
    this.valueFormatter,
    this.marks = const [],
  }) : assert(min <= max, 'min must be less than or equal to max'),
       assert(step > 0, 'step must be greater than zero'),
       assert(precision >= 0, 'precision must not be negative'),
       assert(precision <= _maximumPrecision, 'precision must not exceed 20');

  /// Current controlled value.
  final double value;

  /// Inclusive lower bound.
  final double min;

  /// Inclusive upper bound.
  final double max;

  /// Selectable increment, anchored at [min].
  final double step;

  /// Number of decimal places used for rounding and display.
  final int precision;

  /// Called with the next value after user interaction.
  final ValueChanged<double>? onChanged;

  /// Whether the slider accepts user interaction.
  final bool enabled;

  /// Visible field label.
  final String? label;

  /// Accessible label announced for the slider.
  final String? semanticLabel;

  /// Aura tint used for the active track and thumb.
  final AuraTint tint;

  /// Optional display formatter for current and boundary values.
  final String Function(double value)? valueFormatter;

  /// Optional static labels placed at meaningful positions in the range.
  final List<AuraSliderMark> marks;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = _normalizeValue(value, min, max, step, precision);
    final format =
        valueFormatter ?? (value) => _formatSliderValue(value, precision);
    final spacing = context.auraTheme.spacing;
    if (marks.any((mark) => mark.value < min || mark.value > max)) {
      throw ArgumentError('Slider marks must be inside the configured range.');
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            if (label case final label?)
              Expanded(
                child: AuraText(child: Text(label), style: .bodySmall),
              )
            else
              const Spacer(),
            AuraText(child: Text(format(effectiveValue)), style: .bodySmall),
          ],
        ),
        SizedBox(height: spacing.xs),
        AuraSlider(
          value: effectiveValue,
          onChanged: onChanged,
          min: min,
          max: max,
          step: step,
          precision: precision,
          enabled: enabled,
          semanticLabel: semanticLabel ?? label,
          tint: tint,
        ),
        if (marks.isNotEmpty) ...[
          SizedBox(height: spacing.xs),
          SizedBox(
            height: _markLabelHeight,
            child: Stack(
              clipBehavior: .none,
              children: [
                for (final mark in marks)
                  Align(
                    alignment: Alignment(
                      min == max
                          ? 0
                          : ((mark.value - min) / (max - min)) *
                                    _alignmentRange -
                                1,
                      0,
                    ),
                    child: AuraText(
                      child: Text(mark.label ?? format(mark.value)),
                      style: .caption,
                    ),
                  ),
              ],
            ),
          ),
        ],
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            AuraText(child: Text(format(min)), style: .caption),
            AuraText(child: Text(format(max)), style: .caption),
          ],
        ),
      ],
    );
  }
}

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
    final auraColors = context.auraColors;
    final onChanged = widget.onChanged;
    final isEnabled =
        widget.enabled &&
        AuraInteractionScope.of(context).allowsValueChanges &&
        onChanged != null;
    final effectiveValue = _normalizeValue(
      widget.value,
      widget.min,
      widget.max,
      widget.step,
      widget.precision,
    );
    final increasedValue = _normalizeValue(
      effectiveValue + widget.step,
      widget.min,
      widget.max,
      widget.step,
      widget.precision,
    );
    final decreasedValue = _normalizeValue(
      effectiveValue - widget.step,
      widget.min,
      widget.max,
      widget.step,
      widget.precision,
    );

    void changeValue(double nextValue) {
      if (!isEnabled) {
        return;
      }
      onChanged(
        _normalizeValue(
          nextValue,
          widget.min,
          widget.max,
          widget.step,
          widget.precision,
        ),
      );
    }

    void increase() => changeValue(increasedValue);
    void decrease() => changeValue(decreasedValue);

    return Semantics(
      child: FocusableActionDetector(
        enabled: isEnabled,
        shortcuts: const {
          SingleActivator(.arrowRight): _AuraSliderIncreaseIntent(),
          SingleActivator(.arrowUp): _AuraSliderIncreaseIntent(),
          SingleActivator(.arrowLeft): _AuraSliderDecreaseIntent(),
          SingleActivator(.arrowDown): _AuraSliderDecreaseIntent(),
        },
        actions: {
          _AuraSliderIncreaseIntent: CallbackAction<_AuraSliderIncreaseIntent>(
            onInvoke: (_) {
              increase();

              return null;
            },
          ),
          _AuraSliderDecreaseIntent: CallbackAction<_AuraSliderDecreaseIntent>(
            onInvoke: (_) {
              decrease();

              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) => setState(() => _isFocused = value),
        mouseCursor: isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final activeColor = auraColors.colorFor(widget.tint);
            final inactiveColor = auraColors.outlineVariant;
            final thumbX = _thumbPosition(
              effectiveValue,
              width,
              widget.min,
              widget.max,
            );

            return GestureDetector(
              child: SizedBox(
                height: _controlHeight,
                child: CustomPaint(
                  painter: _AuraSliderPainter(
                    value: effectiveValue,
                    min: widget.min,
                    max: widget.max,
                    activeColor: isEnabled ? activeColor : inactiveColor,
                    inactiveColor: inactiveColor,
                  ),
                  foregroundPainter: isEnabled && _isFocused
                      ? _AuraSliderFocusRingPainter(
                          thumbX: thumbX,
                          color: activeColor,
                        )
                      : null,
                ),
              ),
              onTapDown: isEnabled
                  ? (details) => changeValue(
                      _valueAtPosition(
                        details.localPosition.dx,
                        width,
                        widget.min,
                        widget.max,
                        effectiveValue,
                      ),
                    )
                  : null,
              onHorizontalDragUpdate: isEnabled
                  ? (details) => changeValue(
                      _valueAtPosition(
                        details.localPosition.dx,
                        width,
                        widget.min,
                        widget.max,
                        effectiveValue,
                      ),
                    )
                  : null,
              behavior: .opaque,
            );
          },
        ),
      ),
      enabled: isEnabled,
      slider: true,
      label: widget.semanticLabel,
      value: effectiveValue.toString(),
      increasedValue: isEnabled ? increasedValue.toString() : null,
      decreasedValue: isEnabled ? decreasedValue.toString() : null,
      onIncrease: isEnabled ? increase : null,
      onDecrease: isEnabled ? decrease : null,
    );
  }
}

double _clampValue(double value, double min, double max) =>
    value.clamp(min, max);

String _formatSliderValue(double value, int precision) =>
    value.toStringAsFixed(precision);

double _normalizeValue(
  double value,
  double min,
  double max,
  double step,
  int precision,
) {
  final clamped = _clampValue(value, min, max);
  if (clamped == min || clamped == max) return clamped;
  final stepped = min + ((clamped - min) / step).round() * step;
  final scale = math.pow(10, precision).toDouble();
  final rounded = (stepped * scale).round() / scale;

  return double.parse(
    _clampValue(rounded, min, max).toStringAsFixed(precision),
  );
}

double _thumbPosition(double value, double width, double min, double max) {
  final trackStart = width < _thumbDiameter ? width / 2 : _thumbRadius;
  final trackEnd = width < _thumbDiameter ? width / 2 : width - _thumbRadius;
  final fraction = min == max
      ? 0.5
      : ((value - min) / (max - min)).clamp(0.0, 1.0);

  return trackStart + (trackEnd - trackStart) * fraction;
}

double _valueAtPosition(
  double position,
  double width,
  double min,
  double max,
  double currentValue,
) {
  if (min == max || !width.isFinite || width <= _thumbDiameter) {
    return currentValue;
  }
  final fraction = ((position - _thumbRadius) / (width - _thumbDiameter)).clamp(
    0.0,
    1.0,
  );

  return min + (max - min) * fraction;
}

class const _AuraSliderPainter({
  required final double value,
  required final double min,
  required final double max,
  required final Color activeColor,
  required final Color inactiveColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final trackStart = size.width < _thumbDiameter
        ? size.width / 2
        : _thumbRadius;
    final trackEnd = size.width < _thumbDiameter
        ? size.width / 2
        : size.width - _thumbRadius;
    final thumbX = _thumbPosition(value, size.width, min, max);
    const trackRadius = _trackHeight / 2;
    final trackRect = Rect.fromLTRB(
      trackStart,
      centerY - trackRadius,
      trackEnd,
      centerY + trackRadius,
    );
    final trackRRect = RRect.fromRectAndRadius(
      trackRect,
      const Radius.circular(trackRadius),
    );

    canvas.drawRRect(trackRRect, Paint()..color = inactiveColor);
    if (thumbX > trackStart) {
      canvas.drawRRect(
        .fromRectAndRadius(
          .fromLTRB(
            trackStart,
            centerY - trackRadius,
            thumbX,
            centerY + trackRadius,
          ),
          const Radius.circular(trackRadius),
        ),
        Paint()..color = activeColor,
      );
    }
    canvas.drawCircle(
      .new(thumbX, centerY),
      _thumbRadius,
      Paint()..color = activeColor,
    );
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
  void paint(Canvas canvas, Size size) {
    final focusPaint = Paint()
      ..color = color.withValues(alpha: 0.24)
      ..style = .stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      .new(thumbX, size.height / _half),
      _thumbRadius + _focusRingOffset,
      focusPaint,
    );
  }

  @override
  bool shouldRepaint(_AuraSliderFocusRingPainter oldDelegate) =>
      thumbX != oldDelegate.thumbX || color != oldDelegate.color;
}
