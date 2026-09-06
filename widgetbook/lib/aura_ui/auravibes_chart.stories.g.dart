// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_chart.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraChart, StoryArgs<AuraChart>>;
typedef _Scenario = AuraChartScenario;
typedef _Defaults = AuraChartDefaults;
typedef _Story = AuraChartStory;
typedef _Args = AuraChartArgs;
final AuraChartComponent = Component<AuraChart, StoryArgs<AuraChart>>(
  name: 'AuraChart',
  path: 'aura_ui',
  docComment: r'''A static chart rendered with Flutter drawing primitives and a text legend.''',
  stories: [$Example..$generatedName = 'Example'],
);
typedef AuraChartScenario = Scenario<AuraChart, AuraChartArgs>;
typedef AuraChartDefaults = Defaults<AuraChart, AuraChartArgs>;

class AuraChartStory extends Story<AuraChart, AuraChartArgs> {
  AuraChartStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<AuraChart, AuraChartArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         builder:
             builder ??
             (context, args) => AuraChart(
               labels: args.labels,
               series: args.series,
               semanticLabel: args.semanticLabel,
               key: args.key,
               type: args.type,
               stacked: args.stacked,
               minY: args.minY,
               maxY: args.maxY,
               xAxisTitle: args.xAxisTitle,
               yAxisTitle: args.yAxisTitle,
               unit: args.unit,
               palette: args.palette,
             ),
       );
}

class AuraChartArgs extends StoryArgs<AuraChart> {
  AuraChartArgs({
    required Arg<List<String>> labels,
    required Arg<List<AuraChartSeries>> series,
    Arg<String>? semanticLabel,
    Arg<Key?>? key,
    Arg<AuraChartType>? type,
    Arg<bool>? stacked,
    Arg<double?>? minY,
    Arg<double?>? maxY,
    Arg<String?>? xAxisTitle,
    Arg<String?>? yAxisTitle,
    Arg<String?>? unit,
    Arg<List<AuraTint>>? palette,
  }) : this.labelsArg = $initArg('labels', labels, null)!,
       this.seriesArg = $initArg('series', series, null)!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         StringArg(''),
       )!,
       this.keyArg = $initArg('key', key, null),
       this.typeArg = $initArg(
         'type',
         type,
         EnumArg<AuraChartType>(
           AuraChartType.line,
           values: AuraChartType.values,
         ),
       )!,
       this.stackedArg = $initArg('stacked', stacked, BoolArg(false))!,
       this.minYArg = $initArg('minY', minY, NullableDoubleArg(null))!,
       this.maxYArg = $initArg('maxY', maxY, NullableDoubleArg(null))!,
       this.xAxisTitleArg = $initArg(
         'xAxisTitle',
         xAxisTitle,
         NullableStringArg(null),
       )!,
       this.yAxisTitleArg = $initArg(
         'yAxisTitle',
         yAxisTitle,
         NullableStringArg(null),
       )!,
       this.unitArg = $initArg('unit', unit, NullableStringArg(null))!,
       this.paletteArg = $initArg('palette', palette, ConstArg(const []))!;

  AuraChartArgs.fixed({
    required List<String> labels,
    required List<AuraChartSeries> series,
    String semanticLabel = '',
    Key? key,
    AuraChartType type = AuraChartType.line,
    bool stacked = false,
    double? minY = null,
    double? maxY = null,
    String? xAxisTitle = null,
    String? yAxisTitle = null,
    String? unit = null,
    List<AuraTint> palette = const [],
  }) : this.labelsArg = $initArg('labels', Arg.fixed(labels), null)!,
       this.seriesArg = $initArg('series', Arg.fixed(series), null)!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         Arg.fixed(semanticLabel),
         null,
       )!,
       this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.typeArg = $initArg('type', Arg.fixed(type), null)!,
       this.stackedArg = $initArg('stacked', Arg.fixed(stacked), null)!,
       this.minYArg = $initArg(
         'minY',
         minY == null ? null : Arg.fixed(minY),
         null,
       ),
       this.maxYArg = $initArg(
         'maxY',
         maxY == null ? null : Arg.fixed(maxY),
         null,
       ),
       this.xAxisTitleArg = $initArg(
         'xAxisTitle',
         xAxisTitle == null ? null : Arg.fixed(xAxisTitle),
         null,
       ),
       this.yAxisTitleArg = $initArg(
         'yAxisTitle',
         yAxisTitle == null ? null : Arg.fixed(yAxisTitle),
         null,
       ),
       this.unitArg = $initArg(
         'unit',
         unit == null ? null : Arg.fixed(unit),
         null,
       ),
       this.paletteArg = $initArg('palette', Arg.fixed(palette), null)!;

  final Arg<List<String>> labelsArg;

  final Arg<List<AuraChartSeries>> seriesArg;

  final Arg<String> semanticLabelArg;

  final Arg<Key?>? keyArg;

  final Arg<AuraChartType> typeArg;

  final Arg<bool> stackedArg;

  final Arg<double?>? minYArg;

  final Arg<double?>? maxYArg;

  final Arg<String?>? xAxisTitleArg;

  final Arg<String?>? yAxisTitleArg;

  final Arg<String?>? unitArg;

  final Arg<List<AuraTint>> paletteArg;

  List<String> get labels => labelsArg.value;

  List<AuraChartSeries> get series => seriesArg.value;

  String get semanticLabel => semanticLabelArg.value;

  Key? get key => keyArg?.value;

  AuraChartType get type => typeArg.value;

  bool get stacked => stackedArg.value;

  double? get minY => minYArg?.value;

  double? get maxY => maxYArg?.value;

  String? get xAxisTitle => xAxisTitleArg?.value;

  String? get yAxisTitle => yAxisTitleArg?.value;

  String? get unit => unitArg?.value;

  List<AuraTint> get palette => paletteArg.value;

  @override
  List<Arg?> get list => [
    labelsArg,
    seriesArg,
    semanticLabelArg,
    keyArg,
    typeArg,
    stackedArg,
    minYArg,
    maxYArg,
    xAxisTitleArg,
    yAxisTitleArg,
    unitArg,
    paletteArg,
  ];
}
