// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_radio_group.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<RadioGroupDemo, StoryArgs<RadioGroupDemo>>;
typedef _Scenario = RadioGroupDemoScenario;
typedef _Defaults = RadioGroupDemoDefaults;
typedef _Story = RadioGroupDemoStory;
typedef _Args = RadioGroupDemoArgs;
final RadioGroupDemoComponent =
    Component<RadioGroupDemo, StoryArgs<RadioGroupDemo>>(
      name: component.name ?? 'RadioGroupDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment: r'''Demonstrates a controlled radio group in vertical and horizontal layouts.''',
      stories: [$RadioGroup..$generatedName = 'RadioGroup'],
    );
typedef RadioGroupDemoScenario = Scenario<RadioGroupDemo, RadioGroupDemoArgs>;
typedef RadioGroupDemoDefaults = Defaults<RadioGroupDemo, RadioGroupDemoArgs>;

class RadioGroupDemoStory extends Story<RadioGroupDemo, RadioGroupDemoArgs> {
  RadioGroupDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    RadioGroupDemoArgs? args,
    StoryWidgetBuilder<RadioGroupDemo, RadioGroupDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? RadioGroupDemoArgs(),
         builder:
             builder ??
             (context, args) => RadioGroupDemo(
               key: args.key,
               direction: args.direction,
               tint: args.tint,
               showLabel: args.showLabel,
               showSubtitles: args.showSubtitles,
             ),
       );
}

class RadioGroupDemoArgs extends StoryArgs<RadioGroupDemo> {
  RadioGroupDemoArgs({
    Arg<Key?>? key,
    Arg<Axis>? direction,
    Arg<AuraTint?>? tint,
    Arg<bool>? showLabel,
    Arg<bool>? showSubtitles,
  }) : this.keyArg = $initArg('key', key, null),
       this.directionArg = $initArg(
         'direction',
         direction,
         EnumArg<Axis>(Axis.horizontal, values: Axis.values),
       )!,
       this.tintArg = $initArg(
         'tint',
         tint,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!,
       this.showLabelArg = $initArg('showLabel', showLabel, BoolArg(false))!,
       this.showSubtitlesArg = $initArg(
         'showSubtitles',
         showSubtitles,
         BoolArg(false),
       )!;

  RadioGroupDemoArgs.fixed({
    Key? key,
    Axis direction = Axis.horizontal,
    AuraTint? tint = null,
    bool showLabel = false,
    bool showSubtitles = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.directionArg = $initArg('direction', Arg.fixed(direction), null)!,
       this.tintArg = $initArg(
         'tint',
         tint == null ? null : Arg.fixed(tint),
         null,
       ),
       this.showLabelArg = $initArg('showLabel', Arg.fixed(showLabel), null)!,
       this.showSubtitlesArg = $initArg(
         'showSubtitles',
         Arg.fixed(showSubtitles),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<Axis> directionArg;

  final Arg<AuraTint?>? tintArg;

  final Arg<bool> showLabelArg;

  final Arg<bool> showSubtitlesArg;

  Key? get key => keyArg?.value;

  Axis get direction => directionArg.value;

  AuraTint? get tint => tintArg?.value;

  bool get showLabel => showLabelArg.value;

  bool get showSubtitles => showSubtitlesArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    directionArg,
    tintArg,
    showLabelArg,
    showSubtitlesArg,
  ];
}
