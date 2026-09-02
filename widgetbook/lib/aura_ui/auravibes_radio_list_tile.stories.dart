// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_radio_list_tile.stories.g.dart';

const component = ComponentMeta(name: 'AuraRadioListTile');
const meta = Meta(RadioListTileDemo.new);

final $RadioListTile = _Story(
  name: 'Radio List Tile',
  setup: (context, child, args) => constrainStoryWidth(
    Padding(padding: const EdgeInsets.all(16), child: child),
  ),
  args: _Args(
    tint: NullableEnumArg(null, name: 'tint', values: AuraTint.values),
    disabled: BoolArg(false, name: 'disabled'),
    showSubtitle: BoolArg(true, name: 'showSubtitle'),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
    _Scenario(
      name: 'Selects Radio',
      run: (tester, args) async {
        await tester.tap(find.text('Light Theme'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates settings-style radio list tiles with optional subtitles.
class const RadioListTileDemo({
  super.key,
  required final AuraTint? tint,
  required final bool disabled,
  required final bool showSubtitle,
}) extends StatefulWidget {
  @override
  State<RadioListTileDemo> createState() => _RadioListTileDemoState();
}

class _RadioListTileDemoState extends State<RadioListTileDemo> {
  String? _selectedValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuraRadioListTile<String>(
          value: 'system',
          groupValue: _selectedValue,
          onChanged: widget.disabled
              ? null
              : (value) => setState(() => _selectedValue = value),
          title: const Text('System Theme'),
          subtitle: widget.showSubtitle
              ? const Text('Follow system settings')
              : null,
          tint: widget.tint,
          disabled: widget.disabled,
        ),
        AuraRadioListTile<String>(
          value: 'light',
          groupValue: _selectedValue,
          onChanged: widget.disabled
              ? null
              : (value) => setState(() => _selectedValue = value),
          title: const Text('Light Theme'),
          subtitle: widget.showSubtitle
              ? const Text('Use light color scheme')
              : null,
          tint: widget.tint,
          disabled: widget.disabled,
        ),
        AuraRadioListTile<String>(
          value: 'dark',
          groupValue: _selectedValue,
          onChanged: widget.disabled
              ? null
              : (value) => setState(() => _selectedValue = value),
          title: const Text('Dark Theme'),
          subtitle: widget.showSubtitle
              ? const Text('Use dark color scheme')
              : null,
          tint: widget.tint,
          disabled: widget.disabled,
        ),
      ],
    );
  }
}
