// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_sidebar.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SidebarDemo, StoryArgs<SidebarDemo>>;
typedef _Scenario = SidebarDemoScenario;
typedef _Defaults = SidebarDemoDefaults;
typedef _Story = SidebarDemoStory;
typedef _Args = _SidebarInputArgs;
final SidebarDemoComponent = Component<SidebarDemo, StoryArgs<SidebarDemo>>(
  name: component.name ?? 'SidebarDemo',
  path: component.path ?? 'aura_ui',
  docsBuilder: component.docsBuilder,
  docComment:
      r'''Demonstrates expanded and compact directional navigation sidebars.''',
  stories: [$Sidebar..$generatedName = 'Sidebar'],
);
typedef SidebarDemoScenario = Scenario<SidebarDemo, _SidebarInputArgs>;
typedef SidebarDemoDefaults = Defaults<SidebarDemo, _SidebarInputArgs>;

class SidebarDemoStory extends Story<SidebarDemo, _SidebarInputArgs> {
  SidebarDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _SidebarInputArgs? args,
    StoryWidgetBuilder<SidebarDemo, _SidebarInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _SidebarInputArgs(),
         builder: builder ?? sidebarDefaults.builder!,
       );
}

class _SidebarInputArgs extends StoryArgs<SidebarDemo> {
  _SidebarInputArgs({Arg<bool>? expanded, Arg<int>? selectedIndex})
    : this.expandedArg = $initArg('expanded', expanded, BoolArg(false))!,
      this.selectedIndexArg = $initArg(
        'selectedIndex',
        selectedIndex,
        IntArg(0),
      )!;

  _SidebarInputArgs.fixed({bool expanded = false, int selectedIndex = 0})
    : this.expandedArg = $initArg('expanded', Arg.fixed(expanded), null)!,
      this.selectedIndexArg = $initArg(
        'selectedIndex',
        Arg.fixed(selectedIndex),
        null,
      )!;

  final Arg<bool> expandedArg;

  final Arg<int> selectedIndexArg;

  bool get expanded => expandedArg.value;

  int get selectedIndex => selectedIndexArg.value;

  @override
  List<Arg?> get list => [expandedArg, selectedIndexArg];
}
