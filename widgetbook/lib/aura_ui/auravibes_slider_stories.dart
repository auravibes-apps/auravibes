import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _minValue = 0.0;
const _maxValue = 100.0;
const _initialValue = 50.0;
const _sliderWidth = 320.0;

@widgetbook.UseCase(name: 'Default', type: AuraSlider)
Widget auraSliderUseCase(BuildContext context) {
  return _SliderDemo(
    enabled: context.knobs.boolean(label: 'enabled', initialValue: true),
    tint: context.knobs.object.dropdown(
      label: 'tint',
      options: AuraTint.values,
      initialOption: AuraTint.primary,
      labelBuilder: (value) => value.name,
    ),
  );
}

class _SliderDemo extends StatefulWidget {
  const _SliderDemo({required this.enabled, required this.tint});

  final bool enabled;
  final AuraTint tint;

  @override
  State<_SliderDemo> createState() => _SliderDemoState();
}

class _SliderDemoState extends State<_SliderDemo> {
  double _value = _initialValue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _sliderWidth,
        child: AuraSlider(
          value: _value,
          onChanged: widget.enabled
              ? (value) => setState(() => _value = value)
              : null,
          min: _minValue,
          max: _maxValue,
          enabled: widget.enabled,
          semanticLabel: 'Example slider',
          tint: widget.tint,
        ),
      ),
    );
  }
}
