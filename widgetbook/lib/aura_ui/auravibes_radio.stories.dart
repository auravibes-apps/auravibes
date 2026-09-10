// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_radio.stories.bridge.g.dart';
part 'auravibes_radio.stories.g.dart';

const _component = ComponentMeta(name: 'AuraRadio');

class const _RadioInput({
  required final AuraTint? tint,
  required final bool disabled,
  required final int itemCount,
});

const _meta = Meta(SingleRadioDemo.new, argsType: _RadioInput.new);

final _Defaults _radioDefaults = _Defaults(
  builder: (context, args) => SingleRadioDemo(
    tint: args.tint,
    disabled: args.disabled,
    itemCount: args.itemCount,
  ),
);

abstract final class _StorybookDefinitions {
  static final $SingleRadio = _Story(
    name: 'Single Radio',
    setup: (context, child, args) => StoryHelpers.constrainStoryWidth(child),
    args: _Args(
      tint: NullableEnumArg(null, name: 'tint', values: AuraTint.values),
      disabled: BoolArg(false, name: 'disabled'),
      itemCount: IntArg(
        3,
        name: 'item count',
        style: const SliderIntArgStyle(min: 1, max: 6, divisions: 5),
      ),
    ),
    scenarios: [
      _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(.rtl)]),
      _Scenario(
        name: 'Selects Radio',
        run: (tester, args) async {
          await tester.tap(find.byType(AuraRadio<String>).at(1));
          await tester.pump(const Duration(milliseconds: 300));
        },
      ),
    ],
  );
}

/// Demonstrates a single controlled radio button.
class const SingleRadioDemo({
  super.key,
  required final AuraTint? tint,
  required final bool disabled,
  required final int itemCount,
}) extends StatefulWidget {
  @override
  State<SingleRadioDemo> createState() => _SingleRadioDemoState();
}

class _SingleRadioDemoState extends State<SingleRadioDemo> {
  String? _selectedValue;

  @override
  Widget build(BuildContext context) => _RadioPreview(
    data: (
      itemCount: widget.itemCount,
      selectedValue: _selectedValue,
      tint: widget.tint,
      disabled: widget.disabled,
      onChanged: _select,
    ),
  );

  void _select(String? value) => setState(() => _selectedValue = value);
}

typedef _RadioPreviewData = ({
  int itemCount,
  String? selectedValue,
  AuraTint? tint,
  bool disabled,
  ValueChanged<String?> onChanged,
});

class const _RadioPreview({required final _RadioPreviewData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      _RadioOptions(data: .new(data: data)),
      _RadioSelectionLabel(value: data.selectedValue),
    ],
  );
}

class _RadioOptionsData({required final _RadioPreviewData data}) {
  final List<Widget> options = [
    for (var index = 0; index < data.itemCount; index++) ...[
      _RadioOption(data: _radioOptionData(data, index)),
      if (index < data.itemCount - 1) const SizedBox(height: 8),
    ],
  ];
}

class const _RadioOptions({required final _RadioOptionsData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) =>
      Column(mainAxisSize: .min, children: data.options);
}

_RadioOptionData _radioOptionData(_RadioPreviewData data, int index) => (
  value: 'option${index + 1}',
  groupValue: data.selectedValue,
  tint: data.tint,
  disabled: data.disabled,
  semanticLabel: 'Option ${index + 1}',
  onChanged: data.disabled ? null : data.onChanged,
);

class const _RadioSelectionLabel({required final String? value})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    'Selected: ${value ?? 'none'}',
    style: Theme.of(context).textTheme.bodyMedium,
  );
}

typedef _RadioOptionData = ({
  String value,
  String? groupValue,
  AuraTint? tint,
  bool disabled,
  String semanticLabel,
  ValueChanged<String?>? onChanged,
});

class const _RadioOption({required final _RadioOptionData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRadio<String>(
    value: data.value,
    groupValue: data.groupValue,
    onChanged: data.onChanged,
    tint: data.tint,
    disabled: data.disabled,
    semanticLabel: data.semanticLabel,
  );
}
