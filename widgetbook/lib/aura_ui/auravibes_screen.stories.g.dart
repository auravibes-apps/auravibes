// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_screen.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraScreen, StoryArgs<AuraScreen>>;
typedef _Scenario = AuraScreenScenario;
typedef _Defaults = AuraScreenDefaults;
typedef _Story = AuraScreenStory;
typedef _Args = _ScreenInputArgs;
final AuraScreenComponent = Component<AuraScreen, StoryArgs<AuraScreen>>(
  name: 'AuraScreen',
  path: 'aura_ui',
  docComment: r'''Screen manager.''',
  stories: [$AuraScreen..$generatedName = 'AuraScreen'],
);
typedef AuraScreenScenario = Scenario<AuraScreen, _ScreenInputArgs>;
typedef AuraScreenDefaults = Defaults<AuraScreen, _ScreenInputArgs>;

class AuraScreenStory extends Story<AuraScreen, _ScreenInputArgs> {
  AuraScreenStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _ScreenInputArgs? args,
    StoryWidgetBuilder<AuraScreen, _ScreenInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _ScreenInputArgs(),
         builder: builder ?? screenDefaults.builder!,
       );
}

class _ScreenInputArgs extends StoryArgs<AuraScreen> {
  _ScreenInputArgs({Arg<AuraScreenVariation>? variant})
    : this.variantArg = $initArg(
        'variant',
        variant,
        EnumArg<AuraScreenVariation>(
          AuraScreenVariation.standard,
          values: AuraScreenVariation.values,
        ),
      )!;

  _ScreenInputArgs.fixed({
    AuraScreenVariation variant = AuraScreenVariation.standard,
  }) : this.variantArg = $initArg('variant', Arg.fixed(variant), null)!;

  final Arg<AuraScreenVariation> variantArg;

  AuraScreenVariation get variant => variantArg.value;

  @override
  List<Arg?> get list => [variantArg];
}
