// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_container.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraContainer, StoryArgs<AuraContainer>>;
typedef _Scenario = AuraContainerScenario;
typedef _Defaults = AuraContainerDefaults;
typedef _Story = AuraContainerStory;
typedef _Args = _ContainerInputArgs;
final AuraContainerComponent =
    Component<AuraContainer, StoryArgs<AuraContainer>>(
      name: 'AuraContainer',
      path: 'aura_ui',
      docComment: r'''A customizable layout container component following the Aura design system.

This container provides consistent padding, margin, background colors,
border radius, and shadow options for layout organization.''',
      stories: [$BasicContainer..$generatedName = 'BasicContainer'],
    );
typedef AuraContainerScenario = Scenario<AuraContainer, _ContainerInputArgs>;
typedef AuraContainerDefaults = Defaults<AuraContainer, _ContainerInputArgs>;

class AuraContainerStory extends Story<AuraContainer, _ContainerInputArgs> {
  AuraContainerStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<AuraContainer, _ContainerInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(builder: builder ?? containerDefaults.builder!);
}

class _ContainerInputArgs extends StoryArgs<AuraContainer> {
  _ContainerInputArgs({
    required Arg<AuraEdgeInsetsGeometry> padding,
    required Arg<AuraEdgeInsetsGeometry> margin,
    Arg<AuraContainerShadow>? shadow,
  }) : this.paddingArg = $initArg('padding', padding, null)!,
       this.marginArg = $initArg('margin', margin, null)!,
       this.shadowArg = $initArg(
         'shadow',
         shadow,
         EnumArg<AuraContainerShadow>(
           AuraContainerShadow.none,
           values: AuraContainerShadow.values,
         ),
       )!;

  _ContainerInputArgs.fixed({
    required AuraEdgeInsetsGeometry padding,
    required AuraEdgeInsetsGeometry margin,
    AuraContainerShadow shadow = AuraContainerShadow.none,
  }) : this.paddingArg = $initArg('padding', Arg.fixed(padding), null)!,
       this.marginArg = $initArg('margin', Arg.fixed(margin), null)!,
       this.shadowArg = $initArg('shadow', Arg.fixed(shadow), null)!;

  final Arg<AuraEdgeInsetsGeometry> paddingArg;

  final Arg<AuraEdgeInsetsGeometry> marginArg;

  final Arg<AuraContainerShadow> shadowArg;

  AuraEdgeInsetsGeometry get padding => paddingArg.value;

  AuraEdgeInsetsGeometry get margin => marginArg.value;

  AuraContainerShadow get shadow => shadowArg.value;

  @override
  List<Arg?> get list => [paddingArg, marginArg, shadowArg];
}
