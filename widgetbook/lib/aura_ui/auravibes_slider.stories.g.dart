// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_slider.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SliderDemo, StoryArgs<SliderDemo>>;
typedef _Scenario = SliderDemoScenario;
typedef _Defaults = SliderDemoDefaults;
typedef _Story = SliderDemoStory;
typedef _Args = SliderDemoArgs;
final SliderDemoComponent = Component<SliderDemo, StoryArgs<SliderDemo>>(
  name: component.name ?? 'SliderDemo',
  path: component.path ?? 'aura_ui',
  docsBuilder: component.docsBuilder,
  docComment:
      r'''Demonstrates an interactive slider with enabled and tinted states.''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef SliderDemoScenario = Scenario<SliderDemo, SliderDemoArgs>;
typedef SliderDemoDefaults = Defaults<SliderDemo, SliderDemoArgs>;

class SliderDemoStory extends Story<SliderDemo, SliderDemoArgs> {
  SliderDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    SliderDemoArgs? args,
    StoryWidgetBuilder<SliderDemo, SliderDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SliderDemoArgs(),
         builder:
             builder ??
             (context, args) => SliderDemo(
               key: args.key,
               enabled: args.enabled,
               tint: args.tint,
             ),
       );
}

class SliderDemoArgs extends StoryArgs<SliderDemo> {
  SliderDemoArgs({Arg<Key?>? key, Arg<bool>? enabled, Arg<AuraTint>? tint})
    : this.keyArg = $initArg('key', key, null),
      this.enabledArg = $initArg('enabled', enabled, BoolArg(false))!,
      this.tintArg = $initArg(
        'tint',
        tint,
        EnumArg<AuraTint>(AuraTint.primary, values: AuraTint.values),
      )!;

  SliderDemoArgs.fixed({
    Key? key,
    bool enabled = false,
    AuraTint tint = AuraTint.primary,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.tintArg = $initArg('tint', Arg.fixed(tint), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  final Arg<AuraTint> tintArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  AuraTint get tint => tintArg.value;

  @override
  List<Arg?> get list => [keyArg, enabledArg, tintArg];
}
