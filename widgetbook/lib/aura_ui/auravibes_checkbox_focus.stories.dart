// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_checkbox_focus.stories.g.dart';

class _FocusInput {
  const _FocusInput({required this.selected});

  final bool selected;
}

const component = ComponentMeta(name: 'AuraCheckbox');
const meta = Meta(AuraCheckbox.new, argsType: _FocusInput.new);

final _Defaults focusDefaults = _Defaults(
  builder: (context, args) => AuraCheckbox(
    value: args.selected,
    onChanged: _noopCheckboxChanged,
    autofocus: true,
  ),
);

final $FocusStates = _Story(
  name: 'Focus States',
  setup: (context, child, args) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle.merge(
          style: TextStyle(color: context.auraColors.onSurface),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [child, const SizedBox(width: 12), const Text('Focused')],
          ),
        ),
        const SizedBox(height: 16),
        _FocusStateRow(label: 'Not focused', value: args.selected),
      ],
    ),
  ),
  args: _Args(selected: BoolArg(true, name: 'selected')),
  scenarios: [
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(
      name: 'Focuses Checkbox',
      run: (tester, args) async {
        await tester.tap(find.byType(AuraCheckbox).first);
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

class _FocusStateRow extends StatelessWidget {
  const _FocusStateRow({required this.label, required this.value});

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuraCheckbox(value: value, onChanged: _noopCheckboxChanged),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: context.auraColors.onSurface)),
      ],
    );
  }
}

void _noopCheckboxChanged(bool value) {
  if (value) return;
}
