import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: AuraSwitch)
Widget auraSwitchUseCase(BuildContext context) {
  return _SwitchDemo(
    size: context.knobs.object.dropdown(
      label: 'size',
      options: AuraSwitchSize.values,
      initialOption: AuraSwitchSize.base,
      labelBuilder: (value) => value.name,
    ),
    disabled: context.knobs.boolean(label: 'disabled', initialValue: false),
    isLoading: context.knobs.boolean(label: 'isLoading', initialValue: false),
  );
}

class _SwitchDemo extends StatefulWidget {
  const _SwitchDemo({
    required this.size,
    required this.disabled,
    required this.isLoading,
  });

  final AuraSwitchSize size;
  final bool disabled;
  final bool isLoading;

  @override
  State<_SwitchDemo> createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<_SwitchDemo> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AuraSwitch(
        value: _value,
        onChanged: (value) => setState(() => _value = value),
        size: widget.size,
        disabled: widget.disabled,
        isLoading: widget.isLoading,
      ),
    );
  }
}
