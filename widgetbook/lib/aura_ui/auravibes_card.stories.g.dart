// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_card.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<CardDemo, StoryArgs<CardDemo>>;
typedef _Scenario = CardDemoScenario;
typedef _Defaults = CardDemoDefaults;
typedef _Story = CardDemoStory;
typedef _Args = _CardInputArgs;
final CardDemoComponent = Component<CardDemo, StoryArgs<CardDemo>>(
  name: component.name ?? 'CardDemo',
  path: component.path ?? 'aura_ui',
  docsBuilder: component.docsBuilder,
  docComment:
      r'''Demonstrates editable card content and the optional tap callback.''',
  stories: [$BasicCard..$generatedName = 'BasicCard'],
);
typedef CardDemoScenario = Scenario<CardDemo, _CardInputArgs>;
typedef CardDemoDefaults = Defaults<CardDemo, _CardInputArgs>;

class CardDemoStory extends Story<CardDemo, _CardInputArgs> {
  CardDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<CardDemo, _CardInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(builder: builder ?? cardDefaults.builder!);
}

class _CardInputArgs extends StoryArgs<CardDemo> {
  _CardInputArgs({
    Arg<String>? title,
    Arg<String>? description,
    required Arg<AuraEdgeInsetsGeometry> padding,
    Arg<bool>? enableTap,
    Arg<String?>? semanticLabel,
    Arg<AuraCardStyle>? style,
  }) : this.titleArg = $initArg('title', title, StringArg(''))!,
       this.descriptionArg = $initArg(
         'description',
         description,
         StringArg(''),
       )!,
       this.paddingArg = $initArg('padding', padding, null)!,
       this.enableTapArg = $initArg('enableTap', enableTap, BoolArg(false))!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         NullableStringArg(null),
       )!,
       this.styleArg = $initArg(
         'style',
         style,
         EnumArg<AuraCardStyle>(
           AuraCardStyle.border,
           values: AuraCardStyle.values,
         ),
       )!;

  _CardInputArgs.fixed({
    String title = '',
    String description = '',
    required AuraEdgeInsetsGeometry padding,
    bool enableTap = false,
    String? semanticLabel = null,
    AuraCardStyle style = AuraCardStyle.border,
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!,
       this.paddingArg = $initArg('padding', Arg.fixed(padding), null)!,
       this.enableTapArg = $initArg('enableTap', Arg.fixed(enableTap), null)!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel == null ? null : Arg.fixed(semanticLabel),
         null,
       ),
       this.styleArg = $initArg('style', Arg.fixed(style), null)!;

  final Arg<String> titleArg;

  final Arg<String> descriptionArg;

  final Arg<AuraEdgeInsetsGeometry> paddingArg;

  final Arg<bool> enableTapArg;

  final Arg<String?>? semanticLabelArg;

  final Arg<AuraCardStyle> styleArg;

  String get title => titleArg.value;

  String get description => descriptionArg.value;

  AuraEdgeInsetsGeometry get padding => paddingArg.value;

  bool get enableTap => enableTapArg.value;

  String? get semanticLabel => semanticLabelArg?.value;

  AuraCardStyle get style => styleArg.value;

  @override
  List<Arg?> get list => [
    titleArg,
    descriptionArg,
    paddingArg,
    enableTapArg,
    semanticLabelArg,
    styleArg,
  ];
}
