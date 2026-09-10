// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_radio_list_tile.stories.bridge.g.dart';
part 'auravibes_radio_list_tile.stories.g.dart';

const _radioListTileOptions = <({String value, String title, String subtitle})>[
  (value: 'system', title: 'System Theme', subtitle: 'Follow system settings'),
  (value: 'light', title: 'Light Theme', subtitle: 'Use light color scheme'),
  (value: 'dark', title: 'Dark Theme', subtitle: 'Use dark color scheme'),
];

const _component = ComponentMeta(name: 'AuraRadioListTile');
const _meta = Meta(RadioListTileDemo.new);

abstract final class _StorybookDefinitions {
  static final $RadioListTile = _Story(
    name: 'Radio List Tile',
    setup: (context, child, args) => StoryHelpers.constrainStoryWidth(
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
        modes: [ViewportMode(StoryHelpers.compactPhoneViewport)],
      ),
      _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(.rtl)]),
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
}

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
  Widget build(BuildContext context) => _RadioListTileControl(
    demo: widget,
    selectedValue: _selectedValue,
    onChanged: _select,
  );

  void _select(String? value) => setState(() => _selectedValue = value);
}

class const _RadioListTileControl({
  required final RadioListTileDemo demo,
  required final String? selectedValue,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  ValueChanged<String?>? get _optionChanged => demo.disabled ? null : onChanged;

  @override
  Widget build(BuildContext _) => Column(
    mainAxisSize: .min,
    children: [
      for (final option in _radioListTileOptions)
        _RadioListTileOption(data: _optionData(option)),
    ],
  );

  _RadioListTileOptionData _optionData(
    ({String value, String title, String subtitle}) option,
  ) => (
    value: option.value,
    title: option.title,
    subtitle: demo.showSubtitle ? option.subtitle : '',
    groupValue: selectedValue,
    onChanged: _optionChanged,
    tint: demo.tint,
    disabled: demo.disabled,
  );
}

typedef _RadioListTileOptionData = ({
  String value,
  String title,
  String subtitle,
  String? groupValue,
  ValueChanged<String?>? onChanged,
  AuraTint? tint,
  bool disabled,
});

class _RadioListTileOption extends AuraRadioListTile<String> {
  new({required _RadioListTileOptionData data})
    : super(
        value: data.value,
        groupValue: data.groupValue,
        onChanged: data.onChanged,
        title: Text(data.title),
        subtitle: data.subtitle.isEmpty ? null : Text(data.subtitle),
        tint: data.tint,
        disabled: data.disabled,
      );
}
