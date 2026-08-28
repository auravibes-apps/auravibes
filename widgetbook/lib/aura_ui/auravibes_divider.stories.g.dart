// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_divider.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraDivider, StoryArgs<AuraDivider>>;
typedef _Scenario = AuraDividerScenario;
typedef _Defaults = AuraDividerDefaults;
typedef _Story = AuraDividerStory;
typedef _Args = AuraDividerArgs;
typedef _VerticalScenario = AuraDividerVerticalScenario;
typedef _VerticalDefaults = AuraDividerVerticalDefaults;
typedef _VerticalStory = AuraDividerVerticalStory;
typedef _VerticalArgs = AuraDividerVerticalArgs;
typedef _WithLabelScenario = AuraDividerWithLabelScenario;
typedef _WithLabelDefaults = AuraDividerWithLabelDefaults;
typedef _WithLabelStory = AuraDividerWithLabelStory;
typedef _WithLabelArgs = AuraDividerWithLabelArgs;
final AuraDividerComponent = Component<AuraDivider, StoryArgs<AuraDivider>>(
  name: 'AuraDivider',
  path: 'aura_ui',
  docComment:
      r'''A customizable divider component following the Aura design system.

This divider widget provides consistent visual separation between
content sections with support for labels and different orientations.''',
  stories: [
    $HorizontalDivider..$generatedName = 'HorizontalDivider',
    $VerticalDivider..$generatedName = 'VerticalDivider',
    $DividerWithLabel..$generatedName = 'DividerWithLabel',
  ],
);
typedef AuraDividerScenario = Scenario<AuraDivider, AuraDividerArgs>;
typedef AuraDividerDefaults = Defaults<AuraDivider, AuraDividerArgs>;

class AuraDividerStory extends Story<AuraDivider, AuraDividerArgs> {
  AuraDividerStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    AuraDividerArgs? args,
    StoryWidgetBuilder<AuraDivider, AuraDividerArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AuraDividerArgs(),
         builder:
             builder ??
             (context, args) => AuraDivider(
               key: args.key,
               thickness: args.thickness,
               color: args.color,
               indent: args.indent,
               endIndent: args.endIndent,
             ),
       );
}

class AuraDividerArgs extends StoryArgs<AuraDivider> {
  AuraDividerArgs({
    Arg<Key?>? key,
    Arg<double?>? thickness,
    Arg<AuraTint?>? color,
    Arg<double>? indent,
    Arg<double>? endIndent,
  }) : this.keyArg = $initArg('key', key, null),
       this.thicknessArg = $initArg(
         'thickness',
         thickness,
         NullableDoubleArg(null),
       )!,
       this.colorArg = $initArg(
         'color',
         color,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!,
       this.indentArg = $initArg('indent', indent, DoubleArg(0))!,
       this.endIndentArg = $initArg('endIndent', endIndent, DoubleArg(0))!;

  AuraDividerArgs.fixed({
    Key? key,
    double? thickness = null,
    AuraTint? color = null,
    double indent = 0,
    double endIndent = 0,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.thicknessArg = $initArg(
         'thickness',
         thickness == null ? null : Arg.fixed(thickness),
         null,
       ),
       this.colorArg = $initArg(
         'color',
         color == null ? null : Arg.fixed(color),
         null,
       ),
       this.indentArg = $initArg('indent', Arg.fixed(indent), null)!,
       this.endIndentArg = $initArg('endIndent', Arg.fixed(endIndent), null)!;

  final Arg<Key?>? keyArg;

  final Arg<double?>? thicknessArg;

  final Arg<AuraTint?>? colorArg;

  final Arg<double> indentArg;

  final Arg<double> endIndentArg;

  Key? get key => keyArg?.value;

  double? get thickness => thicknessArg?.value;

  AuraTint? get color => colorArg?.value;

  double get indent => indentArg.value;

  double get endIndent => endIndentArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    thicknessArg,
    colorArg,
    indentArg,
    endIndentArg,
  ];
}

typedef AuraDividerVerticalScenario =
    Scenario<AuraDivider, AuraDividerVerticalArgs>;
typedef AuraDividerVerticalDefaults =
    Defaults<AuraDivider, AuraDividerVerticalArgs>;

class AuraDividerVerticalStory
    extends Story<AuraDivider, AuraDividerVerticalArgs> {
  AuraDividerVerticalStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    AuraDividerVerticalArgs? args,
    StoryWidgetBuilder<AuraDivider, AuraDividerVerticalArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AuraDividerVerticalArgs(),
         builder:
             builder ??
             (context, args) => AuraDivider.vertical(
               key: args.key,
               thickness: args.thickness,
               color: args.color,
               indent: args.indent,
               endIndent: args.endIndent,
             ),
       );
}

class AuraDividerVerticalArgs extends StoryArgs<AuraDivider> {
  AuraDividerVerticalArgs({
    Arg<Key?>? key,
    Arg<double?>? thickness,
    Arg<AuraTint?>? color,
    Arg<double>? indent,
    Arg<double>? endIndent,
  }) : this.keyArg = $initArg('key', key, null),
       this.thicknessArg = $initArg(
         'thickness',
         thickness,
         NullableDoubleArg(null),
       )!,
       this.colorArg = $initArg(
         'color',
         color,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!,
       this.indentArg = $initArg('indent', indent, DoubleArg(0))!,
       this.endIndentArg = $initArg('endIndent', endIndent, DoubleArg(0))!;

  AuraDividerVerticalArgs.fixed({
    Key? key,
    double? thickness = null,
    AuraTint? color = null,
    double indent = 0,
    double endIndent = 0,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.thicknessArg = $initArg(
         'thickness',
         thickness == null ? null : Arg.fixed(thickness),
         null,
       ),
       this.colorArg = $initArg(
         'color',
         color == null ? null : Arg.fixed(color),
         null,
       ),
       this.indentArg = $initArg('indent', Arg.fixed(indent), null)!,
       this.endIndentArg = $initArg('endIndent', Arg.fixed(endIndent), null)!;

  final Arg<Key?>? keyArg;

  final Arg<double?>? thicknessArg;

  final Arg<AuraTint?>? colorArg;

  final Arg<double> indentArg;

  final Arg<double> endIndentArg;

  Key? get key => keyArg?.value;

  double? get thickness => thicknessArg?.value;

  AuraTint? get color => colorArg?.value;

  double get indent => indentArg.value;

  double get endIndent => endIndentArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    thicknessArg,
    colorArg,
    indentArg,
    endIndentArg,
  ];
}

typedef AuraDividerWithLabelScenario =
    Scenario<AuraDivider, AuraDividerWithLabelArgs>;
typedef AuraDividerWithLabelDefaults =
    Defaults<AuraDivider, AuraDividerWithLabelArgs>;

class AuraDividerWithLabelStory
    extends Story<AuraDivider, AuraDividerWithLabelArgs> {
  AuraDividerWithLabelStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    AuraDividerWithLabelArgs? args,
    StoryWidgetBuilder<AuraDivider, AuraDividerWithLabelArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AuraDividerWithLabelArgs(),
         builder:
             builder ??
             (context, args) => AuraDivider.withLabel(
               label: args.label,
               key: args.key,
               thickness: args.thickness,
               color: args.color,
               indent: args.indent,
               endIndent: args.endIndent,
             ),
       );
}

class AuraDividerWithLabelArgs extends StoryArgs<AuraDivider> {
  AuraDividerWithLabelArgs({
    Arg<Widget?>? label,
    Arg<Key?>? key,
    Arg<double?>? thickness,
    Arg<AuraTint?>? color,
    Arg<double>? indent,
    Arg<double>? endIndent,
  }) : this.labelArg = $initArg('label', label, null),
       this.keyArg = $initArg('key', key, null),
       this.thicknessArg = $initArg(
         'thickness',
         thickness,
         NullableDoubleArg(null),
       )!,
       this.colorArg = $initArg(
         'color',
         color,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!,
       this.indentArg = $initArg('indent', indent, DoubleArg(0))!,
       this.endIndentArg = $initArg('endIndent', endIndent, DoubleArg(0))!;

  AuraDividerWithLabelArgs.fixed({
    Widget? label,
    Key? key,
    double? thickness = null,
    AuraTint? color = null,
    double indent = 0,
    double endIndent = 0,
  }) : this.labelArg = $initArg(
         'label',
         label == null ? null : Arg.fixed(label),
         null,
       ),
       this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.thicknessArg = $initArg(
         'thickness',
         thickness == null ? null : Arg.fixed(thickness),
         null,
       ),
       this.colorArg = $initArg(
         'color',
         color == null ? null : Arg.fixed(color),
         null,
       ),
       this.indentArg = $initArg('indent', Arg.fixed(indent), null)!,
       this.endIndentArg = $initArg('endIndent', Arg.fixed(endIndent), null)!;

  final Arg<Widget?>? labelArg;

  final Arg<Key?>? keyArg;

  final Arg<double?>? thicknessArg;

  final Arg<AuraTint?>? colorArg;

  final Arg<double> indentArg;

  final Arg<double> endIndentArg;

  Widget? get label => labelArg?.value;

  Key? get key => keyArg?.value;

  double? get thickness => thicknessArg?.value;

  AuraTint? get color => colorArg?.value;

  double get indent => indentArg.value;

  double get endIndent => endIndentArg.value;

  @override
  List<Arg?> get list => [
    labelArg,
    keyArg,
    thicknessArg,
    colorArg,
    indentArg,
    endIndentArg,
  ];
}
