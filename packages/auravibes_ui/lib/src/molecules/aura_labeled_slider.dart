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
    _validateSliderMarks(this);

    return _AuraLabeledSliderContent(
      slider: this,
      effectiveValue: _effectiveSliderValue(this),
      format: _sliderFormatter(this),
      spacing: context.auraTheme.spacing,
    );
  }
}

void _validateSliderMarks(AuraLabeledSlider slider) {
  if (slider.marks.any(
    (mark) => mark.value < slider.min || mark.value > slider.max,
  )) {
    throw ArgumentError('Slider marks must be inside the configured range.');
  }
}

double _effectiveSliderValue(AuraLabeledSlider slider) => _normalizeValue((
  value: slider.value,
  min: slider.min,
  max: slider.max,
  step: slider.step,
  precision: slider.precision,
));

String Function(double) _sliderFormatter(AuraLabeledSlider slider) =>
    slider.valueFormatter ??
    (value) => _formatSliderValue(value, slider.precision);

class _AuraLabeledSliderContent extends StatelessWidget {
  _AuraLabeledSliderContent({
    required AuraLabeledSlider slider,
    required double effectiveValue,
    required String Function(double) format,
    required AuraSpacingScale spacing,
  }) : _child = Column(
         crossAxisAlignment: .stretch,
         children: [
           _AuraLabeledSliderHeaderAndControl(
             slider: slider,
             effectiveValue: effectiveValue,
             format: format,
           ),
           _AuraLabeledSliderFooter(
             slider: slider,
             format: format,
             spacing: spacing,
           ),
         ],
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraLabeledSliderFooter({
  required final AuraLabeledSlider slider,
  required final String Function(double) format,
  required final AuraSpacingScale spacing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _AuraLabeledSliderMarksSection(
        slider: slider,
        format: format,
        spacing: spacing,
      ),
      _AuraLabeledSliderBounds(slider: slider, format: format),
    ],
  );
}

class const _AuraLabeledSliderHeaderAndControl({
  required final AuraLabeledSlider slider,
  required final double effectiveValue,
  required final String Function(double) format,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.auraTheme.spacing;

    return Column(
      children: [
        _AuraLabeledSliderHeader(
          label: slider.label,
          value: format(effectiveValue),
        ),
        SizedBox(height: spacing.xs),
        _AuraLabeledSliderControl(slider: slider, value: effectiveValue),
      ],
    );
  }
}

class const _AuraLabeledSliderMarksSection({
  required final AuraLabeledSlider slider,
  required final String Function(double) format,
  required final AuraSpacingScale spacing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => slider.marks.isEmpty
      ? const SizedBox.shrink()
      : Column(
          children: [
            SizedBox(height: spacing.xs),
            _AuraLabeledSliderMarks(slider: slider, format: format),
          ],
        );
}

class const _AuraLabeledSliderHeader({
  required final String? label,
  required final String value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (label case final label?)
        Expanded(
          child: AuraText(child: Text(label), style: .bodySmall),
        )
      else
        const Spacer(),
      AuraText(child: Text(value), style: .bodySmall),
    ],
  );
}

class const _AuraLabeledSliderMarks({
  required final AuraLabeledSlider slider,
  required final String Function(double) format,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: _markLabelHeight,
    child: Stack(
      clipBehavior: .none,
      children: [
        for (final mark in slider.marks)
          _AuraLabeledSliderMark(mark: mark, slider: slider, format: format),
      ],
    ),
  );
}

class const _AuraLabeledSliderControl({
  required final AuraLabeledSlider slider,
  required final double value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraSlider(
    value: value,
    onChanged: slider.onChanged,
    min: slider.min,
    max: slider.max,
    step: slider.step,
    precision: slider.precision,
    enabled: slider.enabled,
    semanticLabel: slider.semanticLabel ?? slider.label,
    tint: slider.tint,
  );
}

class const _AuraLabeledSliderMark({
  required final AuraSliderMark mark,
  required final AuraLabeledSlider slider,
  required final String Function(double) format,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: _markAlignment(slider, mark),
    child: _AuraLabeledSliderMarkText(mark: mark, format: format),
  );
}

class const _AuraLabeledSliderMarkText({
  required final AuraSliderMark mark,
  required final String Function(double) format,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraText(child: Text(mark.label ?? format(mark.value)), style: .caption);
}

Alignment _markAlignment(AuraLabeledSlider slider, AuraSliderMark mark) {
  if (slider.min == slider.max) return Alignment.center;

  final progress = (mark.value - slider.min) / (slider.max - slider.min);

  return Alignment(progress * _alignmentRange - 1, 0);
}

class const _AuraLabeledSliderBounds({
  required final AuraLabeledSlider slider,
  required final String Function(double) format,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: .spaceBetween,
    children: [
      AuraText(child: Text(format(slider.min)), style: .caption),
      AuraText(child: Text(format(slider.max)), style: .caption),
    ],
  );
}
