import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Radio Group', type: AuraRadioGroup)
Widget radioGroupUseCase(BuildContext context) {
  return _RadioGroupDemo(
    direction: context.knobs.object.dropdown(
      label: 'direction',
      options: [Axis.vertical, Axis.horizontal],
      initialOption: Axis.vertical,
      labelBuilder: (value) =>
          value == Axis.vertical ? 'vertical' : 'horizontal',
    ),
    colorVariant: context.knobs.objectOrNull.dropdown(
      label: 'colorVariant',
      options: AuraColorVariant.values,
      initialOption: null,
      labelBuilder: (value) => value.name,
    ),
    showLabel: context.knobs.boolean(label: 'showLabel', initialValue: true),
    showSubtitles: context.knobs.boolean(
      label: 'showSubtitles',
      initialValue: false,
    ),
  );
}

class _RadioGroupDemo extends StatefulWidget {
  const _RadioGroupDemo({
    required this.direction,
    required this.colorVariant,
    required this.showLabel,
    required this.showSubtitles,
  });

  final Axis direction;
  final AuraColorVariant? colorVariant;
  final bool showLabel;
  final bool showSubtitles;

  @override
  State<_RadioGroupDemo> createState() => _RadioGroupDemoState();
}

class _RadioGroupDemoState extends State<_RadioGroupDemo> {
  String? _selectedValue;

  static final List<AuraRadioOption<String>> _options = [
    const AuraRadioOption<String>(
      value: 'system',
      label: Text('System'),
      subtitle: Text('Follow system theme'),
    ),
    const AuraRadioOption<String>(
      value: 'light',
      label: Text('Light'),
      subtitle: Text('Always use light theme'),
    ),
    const AuraRadioOption<String>(
      value: 'dark',
      label: Text('Dark'),
      subtitle: Text('Always use dark theme'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AuraRadioGroup<String>(
          value: _selectedValue,
          onChanged: (value) => setState(() => _selectedValue = value),
          options: widget.showSubtitles
              ? _options
              : _options
                    .map(
                      (o) => AuraRadioOption<String>(
                        value: o.value,
                        label: o.label,
                      ),
                    )
                    .toList(),
          direction: widget.direction,
          colorVariant: widget.colorVariant,
          label: widget.showLabel ? const Text('Select Theme') : null,
        ),
      ),
    );
  }
}
