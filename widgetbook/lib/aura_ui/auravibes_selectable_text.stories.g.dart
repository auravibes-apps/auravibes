// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_selectable_text.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<SelectableTextDemo, StoryArgs<SelectableTextDemo>>;
typedef _Scenario = SelectableTextDemoScenario;
typedef _Defaults = SelectableTextDemoDefaults;
typedef _Story = SelectableTextDemoStory;
typedef _Args = _SelectableTextInputArgs;
final SelectableTextDemoComponent =
    Component<SelectableTextDemo, StoryArgs<SelectableTextDemo>>(
      name: component.name ?? 'SelectableTextDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment: r'''Demonstrates selectable text callbacks and cursor configuration.''',
      stories: [
        $DefaultSelectableText..$generatedName = 'DefaultSelectableText',
      ],
    );
typedef SelectableTextDemoScenario =
    Scenario<SelectableTextDemo, _SelectableTextInputArgs>;
typedef SelectableTextDemoDefaults =
    Defaults<SelectableTextDemo, _SelectableTextInputArgs>;

class SelectableTextDemoStory
    extends Story<SelectableTextDemo, _SelectableTextInputArgs> {
  SelectableTextDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _SelectableTextInputArgs? args,
    StoryWidgetBuilder<SelectableTextDemo, _SelectableTextInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _SelectableTextInputArgs(),
         builder: builder ?? selectableTextDefaults.builder!,
       );
}

class _SelectableTextInputArgs extends StoryArgs<SelectableTextDemo> {
  _SelectableTextInputArgs({
    Arg<String>? data,
    Arg<AuraTextStyle>? style,
    Arg<AuraTint?>? tint,
    Arg<TextAlign?>? textAlign,
    Arg<int?>? maxLines,
    Arg<double>? cursorWidth,
    Arg<double?>? cursorHeight,
    Arg<Radius?>? cursorRadius,
    Arg<AuraTint?>? cursorTint,
    Arg<bool>? showCursor,
    Arg<bool>? autofocus,
    Arg<int?>? minLines,
    Arg<bool>? enableTap,
    Arg<bool>? enableSelectionChanged,
  }) : this.dataArg = $initArg('data', data, StringArg(''))!,
       this.styleArg = $initArg(
         'style',
         style,
         EnumArg<AuraTextStyle>(
           AuraTextStyle.heading1,
           values: AuraTextStyle.values,
         ),
       )!,
       this.tintArg = $initArg(
         'tint',
         tint,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!,
       this.textAlignArg = $initArg(
         'textAlign',
         textAlign,
         NullableEnumArg<TextAlign>(null, values: TextAlign.values),
       )!,
       this.maxLinesArg = $initArg('maxLines', maxLines, NullableIntArg(null))!,
       this.cursorWidthArg = $initArg(
         'cursorWidth',
         cursorWidth,
         DoubleArg(0.0),
       )!,
       this.cursorHeightArg = $initArg(
         'cursorHeight',
         cursorHeight,
         NullableDoubleArg(null),
       )!,
       this.cursorRadiusArg = $initArg('cursorRadius', cursorRadius, null),
       this.cursorTintArg = $initArg(
         'cursorTint',
         cursorTint,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!,
       this.showCursorArg = $initArg('showCursor', showCursor, BoolArg(false))!,
       this.autofocusArg = $initArg('autofocus', autofocus, BoolArg(false))!,
       this.minLinesArg = $initArg('minLines', minLines, NullableIntArg(null))!,
       this.enableTapArg = $initArg('enableTap', enableTap, BoolArg(false))!,
       this.enableSelectionChangedArg = $initArg(
         'enableSelectionChanged',
         enableSelectionChanged,
         BoolArg(false),
       )!;

  _SelectableTextInputArgs.fixed({
    String data = '',
    AuraTextStyle style = AuraTextStyle.heading1,
    AuraTint? tint = null,
    TextAlign? textAlign = null,
    int? maxLines = null,
    double cursorWidth = 0.0,
    double? cursorHeight = null,
    Radius? cursorRadius,
    AuraTint? cursorTint = null,
    bool showCursor = false,
    bool autofocus = false,
    int? minLines = null,
    bool enableTap = false,
    bool enableSelectionChanged = false,
  }) : this.dataArg = $initArg('data', Arg.fixed(data), null)!,
       this.styleArg = $initArg('style', Arg.fixed(style), null)!,
       this.tintArg = $initArg(
         'tint',
         tint == null ? null : Arg.fixed(tint),
         null,
       ),
       this.textAlignArg = $initArg(
         'textAlign',
         textAlign == null ? null : Arg.fixed(textAlign),
         null,
       ),
       this.maxLinesArg = $initArg(
         'maxLines',
         maxLines == null ? null : Arg.fixed(maxLines),
         null,
       ),
       this.cursorWidthArg = $initArg(
         'cursorWidth',
         Arg.fixed(cursorWidth),
         null,
       )!,
       this.cursorHeightArg = $initArg(
         'cursorHeight',
         cursorHeight == null ? null : Arg.fixed(cursorHeight),
         null,
       ),
       this.cursorRadiusArg = $initArg(
         'cursorRadius',
         cursorRadius == null ? null : Arg.fixed(cursorRadius),
         null,
       ),
       this.cursorTintArg = $initArg(
         'cursorTint',
         cursorTint == null ? null : Arg.fixed(cursorTint),
         null,
       ),
       this.showCursorArg = $initArg(
         'showCursor',
         Arg.fixed(showCursor),
         null,
       )!,
       this.autofocusArg = $initArg('autofocus', Arg.fixed(autofocus), null)!,
       this.minLinesArg = $initArg(
         'minLines',
         minLines == null ? null : Arg.fixed(minLines),
         null,
       ),
       this.enableTapArg = $initArg('enableTap', Arg.fixed(enableTap), null)!,
       this.enableSelectionChangedArg = $initArg(
         'enableSelectionChanged',
         Arg.fixed(enableSelectionChanged),
         null,
       )!;

  final Arg<String> dataArg;

  final Arg<AuraTextStyle> styleArg;

  final Arg<AuraTint?>? tintArg;

  final Arg<TextAlign?>? textAlignArg;

  final Arg<int?>? maxLinesArg;

  final Arg<double> cursorWidthArg;

  final Arg<double?>? cursorHeightArg;

  final Arg<Radius?>? cursorRadiusArg;

  final Arg<AuraTint?>? cursorTintArg;

  final Arg<bool> showCursorArg;

  final Arg<bool> autofocusArg;

  final Arg<int?>? minLinesArg;

  final Arg<bool> enableTapArg;

  final Arg<bool> enableSelectionChangedArg;

  String get data => dataArg.value;

  AuraTextStyle get style => styleArg.value;

  AuraTint? get tint => tintArg?.value;

  TextAlign? get textAlign => textAlignArg?.value;

  int? get maxLines => maxLinesArg?.value;

  double get cursorWidth => cursorWidthArg.value;

  double? get cursorHeight => cursorHeightArg?.value;

  Radius? get cursorRadius => cursorRadiusArg?.value;

  AuraTint? get cursorTint => cursorTintArg?.value;

  bool get showCursor => showCursorArg.value;

  bool get autofocus => autofocusArg.value;

  int? get minLines => minLinesArg?.value;

  bool get enableTap => enableTapArg.value;

  bool get enableSelectionChanged => enableSelectionChangedArg.value;

  @override
  List<Arg?> get list => [
    dataArg,
    styleArg,
    tintArg,
    textAlignArg,
    maxLinesArg,
    cursorWidthArg,
    cursorHeightArg,
    cursorRadiusArg,
    cursorTintArg,
    showCursorArg,
    autofocusArg,
    minLinesArg,
    enableTapArg,
    enableSelectionChangedArg,
  ];
}
