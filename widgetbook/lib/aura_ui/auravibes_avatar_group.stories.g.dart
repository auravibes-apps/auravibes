// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_avatar_group.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraAvatarGroup, StoryArgs<AuraAvatarGroup>>;
typedef _Scenario = AuraAvatarGroupScenario;
typedef _Defaults = AuraAvatarGroupDefaults;
typedef _Story = AuraAvatarGroupStory;
typedef _Args = AuraAvatarGroupArgs;
final AuraAvatarGroupComponent =
    Component<AuraAvatarGroup, StoryArgs<AuraAvatarGroup>>(
      name: 'AuraAvatarGroup',
      path: 'aura_ui',
      docComment:
          r'''A compact, wrapping group of avatars with an overflow count.''',
      stories: [$Example..$generatedName = 'Example'],
    );
typedef AuraAvatarGroupScenario =
    Scenario<AuraAvatarGroup, AuraAvatarGroupArgs>;
typedef AuraAvatarGroupDefaults =
    Defaults<AuraAvatarGroup, AuraAvatarGroupArgs>;

class AuraAvatarGroupStory extends Story<AuraAvatarGroup, AuraAvatarGroupArgs> {
  AuraAvatarGroupStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<AuraAvatarGroup, AuraAvatarGroupArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         builder:
             builder ??
             (context, args) => AuraAvatarGroup(
               children: args.children,
               key: args.key,
               maxVisible: args.maxVisible,
               overflowSemanticLabel: args.overflowSemanticLabel,
             ),
       );
}

class AuraAvatarGroupArgs extends StoryArgs<AuraAvatarGroup> {
  AuraAvatarGroupArgs({
    required Arg<List<Widget>> children,
    Arg<Key?>? key,
    Arg<int>? maxVisible,
    Arg<String?>? overflowSemanticLabel,
  }) : this.childrenArg = $initArg('children', children, null)!,
       this.keyArg = $initArg('key', key, null),
       this.maxVisibleArg = $initArg('maxVisible', maxVisible, IntArg(5))!,
       this.overflowSemanticLabelArg = $initArg(
         'overflowSemanticLabel',
         overflowSemanticLabel,
         NullableStringArg(null),
       )!;

  AuraAvatarGroupArgs.fixed({
    required List<Widget> children,
    Key? key,
    int maxVisible = 5,
    String? overflowSemanticLabel = null,
  }) : this.childrenArg = $initArg('children', Arg.fixed(children), null)!,
       this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.maxVisibleArg = $initArg(
         'maxVisible',
         Arg.fixed(maxVisible),
         null,
       )!,
       this.overflowSemanticLabelArg = $initArg(
         'overflowSemanticLabel',
         overflowSemanticLabel == null
             ? null
             : Arg.fixed(overflowSemanticLabel),
         null,
       );

  final Arg<List<Widget>> childrenArg;

  final Arg<Key?>? keyArg;

  final Arg<int> maxVisibleArg;

  final Arg<String?>? overflowSemanticLabelArg;

  List<Widget> get children => childrenArg.value;

  Key? get key => keyArg?.value;

  int get maxVisible => maxVisibleArg.value;

  String? get overflowSemanticLabel => overflowSemanticLabelArg?.value;

  @override
  List<Arg?> get list => [
    childrenArg,
    keyArg,
    maxVisibleArg,
    overflowSemanticLabelArg,
  ];
}
