// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_spinner.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraSpinner, StoryArgs<AuraSpinner>>;
typedef _Scenario = AuraSpinnerScenario;
typedef _Defaults = AuraSpinnerDefaults;
typedef _Story = AuraSpinnerStory;
typedef _Args = _SpinnerInputArgs;
final AuraSpinnerComponent = Component<AuraSpinner, StoryArgs<AuraSpinner>>(
  name: 'AuraSpinner',
  path: 'aura_ui',
  docComment: r'''A customizable loading spinner component following the Aura design system.''',
  stories: [$AuraSpinner..$generatedName = 'AuraSpinner'],
);
typedef AuraSpinnerScenario = Scenario<AuraSpinner, _SpinnerInputArgs>;
typedef AuraSpinnerDefaults = Defaults<AuraSpinner, _SpinnerInputArgs>;

class AuraSpinnerStory extends Story<AuraSpinner, _SpinnerInputArgs> {
  AuraSpinnerStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _SpinnerInputArgs? args,
    StoryWidgetBuilder<AuraSpinner, _SpinnerInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _SpinnerInputArgs(),
         builder: builder ?? spinnerDefaults.builder!,
       );
}

class _SpinnerInputArgs extends StoryArgs<AuraSpinner> {
  _SpinnerInputArgs({
    Arg<AuraSpinnerSize>? size,
    Arg<AuraTint?>? tint,
    Arg<double>? strokeWidth,
    Arg<String>? semanticLabel,
  }) : this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<AuraSpinnerSize>(
           AuraSpinnerSize.extraSmall,
           values: AuraSpinnerSize.values,
         ),
       )!,
       this.tintArg = $initArg(
         'tint',
         tint,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!,
       this.strokeWidthArg = $initArg(
         'strokeWidth',
         strokeWidth,
         DoubleArg(0.0),
       )!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         StringArg(''),
       )!;

  _SpinnerInputArgs.fixed({
    AuraSpinnerSize size = AuraSpinnerSize.extraSmall,
    AuraTint? tint = null,
    double strokeWidth = 0.0,
    String semanticLabel = '',
  }) : this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.tintArg = $initArg(
         'tint',
         tint == null ? null : Arg.fixed(tint),
         null,
       ),
       this.strokeWidthArg = $initArg(
         'strokeWidth',
         Arg.fixed(strokeWidth),
         null,
       )!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         Arg.fixed(semanticLabel),
         null,
       )!;

  final Arg<AuraSpinnerSize> sizeArg;

  final Arg<AuraTint?>? tintArg;

  final Arg<double> strokeWidthArg;

  final Arg<String> semanticLabelArg;

  AuraSpinnerSize get size => sizeArg.value;

  AuraTint? get tint => tintArg?.value;

  double get strokeWidth => strokeWidthArg.value;

  String get semanticLabel => semanticLabelArg.value;

  @override
  List<Arg?> get list => [sizeArg, tintArg, strokeWidthArg, semanticLabelArg];
}
