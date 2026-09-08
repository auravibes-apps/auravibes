// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_button_group_single.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<SingleSelectionDemo, StoryArgs<SingleSelectionDemo>>;
typedef _Scenario = SingleSelectionDemoScenario;
typedef _Defaults = SingleSelectionDemoDefaults;
typedef _Story = SingleSelectionDemoStory;
typedef _Args = SingleSelectionDemoArgs;
final SingleSelectionDemoComponent =
    Component<SingleSelectionDemo, StoryArgs<SingleSelectionDemo>>(
      name: component.name ?? 'SingleSelectionDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment: r'''Demonstrates a single-selection button group.''',
      stories: [$SingleSelectionRadio..$generatedName = 'SingleSelectionRadio'],
    );
typedef SingleSelectionDemoScenario =
    Scenario<SingleSelectionDemo, SingleSelectionDemoArgs>;
typedef SingleSelectionDemoDefaults =
    Defaults<SingleSelectionDemo, SingleSelectionDemoArgs>;

class SingleSelectionDemoStory
    extends Story<SingleSelectionDemo, SingleSelectionDemoArgs> {
  SingleSelectionDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    SingleSelectionDemoArgs? args,
    StoryWidgetBuilder<SingleSelectionDemo, SingleSelectionDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SingleSelectionDemoArgs(),
         builder:
             builder ??
             (context, args) => SingleSelectionDemo(
               key: args.key,
               size: args.size,
               variant: args.variant,
               orientation: args.orientation,
               disabled: args.disabled,
               isLoading: args.isLoading,
             ),
       );
}

class SingleSelectionDemoArgs extends StoryArgs<SingleSelectionDemo> {
  SingleSelectionDemoArgs({
    Arg<Key?>? key,
    Arg<AuraButtonGroupSize>? size,
    Arg<AuraButtonGroupVariant>? variant,
    Arg<Axis>? orientation,
    Arg<bool>? disabled,
    Arg<bool>? isLoading,
  }) : this.keyArg = $initArg('key', key, null),
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<AuraButtonGroupSize>(
           AuraButtonGroupSize.sm,
           values: AuraButtonGroupSize.values,
         ),
       )!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<AuraButtonGroupVariant>(
           AuraButtonGroupVariant.filled,
           values: AuraButtonGroupVariant.values,
         ),
       )!,
       this.orientationArg = $initArg(
         'orientation',
         orientation,
         EnumArg<Axis>(Axis.horizontal, values: Axis.values),
       )!,
       this.disabledArg = $initArg('disabled', disabled, BoolArg(false))!,
       this.isLoadingArg = $initArg('isLoading', isLoading, BoolArg(false))!;

  SingleSelectionDemoArgs.fixed({
    Key? key,
    AuraButtonGroupSize size = AuraButtonGroupSize.sm,
    AuraButtonGroupVariant variant = AuraButtonGroupVariant.filled,
    Axis orientation = Axis.horizontal,
    bool disabled = false,
    bool isLoading = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.orientationArg = $initArg(
         'orientation',
         Arg.fixed(orientation),
         null,
       )!,
       this.disabledArg = $initArg('disabled', Arg.fixed(disabled), null)!,
       this.isLoadingArg = $initArg('isLoading', Arg.fixed(isLoading), null)!;

  final Arg<Key?>? keyArg;

  final Arg<AuraButtonGroupSize> sizeArg;

  final Arg<AuraButtonGroupVariant> variantArg;

  final Arg<Axis> orientationArg;

  final Arg<bool> disabledArg;

  final Arg<bool> isLoadingArg;

  Key? get key => keyArg?.value;

  AuraButtonGroupSize get size => sizeArg.value;

  AuraButtonGroupVariant get variant => variantArg.value;

  Axis get orientation => orientationArg.value;

  bool get disabled => disabledArg.value;

  bool get isLoading => isLoadingArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    sizeArg,
    variantArg,
    orientationArg,
    disabledArg,
    isLoadingArg,
  ];
}
