// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'aura_corner_radius_scope.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<RadiusScopeDemo, StoryArgs<RadiusScopeDemo>>;
typedef _Scenario = RadiusScopeDemoScenario;
typedef _Defaults = RadiusScopeDemoDefaults;
typedef _Story = RadiusScopeDemoStory;
typedef _Args = _RadiusScopeInputArgs;
final RadiusScopeDemoComponent =
    Component<RadiusScopeDemo, StoryArgs<RadiusScopeDemo>>(
      name: 'RadiusScopeDemo',
      path: 'aura_ui',
      docComment:
          r'''Shows a token-selected scope and a nested pixel adjustment.''',
      stories: [
        $SelectionAndAdjustment..$generatedName = 'SelectionAndAdjustment',
      ],
    );
typedef RadiusScopeDemoScenario =
    Scenario<RadiusScopeDemo, _RadiusScopeInputArgs>;
typedef RadiusScopeDemoDefaults =
    Defaults<RadiusScopeDemo, _RadiusScopeInputArgs>;

class RadiusScopeDemoStory
    extends Story<RadiusScopeDemo, _RadiusScopeInputArgs> {
  RadiusScopeDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _RadiusScopeInputArgs? args,
    StoryWidgetBuilder<RadiusScopeDemo, _RadiusScopeInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _RadiusScopeInputArgs(),
         builder: builder ?? _radiusScopeDefaults.builder!,
       );
}

class _RadiusScopeInputArgs extends StoryArgs<RadiusScopeDemo> {
  _RadiusScopeInputArgs({Arg<AuraBorderRadius>? level, Arg<double>? delta})
    : this.levelArg = $initArg(
        'level',
        level,
        EnumArg<AuraBorderRadius>(
          AuraBorderRadius.none,
          values: AuraBorderRadius.values,
        ),
      )!,
      this.deltaArg = $initArg('delta', delta, DoubleArg(0.0))!;

  _RadiusScopeInputArgs.fixed({
    AuraBorderRadius level = AuraBorderRadius.none,
    double delta = 0.0,
  }) : this.levelArg = $initArg('level', Arg.fixed(level), null)!,
       this.deltaArg = $initArg('delta', Arg.fixed(delta), null)!;

  final Arg<AuraBorderRadius> levelArg;

  final Arg<double> deltaArg;

  AuraBorderRadius get level => levelArg.value;

  double get delta => deltaArg.value;

  @override
  List<Arg?> get list => [levelArg, deltaArg];
}
