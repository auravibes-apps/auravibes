// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_checkbox_single.stories.g.dart';

const component = ComponentMeta(name: 'AuraCheckbox');
const meta = Meta(SingleCheckboxDemo.new);

final $SingleCheckbox = _Story(
  name: 'Single Checkbox',
  args: _Args(
    tint: NullableEnumArg(null, name: 'tint', values: AuraTint.values),
    disabled: BoolArg(false, name: 'disabled'),
    autofocus: BoolArg(false, name: 'autofocus'),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(
      name: 'Toggles Checkbox',
      run: (tester, args) async {
        await tester.tap(find.byType(AuraCheckbox));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates a controlled checkbox with focus, tint, and disabled states.
class const SingleCheckboxDemo({
  super.key,
  required final AuraTint? tint,
  required final bool disabled,
  required final bool autofocus,
}) extends StatefulWidget {
  @override
  State<SingleCheckboxDemo> createState() => _SingleCheckboxDemoState();
}

class _SingleCheckboxDemoState extends State<SingleCheckboxDemo> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return AuraCheckbox(
      value: _value,
      onChanged: widget.disabled
          ? null
          : (value) => setState(() => _value = value),
      tint: widget.tint,
      disabled: widget.disabled,
      autofocus: widget.autofocus,
    );
  }
}
