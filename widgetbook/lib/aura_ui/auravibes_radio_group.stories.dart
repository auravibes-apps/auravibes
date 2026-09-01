// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_radio_group.stories.g.dart';

const component = ComponentMeta(name: 'AuraRadioGroup');
const meta = Meta(RadioGroupDemo.new);

final $RadioGroup = _Story(
  name: 'Radio Group',
  setup: (context, child, args) => constrainStoryWidth(
    Padding(padding: const EdgeInsets.all(16), child: child),
    maxWidth: 420,
  ),
  args: _Args(
    direction: SingleArg(
      Axis.vertical,
      name: 'direction',
      values: const [Axis.vertical, Axis.horizontal],
      labelBuilder: (value) =>
          value == Axis.vertical ? 'vertical' : 'horizontal',
    ),
    tint: NullableEnumArg(null, name: 'tint', values: AuraTint.values),
    showLabel: BoolArg(true, name: 'showLabel'),
    showSubtitles: BoolArg(false, name: 'showSubtitles'),
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
      name: 'Selects Radio',
      run: (tester, args) async {
        await tester.tap(find.text('Light'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates a controlled radio group in vertical and horizontal layouts.
class const RadioGroupDemo({
  super.key,
  required final Axis direction,
  required final AuraTint? tint,
  required final bool showLabel,
  required final bool showSubtitles,
}) extends StatefulWidget {
  @override
  State<RadioGroupDemo> createState() => _RadioGroupDemoState();
}

class _RadioGroupDemoState extends State<RadioGroupDemo> {
  static const List<AuraRadioOption<String>> _options = [
    AuraRadioOption(
      value: 'system',
      label: Text('System'),
      subtitle: Text('Follow system theme'),
      semanticLabel: 'System theme',
    ),
    AuraRadioOption(
      value: 'light',
      label: Text('Light'),
      subtitle: Text('Always use light theme'),
      semanticLabel: 'Light theme',
    ),
    AuraRadioOption(
      value: 'dark',
      label: Text('Dark'),
      subtitle: Text('Always use dark theme'),
      semanticLabel: 'Dark theme',
    ),
  ];
  String? _selectedValue = 'system';

  @override
  Widget build(BuildContext context) {
    return AuraRadioGroup<String>(
      value: _selectedValue,
      onChanged: (value) => setState(() => _selectedValue = value),
      options: widget.showSubtitles
          ? _options
          : _options
                .map(
                  (o) => AuraRadioOption<String>(
                    value: o.value,
                    label: o.label,
                    semanticLabel: o.semanticLabel,
                  ),
                )
                .toList(),
      label: widget.showLabel ? const Text('Select Theme') : null,
      direction: widget.direction,
      tint: widget.tint,
    );
  }
}
