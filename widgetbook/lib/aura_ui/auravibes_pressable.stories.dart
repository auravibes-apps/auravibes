import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_pressable.stories.bridge.g.dart';
part 'auravibes_pressable.stories.g.dart';

class const _PressableInput({
  required final String label,
  required final bool enabled,
});

const _component = ComponentMeta(name: 'AuraPressable');
const _meta = Meta(PressableDemo.new, argsType: _PressableInput.new);

final _Defaults _pressableDefaults = _Defaults(
  builder: (context, args) =>
      PressableDemo(label: args.label, enabled: args.enabled),
);

abstract final class _StorybookDefinitions {
  static final $Pressable = _Story(
    name: 'Pressable',
    setup: (context, child, args) =>
        Padding(padding: const EdgeInsets.all(24), child: child),
    args: _Args(
      label: StringArg('Press me', name: 'Label'),
      enabled: BoolArg(true, name: 'Enabled'),
    ),
    scenarios: [
      _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(.rtl)]),
      _Scenario(
        name: 'Pressed',
        run: (tester, args) async {
          await tester.tap(find.byType(AuraPressable));
          await tester.pump(const Duration(milliseconds: 200));
        },
      ),
    ],
  );
}

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
  Widget build(BuildContext _) => _PressableControl(
    demo: widget,
    pressed: _pressed,
    onPressed: _markPressed,
  );

  void _markPressed() => setState(() => _pressed = true);
}

class const _PressableControl({
  required final PressableDemo demo,
  required final bool pressed,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _PressableControlData(
    demo: demo,
    pressed: pressed,
    onPressed: onPressed,
    colors: context.auraColors,
  ).button;
}

class _PressableControlData({
  required final PressableDemo demo,
  required final bool pressed,
  required final VoidCallback onPressed,
  required final AuraColorScheme colors,
}) {
  final AuraPressable button = .new(
    child: _PressableLabel(
      label: demo.label,
      pressed: pressed,
      color: colors.onSurface,
    ),
    color: colors.primary,
    decoration: BoxDecoration(
      color: colors.surface,
      border: Border.fromBorderSide(.new(color: colors.outline)),
      borderRadius: const BorderRadius.all(.circular(12)),
    ),
    onPressed: demo.enabled ? onPressed : null,
    padding: const AuraEdgeInsetsGeometry.symmetric(
      horizontal: .lg,
      vertical: .sm,
    ),
    semanticLabel: demo.label,
  );
}

class const _PressableLabel({
  required final String label,
  required final bool pressed,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) =>
      Text(pressed ? 'Pressed' : label, style: .new(color: color));
}
