import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_pressable.stories.g.dart';

class const _PressableInput({
  required final String label,
  required final bool enabled,
});

const component = ComponentMeta(name: 'AuraPressable');
const meta = Meta(PressableDemo.new, argsType: _PressableInput.new);

final _Defaults pressableDefaults = _Defaults(
  builder: (context, args) =>
      PressableDemo(label: args.label, enabled: args.enabled),
);

final $Pressable = _Story(
  name: 'Pressable',
  setup: (context, child, args) =>
      Padding(padding: const EdgeInsets.all(24), child: child),
  args: _Args(
    label: StringArg('Press me', name: 'Label'),
    enabled: BoolArg(true, name: 'Enabled'),
  ),
  scenarios: [
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(
      name: 'Pressed',
      run: (tester, args) async {
        await tester.tap(find.byType(AuraPressable));
        await tester.pump(const Duration(milliseconds: 200));
      },
    ),
  ],
);

/// Demonstrates keyboard and pointer feedback on a reusable pressable surface.
class const PressableDemo({
  required final String label,
  required final bool enabled,
  super.key,
}) extends StatefulWidget {
  @override
  State<PressableDemo> createState() => _PressableDemoState();
}

class _PressableDemoState extends State<PressableDemo> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AuraPressable(
      child: Text(
        _pressed ? 'Pressed' : widget.label,
        style: TextStyle(color: context.auraColors.onSurface),
      ),
      color: context.auraColors.primary,
      decoration: BoxDecoration(
        color: context.auraColors.surface,
        border: Border.all(color: context.auraColors.outline),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      onPressed: widget.enabled ? () => setState(() => _pressed = true) : null,
      padding: const AuraEdgeInsetsGeometry.symmetric(
        horizontal: .lg,
        vertical: .sm,
      ),
      semanticLabel: widget.label,
    );
  }
}
