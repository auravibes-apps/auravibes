// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_app_bar.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AppBarDemo, StoryArgs<AppBarDemo>>;
typedef _Scenario = AppBarDemoScenario;
typedef _Defaults = AppBarDemoDefaults;
typedef _Story = AppBarDemoStory;
typedef _Args = _AppBarInputArgs;
final AppBarDemoComponent = Component<AppBarDemo, StoryArgs<AppBarDemo>>(
  name: component.name ?? 'AppBarDemo',
  path: component.path ?? 'aura_ui',
  docsBuilder: component.docsBuilder,
  docComment: r'''Demonstrates the Aura app bar with editable title and leading action.''',
  stories: [$AppBar..$generatedName = 'AppBar'],
);
typedef AppBarDemoScenario = Scenario<AppBarDemo, _AppBarInputArgs>;
typedef AppBarDemoDefaults = Defaults<AppBarDemo, _AppBarInputArgs>;

class AppBarDemoStory extends Story<AppBarDemo, _AppBarInputArgs> {
  AppBarDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _AppBarInputArgs? args,
    StoryWidgetBuilder<AppBarDemo, _AppBarInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _AppBarInputArgs(),
         builder: builder ?? appBarDefaults.builder!,
       );
}

class _AppBarInputArgs extends StoryArgs<AppBarDemo> {
  _AppBarInputArgs({Arg<String>? title, Arg<bool>? showLeading})
    : this.titleArg = $initArg('title', title, StringArg(''))!,
      this.showLeadingArg = $initArg(
        'showLeading',
        showLeading,
        BoolArg(false),
      )!;

  _AppBarInputArgs.fixed({String title = '', bool showLeading = false})
    : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
      this.showLeadingArg = $initArg(
        'showLeading',
        Arg.fixed(showLeading),
        null,
      )!;

  final Arg<String> titleArg;

  final Arg<bool> showLeadingArg;

  String get title => titleArg.value;

  bool get showLeading => showLeadingArg.value;

  @override
  List<Arg?> get list => [titleArg, showLeadingArg];
}
