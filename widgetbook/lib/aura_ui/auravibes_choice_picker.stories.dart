import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_choice_picker.stories.bridge.g.dart';
part 'auravibes_choice_picker.stories.g.dart';

const _maxAllowedChoicePickerSelections = 2;

const _component = ComponentMeta(name: 'AuraChoicePicker');
const _meta = Meta(ChoicePickerDemo.new);

abstract final class _StorybookDefinitions {
  static final $ChoicePicker = _Story(
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
          .mutuallyExclusive => 'Single selection',
          .multipleSelection => 'Multiple selection',
        },
      ),
      tint: NullableEnumArg(null, name: 'tint', values: AuraTint.values),
      presentation: EnumArg(
        AuraChoicePickerPresentation.list,
        values: AuraChoicePickerPresentation.values,
      ),
    ),
    scenarios: [
      _Scenario(
        name: 'Compact Phone',
        modes: [ViewportMode(StoryHelpers.compactPhoneViewport)],
      ),
      _Scenario(
        name: 'Landscape Phone',
        modes: [ViewportMode(StoryHelpers.landscapePhoneViewport)],
      ),
      _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(.rtl)]),
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
}

/// Demonstrates controlled single- and multiple-selection choices.
class const ChoicePickerDemo({
  super.key,
  required final AuraChoicePickerVariant variant,
  required final AuraTint? tint,
  final AuraChoicePickerPresentation presentation =
      AuraChoicePickerPresentation.list,
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
  Widget build(BuildContext context) => _ChoicePickerControl(
    variant: widget.variant,
    tint: widget.tint,
    presentation: widget.presentation,
    value: _value,
    onChanged: _select,
  );

  void _select(List<String> value) => setState(() => _value = value);
}

class const _ChoicePickerControl({
  required final AuraChoicePickerVariant variant,
  required final AuraTint? tint,
  required final AuraChoicePickerPresentation presentation,
  required final List<String> value,
  required final ValueChanged<List<String>> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.auraColors.surface,
    child: _ChoicePickerField(
      data: .new(
        variant: variant,
        tint: tint,
        presentation: presentation,
        value: value,
        onChanged: onChanged,
      ),
    ),
  );
}

class _ChoicePickerFieldData({
  required final AuraChoicePickerVariant variant,
  required final AuraTint? tint,
  required final AuraChoicePickerPresentation presentation,
  required final List<String> value,
  required final ValueChanged<List<String>> onChanged,
}) {
  final AuraChoicePicker<String> picker = .new(
    options: _ChoicePickerDemoState._options,
    value: variant == AuraChoicePickerVariant.mutuallyExclusive
        ? value.take(1).toList()
        : value,
    onChanged: onChanged,
    variant: variant,
    presentation: presentation,
    maxAllowedSelections: variant == AuraChoicePickerVariant.multipleSelection
        ? _maxAllowedChoicePickerSelections
        : null,
    label: const Text('Preferred contact method'),
    tint: tint,
  );
}

class const _ChoicePickerField({required final _ChoicePickerFieldData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => data.picker;
}
