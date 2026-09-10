import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_dropdown_selector.stories.bridge.g.dart';
part 'auravibes_dropdown_selector.stories.g.dart';

const _dropdownOptions = <AuraDropdownOption<String>>[
  AuraDropdownOption(value: 'Free', child: Text('Free'), semanticLabel: 'Free'),
  AuraDropdownOption(value: 'Pro', child: Text('Pro'), semanticLabel: 'Pro'),
  AuraDropdownOption(
    value: 'Enterprise',
    child: Text('Enterprise'),
    semanticLabel: 'Enterprise',
  ),
];

class const _DropdownInput({
  required final int? selectedIndex,
  required final bool enabled,
  required final bool isRequired,
  required final bool showError,
  required final String label,
});

const _component = ComponentMeta(name: 'AuraDropdownSelector');
const _meta = Meta(DropdownDemo.new, argsType: _DropdownInput.new);

final _Defaults _dropdownDefaults = _Defaults(
  builder: (context, args) => DropdownDemo(
    selectedIndex: args.selectedIndex,
    enabled: args.enabled,
    isRequired: args.isRequired,
    showError: args.showError,
    label: args.label,
  ),
);

abstract final class _StorybookDefinitions {
  static final $Dropdown = _Story(
    name: 'Dropdown',
    setup: (context, child, args) => StoryHelpers.constrainStoryWidth(child),
    args: _Args(
      selectedIndex: NullableIntArg(0, name: 'Selected Index'),
      enabled: BoolArg(true, name: 'Enabled'),
      isRequired: BoolArg(false, name: 'Required'),
      showError: BoolArg(false, name: 'Show Error'),
      label: StringArg('Plan', name: 'Label'),
    ),
    scenarios: [
      _Scenario(
        name: 'Compact Phone',
        modes: [ViewportMode(StoryHelpers.compactPhoneViewport)],
      ),
      _Scenario(
        name: 'Tablet',
        modes: [ViewportMode(StoryHelpers.tabletViewport)],
      ),
      _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(.rtl)]),
      _Scenario(name: 'Arabic', modes: [AuraArabicLocaleMode()]),
      _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
      _Scenario(
        name: 'Opens Menu',
        run: (tester, args) async {
          await tester.tap(find.byType(AuraDropdownSelector<String>));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('Enterprise'), findsOneWidget);
        },
      ),
    ],
  );
}

/// Demonstrates the Aura dropdown with selection, validation, and keyboard
/// focus behavior.
class const DropdownDemo({
  required final int? selectedIndex,
  required final bool enabled,
  required final bool isRequired,
  required final bool showError,
  required final String label,
  super.key,
}) extends StatefulWidget {
  @override
  State<DropdownDemo> createState() => _DropdownDemoState();
}

class _DropdownDemoState extends State<DropdownDemo> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant DropdownDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) => _DropdownControl(
    data: .new(demo: widget, selectedIndex: _selectedIndex, onChanged: _select),
  );

  void _select(String? value) => setState(
    () => _selectedIndex = value == null
        ? null
        : _dropdownOptions.indexWhere((option) => option.value == value),
  );
}

class const _DropdownControl({required final _DropdownControlData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => data.selector;
}

class _DropdownControlData({
  required final DropdownDemo demo,
  required final int? selectedIndex,
  required final ValueChanged<String?> onChanged,
}) {
  final AuraDropdownSelector<String> selector = .new(
    options: _dropdownOptions,
    value: switch (selectedIndex) {
      final index? => _dropdownOptions[index].value,
      null => null,
    },
    onChanged: onChanged,
    placeholder: const Text('Select a plan'),
    label: Text(demo.label),
    hint: const Text('Choose the plan for this workspace'),
    error: demo.showError ? const Text('Select a plan') : null,
    isRequired: demo.isRequired,
    isEnabled: demo.enabled,
    semanticLabel: demo.label,
  );
}
