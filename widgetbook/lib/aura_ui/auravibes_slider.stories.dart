import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_slider.stories.g.dart';

const _minValue = 0.0;
const _maxValue = 100.0;
const _initialValue = 50.0;
const _sliderWidth = 320.0;

const component = ComponentMeta(name: 'AuraSlider');
const meta = Meta(SliderDemo.new);

final $Default = _Story(
  name: 'Default',
  setup: (context, child, args) => SizedBox(width: _sliderWidth, child: child),
  args: _Args(
    enabled: BoolArg(true, name: 'enabled'),
    tint: EnumArg(AuraTint.primary, name: 'tint', values: AuraTint.values),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(
      name: 'Changes Value',
      run: (tester, args) async {
        await tester.drag(find.byType(AuraSlider), const Offset(80, 0));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates an interactive slider with enabled and tinted states.
class const SliderDemo({
  super.key,
  required final bool enabled,
  required final AuraTint tint,
}) extends StatefulWidget {
  @override
  State<SliderDemo> createState() => _SliderDemoState();
}

class _SliderDemoState extends State<SliderDemo> {
  double _value = _initialValue;

  @override
  Widget build(BuildContext context) {
    return AuraSlider(
      value: _value,
      onChanged: widget.enabled
          ? (value) => setState(() => _value = value)
          : null,
      min: _minValue,
      max: _maxValue,
      enabled: widget.enabled,
      semanticLabel: 'Example slider',
      tint: widget.tint,
    );
  }
}
