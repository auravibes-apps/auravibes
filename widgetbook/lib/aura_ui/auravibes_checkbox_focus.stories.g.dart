// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_checkbox_focus.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraCheckbox, StoryArgs<AuraCheckbox>>;
typedef _Scenario = AuraCheckboxScenario;
typedef _Defaults = AuraCheckboxDefaults;
typedef _Story = AuraCheckboxStory;
typedef _Args = _FocusInputArgs;
final AuraCheckboxComponent = Component<AuraCheckbox, StoryArgs<AuraCheckbox>>(
  name: component.name ?? 'AuraCheckbox',
  path: component.path ?? 'aura_ui',
  docsBuilder: component.docsBuilder,
  docComment:
      r'''An Aura checkbox that follows the const-first design system.''',
  stories: [$FocusStates..$generatedName = 'FocusStates'],
);
typedef AuraCheckboxScenario = Scenario<AuraCheckbox, _FocusInputArgs>;
typedef AuraCheckboxDefaults = Defaults<AuraCheckbox, _FocusInputArgs>;

class AuraCheckboxStory extends Story<AuraCheckbox, _FocusInputArgs> {
  AuraCheckboxStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _FocusInputArgs? args,
    StoryWidgetBuilder<AuraCheckbox, _FocusInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _FocusInputArgs(),
         builder: builder ?? focusDefaults.builder!,
       );
}

class _FocusInputArgs extends StoryArgs<AuraCheckbox> {
  _FocusInputArgs({Arg<bool>? selected})
    : this.selectedArg = $initArg('selected', selected, BoolArg(false))!;

  _FocusInputArgs.fixed({bool selected = false})
    : this.selectedArg = $initArg('selected', Arg.fixed(selected), null)!;

  final Arg<bool> selectedArg;

  bool get selected => selectedArg.value;

  @override
  List<Arg?> get list => [selectedArg];
}
