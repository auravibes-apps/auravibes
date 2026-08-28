// Required: Widgetbook stories group related story widgets.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_button_group_multi.stories.g.dart';

const component = ComponentMeta(name: 'AuraButtonGroup');
const meta = Meta(MultiSelectionDemo.new);

final $MultiSelectionToggle = _Story(
  name: 'Multi Selection (Toggle)',
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
      name: 'Toggles Option',
      run: (tester, args) async {
        await tester.tap(find.byIcon(Icons.format_italic));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates a multi-selection toggle button group.
class MultiSelectionDemo extends StatefulWidget {
  const MultiSelectionDemo({
    super.key,
    required this.size,
    required this.variant,
    required this.orientation,
    required this.disabled,
    required this.isLoading,
  });

  final AuraButtonGroupSize size;
  final AuraButtonGroupVariant variant;
  final Axis orientation;
  final bool disabled;
  final bool isLoading;

  @override
  State<MultiSelectionDemo> createState() => _MultiSelectionDemoState();
}

class _MultiSelectionDemoState extends State<MultiSelectionDemo> {
  Set<String> _selectedValues = {'bold'};

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuraButtonGroup<String>.multi(
          items: const [
            AuraButtonGroupItem(
              value: 'bold',
              child: Icon(Icons.format_bold),
              semanticLabel: 'Bold',
            ),
            AuraButtonGroupItem(
              value: 'italic',
              child: Icon(Icons.format_italic),
              semanticLabel: 'Italic',
            ),
            AuraButtonGroupItem(
              value: 'underline',
              child: Icon(Icons.format_underline),
              semanticLabel: 'Underline',
            ),
          ],
          selectedValues: _selectedValues,
          onMultiChanged: (values) => setState(() => _selectedValues = values),
          size: widget.size,
          variant: widget.variant,
          orientation: widget.orientation,
          disabled: widget.disabled,
          isLoading: widget.isLoading,
        ),
        const SizedBox(height: 16),
        Text(
          'Selected: ${_selectedValues.join(', ')}',
          style: TextStyle(color: context.auraColors.onSurface),
        ),
      ],
    );
  }
}
