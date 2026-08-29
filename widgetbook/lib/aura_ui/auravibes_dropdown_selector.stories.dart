import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_dropdown_selector.stories.g.dart';

class _DropdownInput {
  const _DropdownInput({
    required this.selectedIndex,
    required this.enabled,
    required this.isRequired,
    required this.showError,
    required this.label,
  });

  final int? selectedIndex;
  final bool enabled;
  final bool isRequired;
  final bool showError;
  final String label;
}

const component = ComponentMeta(name: 'AuraDropdownSelector');
const meta = Meta(DropdownDemo.new, argsType: _DropdownInput.new);

final _Defaults dropdownDefaults = _Defaults(
  builder: (context, args) => DropdownDemo(
    selectedIndex: args.selectedIndex,
    enabled: args.enabled,
    isRequired: args.isRequired,
    showError: args.showError,
    label: args.label,
  ),
);

final $Dropdown = _Story(
  name: 'Dropdown',
  setup: (context, child, args) => constrainStoryWidth(child),
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
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'Tablet', modes: [ViewportMode(tabletViewport)]),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
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

/// Demonstrates the Aura dropdown with selection, validation, and keyboard
/// focus behavior.
class DropdownDemo extends StatefulWidget {
  const DropdownDemo({
    required this.selectedIndex,
    required this.enabled,
    required this.isRequired,
    required this.showError,
    required this.label,
    super.key,
  });

  final int? selectedIndex;
  final bool enabled;
  final bool isRequired;
  final bool showError;
  final String label;

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
  Widget build(BuildContext context) {
    const options = ['Free', 'Pro', 'Enterprise'];
    final selectedIndex = _selectedIndex;

    return AuraDropdownSelector<String>(
      options: [
        for (final option in options)
          AuraDropdownOption(
            value: option,
            child: Text(option),
            semanticLabel: option,
          ),
      ],
      value: selectedIndex == null ? null : options[selectedIndex],
      onChanged: (value) => setState(() {
        _selectedIndex = value == null ? null : options.indexOf(value);
      }),
      placeholder: const Text('Select a plan'),
      label: Text(widget.label),
      hint: const Text('Choose the plan for this workspace'),
      error: widget.showError ? const Text('Select a plan') : null,
      isRequired: widget.isRequired,
      isEnabled: widget.enabled,
      semanticLabel: widget.label,
    );
  }
}
