// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_checkbox_list_tile.stories.g.dart';

const component = ComponentMeta(name: 'AuraCheckboxListTile');
const meta = Meta(CheckboxListTileDemo.new);

final $CheckboxListTile = _Story(
  name: 'Checkbox List Tile',
  setup: (context, child, args) => constrainStoryWidth(
    Padding(padding: const EdgeInsets.all(16), child: child),
  ),
  args: _Args(
    tint: NullableEnumArg(null, name: 'tint', values: AuraTint.values),
    disabled: BoolArg(false, name: 'disabled'),
    showSubtitle: BoolArg(true, name: 'showSubtitle'),
    autofocus: BoolArg(false, name: 'autofocus'),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
    _Scenario(
      name: 'Toggles Checkbox',
      run: (tester, args) async {
        await tester.tap(find.text('Enable option'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates a settings-style checkbox tile with optional supporting text.
class const CheckboxListTileDemo({
  super.key,
  required final AuraTint? tint,
  required final bool disabled,
  required final bool showSubtitle,
  required final bool autofocus,
}) extends StatefulWidget {
  @override
  State<CheckboxListTileDemo> createState() => _CheckboxListTileDemoState();
}

class _CheckboxListTileDemoState extends State<CheckboxListTileDemo> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return AuraCheckboxListTile(
      value: _value,
      onChanged: widget.disabled
          ? null
          : (value) => setState(() => _value = value),
      title: const Text('Enable option'),
      subtitle: widget.showSubtitle
          ? const Text('Use this for optional settings')
          : null,
      tint: widget.tint,
      disabled: widget.disabled,
      autofocus: widget.autofocus,
    );
  }
}
