import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart' show AuraTint;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const _controlHeight = 48.0;
const _trackHeight = 4.0;
const _thumbRadius = 10.0;
const double _thumbDiameter = _thumbRadius * 2;
const _semanticStepCount = 20.0;

class _AuraSliderIncreaseIntent extends Intent {
  const _AuraSliderIncreaseIntent();
}

class _AuraSliderDecreaseIntent extends Intent {
  const _AuraSliderDecreaseIntent();
}

/// A controlled, themed slider for selecting a numeric value.
class AuraSlider extends StatefulWidget {
  /// Creates a slider with [value] constrained to [min] and [max].
  const AuraSlider({
    required this.value,
    required this.onChanged,
    super.key,
    this.min = 0,
    this.max = 1,
    this.enabled = true,
    this.semanticLabel,
    this.tint = AuraTint.primary,
  }) : assert(min <= max, 'min must be less than or equal to max');

  /// Current controlled value.
  final double value;

  /// Inclusive lower bound for [value].
  final double min;

  /// Inclusive upper bound for [value].
  final double max;

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
    final isEnabled = widget.enabled && onChanged != null;
    final effectiveValue = _clampValue(widget.value, widget.min, widget.max);
    final semanticStep = (widget.max - widget.min) / _semanticStepCount;
    final increasedValue = _clampValue(
      effectiveValue + semanticStep,
      widget.min,
      widget.max,
    );
    final decreasedValue = _clampValue(
      effectiveValue - semanticStep,
      widget.min,
      widget.max,
    );

    void changeValue(double nextValue) {
      if (!widget.enabled || onChanged == null) {
        return;
      }
      onChanged(_clampValue(nextValue, widget.min, widget.max));
    }

    void increase() => changeValue(increasedValue);
    void decrease() => changeValue(decreasedValue);

    return Semantics(
      child: FocusableActionDetector(
        enabled: isEnabled,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowRight):
              _AuraSliderIncreaseIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp):
              _AuraSliderIncreaseIntent(),
          SingleActivator(LogicalKeyboardKey.arrowLeft):
              _AuraSliderDecreaseIntent(),
          SingleActivator(LogicalKeyboardKey.arrowDown):
              _AuraSliderDecreaseIntent(),
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
              behavior: HitTestBehavior.opaque,
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

class _AuraSliderPainter extends CustomPainter {
  const _AuraSliderPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double value;
  final double min;
  final double max;
  final Color activeColor;
  final Color inactiveColor;

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
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
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
      Offset(thumbX, centerY),
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

class _AuraSliderFocusRingPainter extends CustomPainter {
  const _AuraSliderFocusRingPainter({
    required this.thumbX,
    required this.color,
  });

  final double thumbX;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final focusPaint = Paint()
      ..color = color.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(thumbX, size.height / 2),
      _thumbRadius + 3,
      focusPaint,
    );
  }

  @override
  bool shouldRepaint(_AuraSliderFocusRingPainter oldDelegate) =>
      thumbX != oldDelegate.thumbX || color != oldDelegate.color;
}
