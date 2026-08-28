// Required: Widgetbook stories group related story widgets.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_button_group_action.stories.g.dart';

const component = ComponentMeta(name: 'AuraButtonGroup');
const meta = Meta(ActionDemo.new);

final $ActionClickable = _Story(
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
      modes: [ViewportMode(landscapePhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(
      name: 'Pressed',
      run: (tester, args) async {
        await tester.tap(find.byIcon(Icons.undo));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates an action button group and reports the last pressed action.
class ActionDemo extends StatefulWidget {
  const ActionDemo({
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
  State<ActionDemo> createState() => _ActionDemoState();
}

class _ActionDemoState extends State<ActionDemo> {
  String _lastPressed = 'None';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuraButtonGroup<String>.action(
          items: const [
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
          ],
          onPressed: (value) => setState(() => _lastPressed = value),
          size: widget.size,
          variant: widget.variant,
          orientation: widget.orientation,
          disabled: widget.disabled,
          isLoading: widget.isLoading,
        ),
        const SizedBox(height: 16),
        Text(
          'Last pressed: $_lastPressed',
          style: TextStyle(color: context.auraColors.onSurface),
        ),
      ],
    );
  }
}
