// Required: Widgetbook stories group related story widgets.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_button_group_single.stories.g.dart';

const component = ComponentMeta(name: 'AuraButtonGroup');
const meta = Meta(SingleSelectionDemo.new);

final $SingleSelectionRadio = _Story(
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
      modes: [ViewportMode(landscapePhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(
      name: 'Selects Option',
      run: (tester, args) async {
        await tester.tap(find.text('Option 2'));
        await tester.pump(const Duration(milliseconds: 1000));
      },
    ),
  ],
);

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
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuraButtonGroup<String>.single(
          items: const [
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
          ],
          selectedValue: _selectedValue,
          onChanged: (value) => setState(() => _selectedValue = value),
          key: ValueKey(_selectedValue),
          size: widget.size,
          variant: widget.variant,
          orientation: widget.orientation,
          disabled: widget.disabled,
          isLoading: widget.isLoading,
        ),
        const SizedBox(height: 16),
        Text(
          'Selected: $_selectedValue',
          style: TextStyle(color: context.auraColors.onSurface),
        ),
      ],
    );
  }
}
