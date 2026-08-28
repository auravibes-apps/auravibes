// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_badge.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraBadge, StoryArgs<AuraBadge>>;
typedef _TextScenario = AuraBadgeTextScenario;
typedef _TextDefaults = AuraBadgeTextDefaults;
typedef _TextStory = AuraBadgeTextStory;
typedef _TextArgs = _TextBadgeInputArgs;
typedef _CountScenario = AuraBadgeCountScenario;
typedef _CountDefaults = AuraBadgeCountDefaults;
typedef _CountStory = AuraBadgeCountStory;
typedef _CountArgs = AuraBadgeCountArgs;
typedef _DotScenario = AuraBadgeDotScenario;
typedef _DotDefaults = AuraBadgeDotDefaults;
typedef _DotStory = AuraBadgeDotStory;
typedef _DotArgs = AuraBadgeDotArgs;
typedef _Scenario = AuraBadgeScenario;
typedef _Defaults = AuraBadgeDefaults;
typedef _Story = AuraBadgeStory;
typedef _Args = AuraBadgeArgs;
final AuraBadgeComponent = Component<AuraBadge, StoryArgs<AuraBadge>>(
  name: 'AuraBadge',
  path: 'aura_ui',
  docComment:
      r'''A customizable badge component following the Aura design system.

This badge widget provides consistent styling for status indicators,
labels, and notification counts across the application.''',
  stories: [
    $TextBadge..$generatedName = 'TextBadge',
    $CountBadge..$generatedName = 'CountBadge',
    $DotBadge..$generatedName = 'DotBadge',
    $CustomContentBadge..$generatedName = 'CustomContentBadge',
  ],
);
typedef AuraBadgeTextScenario = Scenario<AuraBadge, _TextBadgeInputArgs>;
typedef AuraBadgeTextDefaults = Defaults<AuraBadge, _TextBadgeInputArgs>;

class AuraBadgeTextStory extends Story<AuraBadge, _TextBadgeInputArgs> {
  AuraBadgeTextStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _TextBadgeInputArgs? args,
    StoryWidgetBuilder<AuraBadge, _TextBadgeInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _TextBadgeInputArgs(),
         builder: builder ?? textDefaults.builder!,
       );
}

class _TextBadgeInputArgs extends StoryArgs<AuraBadge> {
  _TextBadgeInputArgs({
    Arg<String>? text,
    Arg<AuraBadgeVariant>? variant,
    Arg<AuraBadgeSize>? size,
  }) : this.textArg = $initArg('text', text, StringArg(''))!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<AuraBadgeVariant>(
           AuraBadgeVariant.primary,
           values: AuraBadgeVariant.values,
         ),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<AuraBadgeSize>(
           AuraBadgeSize.small,
           values: AuraBadgeSize.values,
         ),
       )!;

  _TextBadgeInputArgs.fixed({
    String text = '',
    AuraBadgeVariant variant = AuraBadgeVariant.primary,
    AuraBadgeSize size = AuraBadgeSize.small,
  }) : this.textArg = $initArg('text', Arg.fixed(text), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!;

  final Arg<String> textArg;

  final Arg<AuraBadgeVariant> variantArg;

  final Arg<AuraBadgeSize> sizeArg;

  String get text => textArg.value;

  AuraBadgeVariant get variant => variantArg.value;

  AuraBadgeSize get size => sizeArg.value;

  @override
  List<Arg?> get list => [textArg, variantArg, sizeArg];
}

typedef AuraBadgeCountScenario = Scenario<AuraBadge, AuraBadgeCountArgs>;
typedef AuraBadgeCountDefaults = Defaults<AuraBadge, AuraBadgeCountArgs>;

class AuraBadgeCountStory extends Story<AuraBadge, AuraBadgeCountArgs> {
  AuraBadgeCountStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    AuraBadgeCountArgs? args,
    StoryWidgetBuilder<AuraBadge, AuraBadgeCountArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AuraBadgeCountArgs(),
         builder:
             builder ??
             (context, args) => AuraBadge.count(
               count: args.count,
               key: args.key,
               variant: args.variant,
               size: args.size,
               semanticLabel: args.semanticLabel,
               maxCount: args.maxCount,
             ),
       );
}

class AuraBadgeCountArgs extends StoryArgs<AuraBadge> {
  AuraBadgeCountArgs({
    Arg<int>? count,
    Arg<Key?>? key,
    Arg<AuraBadgeVariant>? variant,
    Arg<AuraBadgeSize>? size,
    Arg<String?>? semanticLabel,
    Arg<int>? maxCount,
  }) : this.countArg = $initArg('count', count, IntArg(0))!,
       this.keyArg = $initArg('key', key, null),
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<AuraBadgeVariant>(
           AuraBadgeVariant.primary,
           values: AuraBadgeVariant.values,
         ),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<AuraBadgeSize>(
           AuraBadgeSize.medium,
           values: AuraBadgeSize.values,
         ),
       )!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         NullableStringArg(null),
       )!,
       this.maxCountArg = $initArg('maxCount', maxCount, IntArg(99))!;

  AuraBadgeCountArgs.fixed({
    int count = 0,
    Key? key,
    AuraBadgeVariant variant = AuraBadgeVariant.primary,
    AuraBadgeSize size = AuraBadgeSize.medium,
    String? semanticLabel = null,
    int maxCount = 99,
  }) : this.countArg = $initArg('count', Arg.fixed(count), null)!,
       this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel == null ? null : Arg.fixed(semanticLabel),
         null,
       ),
       this.maxCountArg = $initArg('maxCount', Arg.fixed(maxCount), null)!;

  final Arg<int> countArg;

  final Arg<Key?>? keyArg;

  final Arg<AuraBadgeVariant> variantArg;

  final Arg<AuraBadgeSize> sizeArg;

  final Arg<String?>? semanticLabelArg;

  final Arg<int> maxCountArg;

  int get count => countArg.value;

  Key? get key => keyArg?.value;

  AuraBadgeVariant get variant => variantArg.value;

  AuraBadgeSize get size => sizeArg.value;

  String? get semanticLabel => semanticLabelArg?.value;

  int get maxCount => maxCountArg.value;

  @override
  List<Arg?> get list => [
    countArg,
    keyArg,
    variantArg,
    sizeArg,
    semanticLabelArg,
    maxCountArg,
  ];
}

typedef AuraBadgeDotScenario = Scenario<AuraBadge, AuraBadgeDotArgs>;
typedef AuraBadgeDotDefaults = Defaults<AuraBadge, AuraBadgeDotArgs>;

class AuraBadgeDotStory extends Story<AuraBadge, AuraBadgeDotArgs> {
  AuraBadgeDotStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    AuraBadgeDotArgs? args,
    StoryWidgetBuilder<AuraBadge, AuraBadgeDotArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AuraBadgeDotArgs(),
         builder:
             builder ??
             (context, args) => AuraBadge.dot(
               key: args.key,
               variant: args.variant,
               semanticLabel: args.semanticLabel,
             ),
       );
}

class AuraBadgeDotArgs extends StoryArgs<AuraBadge> {
  AuraBadgeDotArgs({
    Arg<Key?>? key,
    Arg<AuraBadgeVariant>? variant,
    Arg<String?>? semanticLabel,
  }) : this.keyArg = $initArg('key', key, null),
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<AuraBadgeVariant>(
           AuraBadgeVariant.primary,
           values: AuraBadgeVariant.values,
         ),
       )!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         NullableStringArg(null),
       )!;

  AuraBadgeDotArgs.fixed({
    Key? key,
    AuraBadgeVariant variant = AuraBadgeVariant.primary,
    String? semanticLabel = null,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel == null ? null : Arg.fixed(semanticLabel),
         null,
       );

  final Arg<Key?>? keyArg;

  final Arg<AuraBadgeVariant> variantArg;

  final Arg<String?>? semanticLabelArg;

  Key? get key => keyArg?.value;

  AuraBadgeVariant get variant => variantArg.value;

  String? get semanticLabel => semanticLabelArg?.value;

  @override
  List<Arg?> get list => [keyArg, variantArg, semanticLabelArg];
}

typedef AuraBadgeScenario = Scenario<AuraBadge, AuraBadgeArgs>;
typedef AuraBadgeDefaults = Defaults<AuraBadge, AuraBadgeArgs>;

class AuraBadgeStory extends Story<AuraBadge, AuraBadgeArgs> {
  AuraBadgeStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<AuraBadge, AuraBadgeArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         builder:
             builder ??
             (context, args) => AuraBadge(
               child: args.child,
               key: args.key,
               variant: args.variant,
               size: args.size,
               semanticLabel: args.semanticLabel,
             ),
       );
}

class AuraBadgeArgs extends StoryArgs<AuraBadge> {
  AuraBadgeArgs({
    required Arg<Widget> child,
    Arg<Key?>? key,
    Arg<AuraBadgeVariant>? variant,
    Arg<AuraBadgeSize>? size,
    Arg<String?>? semanticLabel,
  }) : this.childArg = $initArg('child', child, null)!,
       this.keyArg = $initArg('key', key, null),
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<AuraBadgeVariant>(
           AuraBadgeVariant.primary,
           values: AuraBadgeVariant.values,
         ),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<AuraBadgeSize>(
           AuraBadgeSize.medium,
           values: AuraBadgeSize.values,
         ),
       )!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         NullableStringArg(null),
       )!;

  AuraBadgeArgs.fixed({
    required Widget child,
    Key? key,
    AuraBadgeVariant variant = AuraBadgeVariant.primary,
    AuraBadgeSize size = AuraBadgeSize.medium,
    String? semanticLabel = null,
  }) : this.childArg = $initArg('child', Arg.fixed(child), null)!,
       this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel == null ? null : Arg.fixed(semanticLabel),
         null,
       );

  final Arg<Widget> childArg;

  final Arg<Key?>? keyArg;

  final Arg<AuraBadgeVariant> variantArg;

  final Arg<AuraBadgeSize> sizeArg;

  final Arg<String?>? semanticLabelArg;

  Widget get child => childArg.value;

  Key? get key => keyArg?.value;

  AuraBadgeVariant get variant => variantArg.value;

  AuraBadgeSize get size => sizeArg.value;

  String? get semanticLabel => semanticLabelArg?.value;

  @override
  List<Arg?> get list => [
    childArg,
    keyArg,
    variantArg,
    sizeArg,
    semanticLabelArg,
  ];
}
