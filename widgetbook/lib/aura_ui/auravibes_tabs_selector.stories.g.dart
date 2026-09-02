// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_tabs_selector.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SelectorTabsDemo, StoryArgs<SelectorTabsDemo>>;
typedef _Scenario = SelectorTabsDemoScenario;
typedef _Defaults = SelectorTabsDemoDefaults;
typedef _Story = SelectorTabsDemoStory;
typedef _Args = SelectorTabsDemoArgs;
final SelectorTabsDemoComponent =
    Component<SelectorTabsDemo, StoryArgs<SelectorTabsDemo>>(
      name: component.name ?? 'SelectorTabsDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment: r'''Demonstrates selector tabs whose selected value is owned by the caller.''',
      stories: [$SelectorTabs..$generatedName = 'SelectorTabs'],
    );
typedef SelectorTabsDemoScenario =
    Scenario<SelectorTabsDemo, SelectorTabsDemoArgs>;
typedef SelectorTabsDemoDefaults =
    Defaults<SelectorTabsDemo, SelectorTabsDemoArgs>;

class SelectorTabsDemoStory
    extends Story<SelectorTabsDemo, SelectorTabsDemoArgs> {
  SelectorTabsDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    SelectorTabsDemoArgs? args,
    StoryWidgetBuilder<SelectorTabsDemo, SelectorTabsDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SelectorTabsDemoArgs(),
         builder: builder ?? (context, args) => SelectorTabsDemo(key: args.key),
       );
}

class SelectorTabsDemoArgs extends StoryArgs<SelectorTabsDemo> {
  SelectorTabsDemoArgs({Arg<Key?>? key})
    : this.keyArg = $initArg('key', key, null);

  SelectorTabsDemoArgs.fixed({Key? key})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null);

  final Arg<Key?>? keyArg;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [keyArg];
}
