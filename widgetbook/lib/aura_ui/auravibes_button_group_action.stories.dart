// Required: Widgetbook stories group related story widgets.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_button_group_action.stories.bridge.g.dart';
part 'auravibes_button_group_action.stories.g.dart';

const _actionItems = <AuraButtonGroupItem<String>>[
  AuraButtonGroupItem(
    value: 'undo',
    child: Icon(Icons.undo),
    semanticLabel: 'Undo',
  ),
  AuraButtonGroupItem(
    value: 'redo',
    child: Icon(Icons.redo),
    semanticLabel: 'Redo',
  ),
  AuraButtonGroupItem(
    value: 'copy',
    child: Icon(Icons.copy),
    semanticLabel: 'Copy',
  ),
  AuraButtonGroupItem(
    value: 'paste',
    child: Icon(Icons.paste),
    semanticLabel: 'Paste',
  ),
];

const _component = ComponentMeta(name: 'AuraButtonGroup');
const _meta = Meta(ActionDemo.new);

abstract final class _StorybookDefinitions {
  static final $ActionClickable = _Story(
    name: 'Action (Clickable)',
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
        name: 'Pressed',
        run: (tester, args) async {
          await tester.tap(find.byIcon(Icons.undo));
          await tester.pump(const Duration(milliseconds: 300));
        },
      ),
    ],
  );
}

/// Demonstrates an action button group and reports the last pressed action.
class const ActionDemo({
  super.key,
  required final AuraButtonGroupSize size,
  required final AuraButtonGroupVariant variant,
  required final Axis orientation,
  required final bool disabled,
  required final bool isLoading,
}) extends StatefulWidget {
  @override
  State<ActionDemo> createState() => _ActionDemoState();
}

class _ActionDemoState extends State<ActionDemo> {
  String _lastPressed = 'None';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      _ActionGroup(
        demo: widget,
        onPressed: (value) => setState(() => _lastPressed = value),
      ),
      const SizedBox(height: 16),
      _ActionStatus(lastPressed: _lastPressed),
    ],
  );
}

class const _ActionGroup({
  required final ActionDemo demo,
  required final ValueChanged<String> onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraButtonGroup<String>.action(
    items: _actionItems,
    onPressed: onPressed,
    size: demo.size,
    variant: demo.variant,
    orientation: demo.orientation,
    disabled: demo.disabled,
    isLoading: demo.isLoading,
  );
}

class const _ActionStatus({required final String lastPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    'Last pressed: $lastPressed',
    style: .new(color: context.auraColors.onSurface),
  );
}
