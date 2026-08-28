// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_switch.stories.g.dart';

const component = ComponentMeta(name: 'AuraSwitch');
const meta = Meta(SwitchDemo.new);

final $Default = _Story(
  name: 'Default',
  setup: (context, child, args) => constrainStoryWidth(
    Padding(padding: const EdgeInsets.all(16), child: child),
  ),
  args: _Args(
    size: EnumArg(
      AuraSwitchSize.base,
      name: 'size',
      values: AuraSwitchSize.values,
    ),
    disabled: BoolArg(false, name: 'disabled'),
    isLoading: BoolArg(false, name: 'isLoading'),
    semanticLabel: StringArg('Switch', name: 'Semantic Label'),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(
      name: 'Toggles Switch',
      run: (tester, args) async {
        await tester.tap(find.byType(AuraSwitch));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates a controlled switch with size, loading, and disabled states.
class SwitchDemo extends StatefulWidget {
  const SwitchDemo({
    super.key,
    required this.size,
    required this.disabled,
    required this.isLoading,
    this.semanticLabel = 'Switch',
  });

  final AuraSwitchSize size;
  final bool disabled;
  final bool isLoading;
  final String semanticLabel;

  @override
  State<SwitchDemo> createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<SwitchDemo> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return AuraSwitch(
      value: _value,
      onChanged: (value) => setState(() => _value = value),
      size: widget.size,
      disabled: widget.disabled,
      isLoading: widget.isLoading,
      semanticLabel: widget.semanticLabel,
    );
  }
}
