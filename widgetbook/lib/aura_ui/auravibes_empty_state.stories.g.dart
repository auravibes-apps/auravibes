// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_empty_state.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraEmptyState, StoryArgs<AuraEmptyState>>;
typedef _Scenario = AuraEmptyStateScenario;
typedef _Defaults = AuraEmptyStateDefaults;
typedef _Story = AuraEmptyStateStory;
typedef _Args = AuraEmptyStateArgs;
final AuraEmptyStateComponent =
    Component<AuraEmptyState, StoryArgs<AuraEmptyState>>(
      name: 'AuraEmptyState',
      path: 'aura_ui',
      docComment: r'''A reusable empty region with caller-owned copy and optional action.''',
      stories: [$Example..$generatedName = 'Example'],
    );
typedef AuraEmptyStateScenario = Scenario<AuraEmptyState, AuraEmptyStateArgs>;
typedef AuraEmptyStateDefaults = Defaults<AuraEmptyState, AuraEmptyStateArgs>;

class AuraEmptyStateStory extends Story<AuraEmptyState, AuraEmptyStateArgs> {
  AuraEmptyStateStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<AuraEmptyState, AuraEmptyStateArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         builder:
             builder ??
             (context, args) => AuraEmptyState(
               title: args.title,
               key: args.key,
               description: args.description,
               icon: args.icon,
               action: args.action,
             ),
       );
}

class AuraEmptyStateArgs extends StoryArgs<AuraEmptyState> {
  AuraEmptyStateArgs({
    required Arg<Widget> title,
    Arg<Key?>? key,
    Arg<Widget?>? description,
    Arg<Widget?>? icon,
    Arg<Widget?>? action,
  }) : this.titleArg = $initArg('title', title, null)!,
       this.keyArg = $initArg('key', key, null),
       this.descriptionArg = $initArg('description', description, null),
       this.iconArg = $initArg('icon', icon, null),
       this.actionArg = $initArg('action', action, null);

  AuraEmptyStateArgs.fixed({
    required Widget title,
    Key? key,
    Widget? description,
    Widget? icon,
    Widget? action,
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.descriptionArg = $initArg(
         'description',
         description == null ? null : Arg.fixed(description),
         null,
       ),
       this.iconArg = $initArg(
         'icon',
         icon == null ? null : Arg.fixed(icon),
         null,
       ),
       this.actionArg = $initArg(
         'action',
         action == null ? null : Arg.fixed(action),
         null,
       );

  final Arg<Widget> titleArg;

  final Arg<Key?>? keyArg;

  final Arg<Widget?>? descriptionArg;

  final Arg<Widget?>? iconArg;

  final Arg<Widget?>? actionArg;

  Widget get title => titleArg.value;

  Key? get key => keyArg?.value;

  Widget? get description => descriptionArg?.value;

  Widget? get icon => iconArg?.value;

  Widget? get action => actionArg?.value;

  @override
  List<Arg?> get list => [titleArg, keyArg, descriptionArg, iconArg, actionArg];
}
