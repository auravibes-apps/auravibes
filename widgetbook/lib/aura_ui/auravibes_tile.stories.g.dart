// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_tile.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraTile, StoryArgs<AuraTile>>;
typedef _Scenario = AuraTileScenario;
typedef _Defaults = AuraTileDefaults;
typedef _Story = AuraTileStory;
typedef _Args = _TileInputArgs;
final AuraTileComponent = Component<AuraTile, StoryArgs<AuraTile>>(
  name: 'AuraTile',
  path: 'aura_ui',
  docComment:
      r'''A customizable tile component following the Aura design system.

Tiles are horizontally expanded interactive elements similar to buttons
but designed for broader content areas and different interaction patterns.
They support multiple variants, sizes, and states while maintaining
consistency with the design tokens.''',
  stories: [$AuraTile..$generatedName = 'AuraTile'],
);
typedef AuraTileScenario = Scenario<AuraTile, _TileInputArgs>;
typedef AuraTileDefaults = Defaults<AuraTile, _TileInputArgs>;

class AuraTileStory extends Story<AuraTile, _TileInputArgs> {
  AuraTileStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _TileInputArgs? args,
    StoryWidgetBuilder<AuraTile, _TileInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _TileInputArgs(),
         builder: builder ?? tileDefaults.builder!,
       );
}

class _TileInputArgs extends StoryArgs<AuraTile> {
  _TileInputArgs({
    Arg<String>? childText,
    Arg<AuraTileVariant>? variant,
    Arg<AuraTileSize>? size,
    Arg<bool>? isLoading,
    Arg<bool>? showLeadingIcon,
    Arg<bool>? showTrailingIcon,
    Arg<bool>? enabled,
  }) : this.childTextArg = $initArg('childText', childText, StringArg(''))!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<AuraTileVariant>(
           AuraTileVariant.primary,
           values: AuraTileVariant.values,
         ),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<AuraTileSize>(AuraTileSize.small, values: AuraTileSize.values),
       )!,
       this.isLoadingArg = $initArg('isLoading', isLoading, BoolArg(false))!,
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         showLeadingIcon,
         BoolArg(false),
       )!,
       this.showTrailingIconArg = $initArg(
         'showTrailingIcon',
         showTrailingIcon,
         BoolArg(false),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(false))!;

  _TileInputArgs.fixed({
    String childText = '',
    AuraTileVariant variant = AuraTileVariant.primary,
    AuraTileSize size = AuraTileSize.small,
    bool isLoading = false,
    bool showLeadingIcon = false,
    bool showTrailingIcon = false,
    bool enabled = false,
  }) : this.childTextArg = $initArg('childText', Arg.fixed(childText), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.isLoadingArg = $initArg('isLoading', Arg.fixed(isLoading), null)!,
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         Arg.fixed(showLeadingIcon),
         null,
       )!,
       this.showTrailingIconArg = $initArg(
         'showTrailingIcon',
         Arg.fixed(showTrailingIcon),
         null,
       )!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<String> childTextArg;

  final Arg<AuraTileVariant> variantArg;

  final Arg<AuraTileSize> sizeArg;

  final Arg<bool> isLoadingArg;

  final Arg<bool> showLeadingIconArg;

  final Arg<bool> showTrailingIconArg;

  final Arg<bool> enabledArg;

  String get childText => childTextArg.value;

  AuraTileVariant get variant => variantArg.value;

  AuraTileSize get size => sizeArg.value;

  bool get isLoading => isLoadingArg.value;

  bool get showLeadingIcon => showLeadingIconArg.value;

  bool get showTrailingIcon => showTrailingIconArg.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [
    childTextArg,
    variantArg,
    sizeArg,
    isLoadingArg,
    showLeadingIconArg,
    showTrailingIconArg,
    enabledArg,
  ];
}
