// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_tabs_basic.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraTabs, StoryArgs<AuraTabs>>;
typedef _Scenario<T> = AuraTabsScenario<T>;
typedef _Defaults = AuraTabsDefaults;
typedef _Story<T> = AuraTabsStory<T>;
typedef _Args<T> = AuraTabsArgs<T>;
final AuraTabsComponent = Component<AuraTabs, StoryArgs<AuraTabs>>(
  name: component.name ?? 'AuraTabs',
  path: component.path ?? 'aura_ui',
  docsBuilder: component.docsBuilder,
  docComment: r'''A selectable Aura tab strip with optional content.

Use [AuraTabs] when each tab owns content. Use [AuraTabs.selector] when the
tab strip selects a value and the caller renders content separately.''',
  stories: [$BasicTabs..$generatedName = 'BasicTabs'],
);
typedef AuraTabsScenario<T> = Scenario<AuraTabs<T>, AuraTabsArgs<T>>;
typedef AuraTabsDefaults = Defaults<AuraTabs, AuraTabsArgs>;

class AuraTabsStory<T> extends Story<AuraTabs<T>, AuraTabsArgs<T>> {
  AuraTabsStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<AuraTabs<T>, AuraTabsArgs<T>>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         builder:
             builder ??
             (context, args) => AuraTabs<T>(
               items: args.items,
               key: args.key,
               initialIndex: args.initialIndex,
               selectedIndex: args.selectedIndex,
               onChanged: args.onChanged,
             ),
       );
}

class AuraTabsArgs<T> extends StoryArgs<AuraTabs<T>> {
  AuraTabsArgs({
    required Arg<List<AuraTabItem>> items,
    Arg<Key?>? key,
    Arg<int>? initialIndex,
    Arg<int?>? selectedIndex,
    Arg<void Function(int)?>? onChanged,
  }) : this.itemsArg = $initArg('items', items, null)!,
       this.keyArg = $initArg('key', key, null),
       this.initialIndexArg = $initArg(
         'initialIndex',
         initialIndex,
         IntArg(0),
       )!,
       this.selectedIndexArg = $initArg(
         'selectedIndex',
         selectedIndex,
         NullableIntArg(null),
       )!,
       this.onChangedArg = $initArg('onChanged', onChanged, null);

  AuraTabsArgs.fixed({
    required List<AuraTabItem> items,
    Key? key,
    int initialIndex = 0,
    int? selectedIndex = null,
    void Function(int)? onChanged,
  }) : this.itemsArg = $initArg('items', Arg.fixed(items), null)!,
       this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.initialIndexArg = $initArg(
         'initialIndex',
         Arg.fixed(initialIndex),
         null,
       )!,
       this.selectedIndexArg = $initArg(
         'selectedIndex',
         selectedIndex == null ? null : Arg.fixed(selectedIndex),
         null,
       ),
       this.onChangedArg = $initArg(
         'onChanged',
         onChanged == null ? null : Arg.fixed(onChanged),
         null,
       );

  final Arg<List<AuraTabItem>> itemsArg;

  final Arg<Key?>? keyArg;

  final Arg<int> initialIndexArg;

  final Arg<int?>? selectedIndexArg;

  final Arg<void Function(int)?>? onChangedArg;

  List<AuraTabItem> get items => itemsArg.value;

  Key? get key => keyArg?.value;

  int get initialIndex => initialIndexArg.value;

  int? get selectedIndex => selectedIndexArg?.value;

  void Function(int)? get onChanged => onChangedArg?.value;

  @override
  List<Arg?> get list => [
    itemsArg,
    keyArg,
    initialIndexArg,
    selectedIndexArg,
    onChangedArg,
  ];
}
