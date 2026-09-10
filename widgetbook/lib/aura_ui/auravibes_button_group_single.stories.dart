// Required: Widgetbook stories group related story widgets.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_button_group_single.stories.bridge.g.dart';
part 'auravibes_button_group_single.stories.g.dart';

const _component = ComponentMeta(name: 'AuraButtonGroup');
const _meta = Meta(SingleSelectionDemo.new);

abstract final class _StorybookDefinitions {
  static final $SingleSelectionRadio = _Story(
    name: 'Single Selection (Radio)',
    setup: (context, child, args) =>
        Padding(padding: const EdgeInsets.all(16), child: child),
    args: _Args(
      size: EnumArg(
        AuraButtonGroupSize.base,
        name: 'size',
        values: AuraButtonGroupSize.values,
      ),
      variant: EnumArg(
        AuraButtonGroupVariant.outlined,
        name: 'variant',
        values: AuraButtonGroupVariant.values,
      ),
      orientation: EnumArg(
        Axis.horizontal,
        name: 'orientation',
        values: Axis.values,
      ),
      disabled: BoolArg(false, name: 'disabled'),
      isLoading: BoolArg(false, name: 'isLoading'),
    ),
    scenarios: [
      _Scenario(
        name: 'Landscape Phone',
        modes: [ViewportMode(StoryHelpers.landscapePhoneViewport)],
      ),
      _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(.rtl)]),
      _Scenario(
        name: 'Selects Option',
        run: (tester, args) async {
          await tester.tap(find.text('Option 2'));
          await tester.pump(const Duration(milliseconds: 1000));
        },
      ),
    ],
  );
}

/// Demonstrates a single-selection button group.
class const SingleSelectionDemo({
  super.key,
  required final AuraButtonGroupSize size,
  required final AuraButtonGroupVariant variant,
  required final Axis orientation,
  required final bool disabled,
  required final bool isLoading,
}) extends StatefulWidget {
  @override
  State<SingleSelectionDemo> createState() => _SingleSelectionDemoState();
}

class _SingleSelectionDemoState extends State<SingleSelectionDemo> {
  String? _selectedValue = 'option1';

  @override
  Widget build(BuildContext context) => _SingleSelectionPreview(
    demo: widget,
    selectedValue: _selectedValue,
    onChanged: _select,
  );

  void _select(String? value) => setState(() => _selectedValue = value);
}

class const _SingleSelectionPreview({
  required final SingleSelectionDemo demo,
  required final String? selectedValue,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      _SingleSelectionControl(
        demo: demo,
        selectedValue: selectedValue,
        onChanged: onChanged,
      ),
      const SizedBox(height: 16),
      Text(
        'Selected: $selectedValue',
        style: .new(color: context.auraColors.onSurface),
      ),
    ],
  );
}

class const _SingleSelectionControl({
  required final SingleSelectionDemo demo,
  required final String? selectedValue,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  static const List<AuraButtonGroupItem<String>> _items = [
    AuraButtonGroupItem(
      value: 'option1',
      child: Text('Option 1'),
      semanticLabel: 'Option 1',
    ),
    AuraButtonGroupItem(
      value: 'option2',
      child: Text('Option 2'),
      semanticLabel: 'Option 2',
    ),
    AuraButtonGroupItem(
      value: 'option3',
      child: Text('Option 3'),
      semanticLabel: 'Option 3',
    ),
  ];

  @override
  Widget build(BuildContext context) => AuraButtonGroup<String>.single(
    items: _items,
    selectedValue: selectedValue,
    onChanged: onChanged,
    key: ValueKey(selectedValue),
    size: demo.size,
    variant: demo.variant,
    orientation: demo.orientation,
    disabled: demo.disabled,
    isLoading: demo.isLoading,
  );
}
