import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Choice Picker', type: AuraChoicePicker)
Widget choicePickerUseCase(BuildContext context) {
  return _ChoicePickerDemo(
    variant: context.knobs.object.dropdown(
      label: 'variant',
      options: AuraChoicePickerVariant.values,
      initialOption: AuraChoicePickerVariant.mutuallyExclusive,
      labelBuilder: (value) => switch (value) {
        AuraChoicePickerVariant.mutuallyExclusive => 'Single selection',
        AuraChoicePickerVariant.multipleSelection => 'Multiple selection',
      },
    ),
    tint: context.knobs.objectOrNull.dropdown(
      label: 'tint',
      options: AuraTint.values,
      initialOption: null,
      labelBuilder: (value) => value.name,
    ),
  );
}

class _ChoicePickerDemo extends StatefulWidget {
  const _ChoicePickerDemo({required this.variant, required this.tint});

  final AuraChoicePickerVariant variant;
  final AuraTint? tint;

  @override
  State<_ChoicePickerDemo> createState() => _ChoicePickerDemoState();
}

class _ChoicePickerDemoState extends State<_ChoicePickerDemo> {
  static const List<AuraChoiceOption<String>> _options = [
    AuraChoiceOption(value: 'email', label: Text('Email')),
    AuraChoiceOption(value: 'phone', label: Text('Phone')),
    AuraChoiceOption(value: 'post', label: Text('Post'), disabled: true),
  ];
  List<String> _value = ['email'];

  @override
  Widget build(BuildContext context) {
    final maxAllowedSelections =
        widget.variant == AuraChoicePickerVariant.multipleSelection ? 2 : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AuraChoicePicker<String>(
          options: _options,
          value: widget.variant == AuraChoicePickerVariant.mutuallyExclusive
              ? _value.take(1).toList()
              : _value,
          onChanged: (value) => setState(() => _value = value),
          variant: widget.variant,
          maxAllowedSelections: maxAllowedSelections,
          label: const Text('Preferred contact method'),
          tint: widget.tint,
        ),
      ),
    );
  }
}
