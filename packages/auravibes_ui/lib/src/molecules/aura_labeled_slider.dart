part of 'aura_slider.dart';

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
