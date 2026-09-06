// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_table.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraTable, StoryArgs<AuraTable>>;
typedef _Scenario = AuraTableScenario;
typedef _Defaults = AuraTableDefaults;
typedef _Story = AuraTableStory;
typedef _Args = AuraTableArgs;
final AuraTableComponent = Component<AuraTable, StoryArgs<AuraTable>>(
  name: 'AuraTable',
  path: 'aura_ui',
  docComment: r'''A read-only table that scrolls horizontally when its columns do not fit.''',
  stories: [$Example..$generatedName = 'Example'],
);
typedef AuraTableScenario = Scenario<AuraTable, AuraTableArgs>;
typedef AuraTableDefaults = Defaults<AuraTable, AuraTableArgs>;

class AuraTableStory extends Story<AuraTable, AuraTableArgs> {
  AuraTableStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<AuraTable, AuraTableArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         builder:
             builder ??
             (context, args) => AuraTable(
               columns: args.columns,
               rows: args.rows,
               key: args.key,
               caption: args.caption,
               columnAlignments: args.columnAlignments,
               columnFormats: args.columnFormats,
               sortableColumns: args.sortableColumns,
               rowTints: args.rowTints,
               emptyText: args.emptyText,
               noValueLabel: args.noValueLabel,
             ),
       );
}

class AuraTableArgs extends StoryArgs<AuraTable> {
  AuraTableArgs({
    required Arg<List<String>> columns,
    required Arg<List<List<Object?>>> rows,
    Arg<Key?>? key,
    Arg<Widget?>? caption,
    Arg<List<AuraTableAlignment>>? columnAlignments,
    Arg<List<AuraTableValueFormat>>? columnFormats,
    Arg<List<bool>>? sortableColumns,
    Arg<List<AuraTint?>>? rowTints,
    Arg<String?>? emptyText,
    Arg<String>? noValueLabel,
  }) : this.columnsArg = $initArg('columns', columns, null)!,
       this.rowsArg = $initArg('rows', rows, null)!,
       this.keyArg = $initArg('key', key, null),
       this.captionArg = $initArg('caption', caption, null),
       this.columnAlignmentsArg = $initArg(
         'columnAlignments',
         columnAlignments,
         ConstArg(const []),
       )!,
       this.columnFormatsArg = $initArg(
         'columnFormats',
         columnFormats,
         ConstArg(const []),
       )!,
       this.sortableColumnsArg = $initArg(
         'sortableColumns',
         sortableColumns,
         ConstArg(const []),
       )!,
       this.rowTintsArg = $initArg('rowTints', rowTints, ConstArg(const []))!,
       this.emptyTextArg = $initArg(
         'emptyText',
         emptyText,
         NullableStringArg(null),
       )!,
       this.noValueLabelArg = $initArg(
         'noValueLabel',
         noValueLabel,
         StringArg('No value'),
       )!;

  AuraTableArgs.fixed({
    required List<String> columns,
    required List<List<Object?>> rows,
    Key? key,
    Widget? caption,
    List<AuraTableAlignment> columnAlignments = const [],
    List<AuraTableValueFormat> columnFormats = const [],
    List<bool> sortableColumns = const [],
    List<AuraTint?> rowTints = const [],
    String? emptyText = null,
    String noValueLabel = 'No value',
  }) : this.columnsArg = $initArg('columns', Arg.fixed(columns), null)!,
       this.rowsArg = $initArg('rows', Arg.fixed(rows), null)!,
       this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.captionArg = $initArg(
         'caption',
         caption == null ? null : Arg.fixed(caption),
         null,
       ),
       this.columnAlignmentsArg = $initArg(
         'columnAlignments',
         Arg.fixed(columnAlignments),
         null,
       )!,
       this.columnFormatsArg = $initArg(
         'columnFormats',
         Arg.fixed(columnFormats),
         null,
       )!,
       this.sortableColumnsArg = $initArg(
         'sortableColumns',
         Arg.fixed(sortableColumns),
         null,
       )!,
       this.rowTintsArg = $initArg('rowTints', Arg.fixed(rowTints), null)!,
       this.emptyTextArg = $initArg(
         'emptyText',
         emptyText == null ? null : Arg.fixed(emptyText),
         null,
       ),
       this.noValueLabelArg = $initArg(
         'noValueLabel',
         Arg.fixed(noValueLabel),
         null,
       )!;

  final Arg<List<String>> columnsArg;

  final Arg<List<List<Object?>>> rowsArg;

  final Arg<Key?>? keyArg;

  final Arg<Widget?>? captionArg;

  final Arg<List<AuraTableAlignment>> columnAlignmentsArg;

  final Arg<List<AuraTableValueFormat>> columnFormatsArg;

  final Arg<List<bool>> sortableColumnsArg;

  final Arg<List<AuraTint?>> rowTintsArg;

  final Arg<String?>? emptyTextArg;

  final Arg<String> noValueLabelArg;

  List<String> get columns => columnsArg.value;

  List<List<Object?>> get rows => rowsArg.value;

  Key? get key => keyArg?.value;

  Widget? get caption => captionArg?.value;

  List<AuraTableAlignment> get columnAlignments => columnAlignmentsArg.value;

  List<AuraTableValueFormat> get columnFormats => columnFormatsArg.value;

  List<bool> get sortableColumns => sortableColumnsArg.value;

  List<AuraTint?> get rowTints => rowTintsArg.value;

  String? get emptyText => emptyTextArg?.value;

  String get noValueLabel => noValueLabelArg.value;

  @override
  List<Arg?> get list => [
    columnsArg,
    rowsArg,
    keyArg,
    captionArg,
    columnAlignmentsArg,
    columnFormatsArg,
    sortableColumnsArg,
    rowTintsArg,
    emptyTextArg,
    noValueLabelArg,
  ];
}
