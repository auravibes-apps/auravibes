// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_list.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraList, StoryArgs<AuraList>>;
typedef _Scenario = AuraListScenario;
typedef _Defaults = AuraListDefaults;
typedef _Story = AuraListStory;
typedef _Args = _ListInputArgs;
final AuraListComponent = Component<AuraList, StoryArgs<AuraList>>(
  name: 'AuraList',
  path: 'aura_ui',
  docComment: r'''A scrollable list of static Aura UI child widgets.

[alignment] controls how children are placed along the axis perpendicular
to [direction]. The list fills bounded parent constraints and shrink-wraps
its content when the scroll axis is unbounded.''',
  stories: [$AuraList..$generatedName = 'AuraList'],
);
typedef AuraListScenario = Scenario<AuraList, _ListInputArgs>;
typedef AuraListDefaults = Defaults<AuraList, _ListInputArgs>;

class AuraListStory extends Story<AuraList, _ListInputArgs> {
  AuraListStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _ListInputArgs? args,
    StoryWidgetBuilder<AuraList, _ListInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _ListInputArgs(),
         builder: builder ?? listDefaults.builder!,
       );
}

class _ListInputArgs extends StoryArgs<AuraList> {
  _ListInputArgs({Arg<Axis>? direction, Arg<int>? itemCount})
    : this.directionArg = $initArg(
        'direction',
        direction,
        EnumArg<Axis>(Axis.horizontal, values: Axis.values),
      )!,
      this.itemCountArg = $initArg('itemCount', itemCount, IntArg(0))!;

  _ListInputArgs.fixed({Axis direction = Axis.horizontal, int itemCount = 0})
    : this.directionArg = $initArg('direction', Arg.fixed(direction), null)!,
      this.itemCountArg = $initArg('itemCount', Arg.fixed(itemCount), null)!;

  final Arg<Axis> directionArg;

  final Arg<int> itemCountArg;

  Axis get direction => directionArg.value;

  int get itemCount => itemCountArg.value;

  @override
  List<Arg?> get list => [directionArg, itemCountArg];
}
