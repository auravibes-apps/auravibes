// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Single Radio', type: AuraRadio)
Widget singleRadioUseCase(BuildContext context) {
  return _SingleRadioDemo(
    tint: context.knobs.objectOrNull.dropdown(
      label: 'tint',
      options: AuraTint.values,
      initialOption: null,
      labelBuilder: (value) => value.name,
    ),
    disabled: context.knobs.boolean(label: 'disabled', initialValue: false),
  );
}

class _SingleRadioDemo extends StatefulWidget {
  const _SingleRadioDemo({required this.tint, required this.disabled});

  final AuraTint? tint;
  final bool disabled;

  @override
  State<_SingleRadioDemo> createState() => _SingleRadioDemoState();
}

class _SingleRadioDemoState extends State<_SingleRadioDemo> {
  String? _selectedValue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuraRadio<String>(
            value: 'option1',
            groupValue: _selectedValue,
            onChanged: widget.disabled
                ? null
                : (value) => setState(() => _selectedValue = value),
            tint: widget.tint,
            disabled: widget.disabled,
          ),
          const SizedBox(height: 16),
          Text(
            'Selected: ${_selectedValue ?? 'none'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
