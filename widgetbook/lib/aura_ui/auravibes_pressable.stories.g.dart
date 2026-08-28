// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_pressable.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<PressableDemo, StoryArgs<PressableDemo>>;
typedef _Scenario = PressableDemoScenario;
typedef _Defaults = PressableDemoDefaults;
typedef _Story = PressableDemoStory;
typedef _Args = _PressableInputArgs;
final PressableDemoComponent = Component<PressableDemo, StoryArgs<PressableDemo>>(
  name: component.name ?? 'PressableDemo',
  path: component.path ?? 'aura_ui',
  docsBuilder: component.docsBuilder,
  docComment:
      r'''Demonstrates keyboard and pointer feedback on a reusable pressable surface.''',
  stories: [$Pressable..$generatedName = 'Pressable'],
);
typedef PressableDemoScenario = Scenario<PressableDemo, _PressableInputArgs>;
typedef PressableDemoDefaults = Defaults<PressableDemo, _PressableInputArgs>;

class PressableDemoStory extends Story<PressableDemo, _PressableInputArgs> {
  PressableDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _PressableInputArgs? args,
    StoryWidgetBuilder<PressableDemo, _PressableInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _PressableInputArgs(),
         builder: builder ?? pressableDefaults.builder!,
       );
}

class _PressableInputArgs extends StoryArgs<PressableDemo> {
  _PressableInputArgs({Arg<String>? label, Arg<bool>? enabled})
    : this.labelArg = $initArg('label', label, StringArg(''))!,
      this.enabledArg = $initArg('enabled', enabled, BoolArg(false))!;

  _PressableInputArgs.fixed({String label = '', bool enabled = false})
    : this.labelArg = $initArg('label', Arg.fixed(label), null)!,
      this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<String> labelArg;

  final Arg<bool> enabledArg;

  String get label => labelArg.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [labelArg, enabledArg];
}
