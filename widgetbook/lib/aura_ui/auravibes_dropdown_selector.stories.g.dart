// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_dropdown_selector.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<DropdownDemo, StoryArgs<DropdownDemo>>;
typedef _Scenario = DropdownDemoScenario;
typedef _Defaults = DropdownDemoDefaults;
typedef _Story = DropdownDemoStory;
typedef _Args = _DropdownInputArgs;
final DropdownDemoComponent = Component<DropdownDemo, StoryArgs<DropdownDemo>>(
  name: component.name ?? 'DropdownDemo',
  path: component.path ?? 'aura_ui',
  docsBuilder: component.docsBuilder,
  docComment:
      r'''Demonstrates the Aura dropdown with selection, validation, and keyboard
focus behavior.''',
  stories: [$Dropdown..$generatedName = 'Dropdown'],
);
typedef DropdownDemoScenario = Scenario<DropdownDemo, _DropdownInputArgs>;
typedef DropdownDemoDefaults = Defaults<DropdownDemo, _DropdownInputArgs>;

class DropdownDemoStory extends Story<DropdownDemo, _DropdownInputArgs> {
  DropdownDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _DropdownInputArgs? args,
    StoryWidgetBuilder<DropdownDemo, _DropdownInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _DropdownInputArgs(),
         builder: builder ?? dropdownDefaults.builder!,
       );
}

class _DropdownInputArgs extends StoryArgs<DropdownDemo> {
  _DropdownInputArgs({
    Arg<int?>? selectedIndex,
    Arg<bool>? enabled,
    Arg<bool>? isRequired,
    Arg<bool>? showError,
    Arg<String>? label,
  }) : this.selectedIndexArg = $initArg(
         'selectedIndex',
         selectedIndex,
         NullableIntArg(null),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(false))!,
       this.isRequiredArg = $initArg('isRequired', isRequired, BoolArg(false))!,
       this.showErrorArg = $initArg('showError', showError, BoolArg(false))!,
       this.labelArg = $initArg('label', label, StringArg(''))!;

  _DropdownInputArgs.fixed({
    int? selectedIndex = null,
    bool enabled = false,
    bool isRequired = false,
    bool showError = false,
    String label = '',
  }) : this.selectedIndexArg = $initArg(
         'selectedIndex',
         selectedIndex == null ? null : Arg.fixed(selectedIndex),
         null,
       ),
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.isRequiredArg = $initArg(
         'isRequired',
         Arg.fixed(isRequired),
         null,
       )!,
       this.showErrorArg = $initArg('showError', Arg.fixed(showError), null)!,
       this.labelArg = $initArg('label', Arg.fixed(label), null)!;

  final Arg<int?>? selectedIndexArg;

  final Arg<bool> enabledArg;

  final Arg<bool> isRequiredArg;

  final Arg<bool> showErrorArg;

  final Arg<String> labelArg;

  int? get selectedIndex => selectedIndexArg?.value;

  bool get enabled => enabledArg.value;

  bool get isRequired => isRequiredArg.value;

  bool get showError => showErrorArg.value;

  String get label => labelArg.value;

  @override
  List<Arg?> get list => [
    selectedIndexArg,
    enabledArg,
    isRequiredArg,
    showErrorArg,
    labelArg,
  ];
}
