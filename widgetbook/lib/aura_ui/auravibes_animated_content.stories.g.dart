// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_animated_content.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<AuraAnimatedContent, StoryArgs<AuraAnimatedContent>>;
typedef _Scenario = AuraAnimatedContentScenario;
typedef _Defaults = AuraAnimatedContentDefaults;
typedef _Story = AuraAnimatedContentStory;
typedef _Args = AuraAnimatedContentArgs;
final AuraAnimatedContentComponent =
    Component<AuraAnimatedContent, StoryArgs<AuraAnimatedContent>>(
      name: 'AuraAnimatedContent',
      path: 'aura_ui',
      docComment: r'''A brief fade between keyed children, disabled for reduced motion.''',
      stories: [$Example..$generatedName = 'Example'],
    );
typedef AuraAnimatedContentScenario =
    Scenario<AuraAnimatedContent, AuraAnimatedContentArgs>;
typedef AuraAnimatedContentDefaults =
    Defaults<AuraAnimatedContent, AuraAnimatedContentArgs>;

class AuraAnimatedContentStory
    extends Story<AuraAnimatedContent, AuraAnimatedContentArgs> {
  AuraAnimatedContentStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<AuraAnimatedContent, AuraAnimatedContentArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         builder:
             builder ??
             (context, args) => AuraAnimatedContent(
               child: args.child,
               key: args.key,
               transition: args.transition,
             ),
       );
}

class AuraAnimatedContentArgs extends StoryArgs<AuraAnimatedContent> {
  AuraAnimatedContentArgs({
    required Arg<Widget> child,
    Arg<Key?>? key,
    Arg<AuraContentTransition>? transition,
  }) : this.childArg = $initArg('child', child, null)!,
       this.keyArg = $initArg('key', key, null),
       this.transitionArg = $initArg(
         'transition',
         transition,
         EnumArg<AuraContentTransition>(
           AuraContentTransition.fade,
           values: AuraContentTransition.values,
         ),
       )!;

  AuraAnimatedContentArgs.fixed({
    required Widget child,
    Key? key,
    AuraContentTransition transition = AuraContentTransition.fade,
  }) : this.childArg = $initArg('child', Arg.fixed(child), null)!,
       this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.transitionArg = $initArg(
         'transition',
         Arg.fixed(transition),
         null,
       )!;

  final Arg<Widget> childArg;

  final Arg<Key?>? keyArg;

  final Arg<AuraContentTransition> transitionArg;

  Widget get child => childArg.value;

  Key? get key => keyArg?.value;

  AuraContentTransition get transition => transitionArg.value;

  @override
  List<Arg?> get list => [childArg, keyArg, transitionArg];
}
