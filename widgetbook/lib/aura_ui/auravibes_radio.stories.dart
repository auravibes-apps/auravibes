// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_radio.stories.g.dart';

const component = ComponentMeta(name: 'AuraRadio');

class _RadioInput {
  const _RadioInput({
    required this.tint,
    required this.disabled,
    required this.itemCount,
  });

  final AuraTint? tint;
  final bool disabled;
  final int itemCount;
}

const meta = Meta(SingleRadioDemo.new, argsType: _RadioInput.new);

final _Defaults radioDefaults = _Defaults(
  builder: (context, args) => SingleRadioDemo(
    tint: args.tint,
    disabled: args.disabled,
    itemCount: args.itemCount,
  ),
);

final $SingleRadio = _Story(
  name: 'Single Radio',
  setup: (context, child, args) => constrainStoryWidth(child),
  args: _Args(
    tint: NullableEnumArg(null, name: 'tint', values: AuraTint.values),
    disabled: BoolArg(false, name: 'disabled'),
    itemCount: IntArg(
      3,
      name: 'item count',
      style: const SliderIntArgStyle(min: 1, max: 6, divisions: 5),
    ),
  ),
  scenarios: [
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(
      name: 'Selects Radio',
      run: (tester, args) async {
        await tester.tap(find.byType(AuraRadio<String>).at(1));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates a single controlled radio button.
class SingleRadioDemo extends StatefulWidget {
  const SingleRadioDemo({
    super.key,
    required this.tint,
    required this.disabled,
    required this.itemCount,
  });

  final AuraTint? tint;
  final bool disabled;
  final int itemCount;

  @override
  State<SingleRadioDemo> createState() => _SingleRadioDemoState();
}

class _SingleRadioDemoState extends State<SingleRadioDemo> {
  String? _selectedValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < widget.itemCount; index++) ...[
          AuraRadio<String>(
            value: 'option${index + 1}',
            groupValue: _selectedValue,
            onChanged: widget.disabled
                ? null
                : (value) => setState(() => _selectedValue = value),
            tint: widget.tint,
            disabled: widget.disabled,
            semanticLabel: 'Option ${index + 1}',
          ),
          if (index < widget.itemCount - 1) const SizedBox(height: 8),
        ],
        Text(
          'Selected: ${_selectedValue ?? 'none'}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
