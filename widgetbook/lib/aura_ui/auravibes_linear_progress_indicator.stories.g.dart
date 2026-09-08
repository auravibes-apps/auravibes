// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_linear_progress_indicator.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<
      AuraLinearProgressIndicator,
      StoryArgs<AuraLinearProgressIndicator>
    >;
typedef _Scenario = AuraLinearProgressIndicatorScenario;
typedef _Defaults = AuraLinearProgressIndicatorDefaults;
typedef _Story = AuraLinearProgressIndicatorStory;
typedef _Args = _ProgressInputArgs;
final AuraLinearProgressIndicatorComponent =
    Component<
      AuraLinearProgressIndicator,
      StoryArgs<AuraLinearProgressIndicator>
    >(
      name: 'AuraLinearProgressIndicator',
      path: 'aura_ui',
      docComment:
          r'''A linear progress indicator following the Aura design system.''',
      stories: [$Progress..$generatedName = 'Progress'],
    );
typedef AuraLinearProgressIndicatorScenario =
    Scenario<AuraLinearProgressIndicator, _ProgressInputArgs>;
typedef AuraLinearProgressIndicatorDefaults =
    Defaults<AuraLinearProgressIndicator, _ProgressInputArgs>;

class AuraLinearProgressIndicatorStory
    extends Story<AuraLinearProgressIndicator, _ProgressInputArgs> {
  AuraLinearProgressIndicatorStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _ProgressInputArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? _ProgressInputArgs());
}

class _ProgressInputArgs extends StoryArgs<AuraLinearProgressIndicator> {
  _ProgressInputArgs({
    Arg<double>? value,
    Arg<double>? height,
    Arg<AuraTint>? tint,
    Arg<double>? backgroundAlpha,
    Arg<AuraBorderRadius>? borderRadius,
    Arg<String>? semanticLabel,
    Arg<String>? semanticValue,
  }) : this.valueArg = $initArg('value', value, DoubleArg(0.0))!,
       this.heightArg = $initArg('height', height, DoubleArg(0.0))!,
       this.tintArg = $initArg(
         'tint',
         tint,
         EnumArg<AuraTint>(AuraTint.primary, values: AuraTint.values),
       )!,
       this.backgroundAlphaArg = $initArg(
         'backgroundAlpha',
         backgroundAlpha,
         DoubleArg(0.0),
       )!,
       this.borderRadiusArg = $initArg(
         'borderRadius',
         borderRadius,
         EnumArg<AuraBorderRadius>(
           AuraBorderRadius.none,
           values: AuraBorderRadius.values,
         ),
       )!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         StringArg(''),
       )!,
       this.semanticValueArg = $initArg(
         'semanticValue',
         semanticValue,
         StringArg(''),
       )!;

  _ProgressInputArgs.fixed({
    double value = 0.0,
    double height = 0.0,
    AuraTint tint = AuraTint.primary,
    double backgroundAlpha = 0.0,
    AuraBorderRadius borderRadius = AuraBorderRadius.none,
    String semanticLabel = '',
    String semanticValue = '',
  }) : this.valueArg = $initArg('value', Arg.fixed(value), null)!,
       this.heightArg = $initArg('height', Arg.fixed(height), null)!,
       this.tintArg = $initArg('tint', Arg.fixed(tint), null)!,
       this.backgroundAlphaArg = $initArg(
         'backgroundAlpha',
         Arg.fixed(backgroundAlpha),
         null,
       )!,
       this.borderRadiusArg = $initArg(
         'borderRadius',
         Arg.fixed(borderRadius),
         null,
       )!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         Arg.fixed(semanticLabel),
         null,
       )!,
       this.semanticValueArg = $initArg(
         'semanticValue',
         Arg.fixed(semanticValue),
         null,
       )!;

  final Arg<double> valueArg;

  final Arg<double> heightArg;

  final Arg<AuraTint> tintArg;

  final Arg<double> backgroundAlphaArg;

  final Arg<AuraBorderRadius> borderRadiusArg;

  final Arg<String> semanticLabelArg;

  final Arg<String> semanticValueArg;

  double get value => valueArg.value;

  double get height => heightArg.value;

  AuraTint get tint => tintArg.value;

  double get backgroundAlpha => backgroundAlphaArg.value;

  AuraBorderRadius get borderRadius => borderRadiusArg.value;

  String get semanticLabel => semanticLabelArg.value;

  String get semanticValue => semanticValueArg.value;

  @override
  List<Arg?> get list => [
    valueArg,
    heightArg,
    tintArg,
    backgroundAlphaArg,
    borderRadiusArg,
    semanticLabelArg,
    semanticValueArg,
  ];
}
