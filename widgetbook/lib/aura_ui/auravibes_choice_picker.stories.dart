import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_choice_picker.stories.g.dart';

const component = ComponentMeta(name: 'AuraChoicePicker');
const meta = Meta(ChoicePickerDemo.new);

final $ChoicePicker = _Story(
  name: 'Choice Picker',
  setup: (context, child, args) => SizedBox(
    width: 360,
    height: 260,
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
  args: _Args(
    variant: EnumArg(
      AuraChoicePickerVariant.mutuallyExclusive,
      name: 'variant',
      values: AuraChoicePickerVariant.values,
      labelBuilder: (value) => switch (value) {
        AuraChoicePickerVariant.mutuallyExclusive => 'Single selection',
        AuraChoicePickerVariant.multipleSelection => 'Multiple selection',
      },
    ),
    tint: NullableEnumArg(null, name: 'tint', values: AuraTint.values),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(
      name: 'Landscape Phone',
      modes: [ViewportMode(landscapePhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
    _Scenario(
      name: 'Selects Choice',
      run: (tester, args) async {
        await tester.tap(find.text('Phone'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates controlled single- and multiple-selection choices.
class const ChoicePickerDemo({
  super.key,
  required final AuraChoicePickerVariant variant,
  required final AuraTint? tint,
}) extends StatefulWidget {
  @override
  State<ChoicePickerDemo> createState() => _ChoicePickerDemoState();
}

class _ChoicePickerDemoState extends State<ChoicePickerDemo> {
  static const List<AuraChoiceOption<String>> _options = [
    AuraChoiceOption(
      value: 'email',
      label: AuraText(child: Text('Email'), style: .bodySmall),
    ),
    AuraChoiceOption(
      value: 'phone',
      label: AuraText(child: Text('Phone'), style: .bodySmall),
    ),
    AuraChoiceOption(
      value: 'post',
      label: AuraText(child: Text('Post'), style: .bodySmall),
      disabled: true,
    ),
  ];
  List<String> _value = ['email'];

  @override
  Widget build(BuildContext context) {
    final maxAllowedSelections =
        widget.variant == AuraChoicePickerVariant.multipleSelection ? 2 : null;

    return ColoredBox(
      color: context.auraColors.surface,
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
    );
  }
}
