// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_icon_button.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraIconButton, StoryArgs<AuraIconButton>>;
typedef _Scenario = AuraIconButtonScenario;
typedef _Defaults = AuraIconButtonDefaults;
typedef _Story = AuraIconButtonStory;
typedef _Args = _IconButtonInputArgs;
final AuraIconButtonComponent =
    Component<AuraIconButton, StoryArgs<AuraIconButton>>(
      name: component.name ?? 'AuraIconButton',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment: r'''A specialized icon button component following the Aura design system.''',
      stories: [$IconButtonBasic..$generatedName = 'IconButtonBasic'],
    );
typedef AuraIconButtonScenario = Scenario<AuraIconButton, _IconButtonInputArgs>;
typedef AuraIconButtonDefaults = Defaults<AuraIconButton, _IconButtonInputArgs>;

class AuraIconButtonStory extends Story<AuraIconButton, _IconButtonInputArgs> {
  AuraIconButtonStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<AuraIconButton, _IconButtonInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(builder: builder ?? iconButtonDefaults.builder!);
}

class _IconButtonInputArgs extends StoryArgs<AuraIconButton> {
  _IconButtonInputArgs({
    required Arg<IconData> icon,
    Arg<bool>? disabled,
    Arg<AuraIconSize>? size,
    Arg<AuraIconButtonVariant>? variant,
    Arg<String>? tooltip,
  }) : this.iconArg = $initArg('icon', icon, null)!,
       this.disabledArg = $initArg('disabled', disabled, BoolArg(false))!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<AuraIconSize>(
           AuraIconSize.extraSmall,
           values: AuraIconSize.values,
         ),
       )!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<AuraIconButtonVariant>(
           AuraIconButtonVariant.ghost,
           values: AuraIconButtonVariant.values,
         ),
       )!,
       this.tooltipArg = $initArg('tooltip', tooltip, StringArg(''))!;

  _IconButtonInputArgs.fixed({
    required IconData icon,
    bool disabled = false,
    AuraIconSize size = AuraIconSize.extraSmall,
    AuraIconButtonVariant variant = AuraIconButtonVariant.ghost,
    String tooltip = '',
  }) : this.iconArg = $initArg('icon', Arg.fixed(icon), null)!,
       this.disabledArg = $initArg('disabled', Arg.fixed(disabled), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.tooltipArg = $initArg('tooltip', Arg.fixed(tooltip), null)!;

  final Arg<IconData> iconArg;

  final Arg<bool> disabledArg;

  final Arg<AuraIconSize> sizeArg;

  final Arg<AuraIconButtonVariant> variantArg;

  final Arg<String> tooltipArg;

  IconData get icon => iconArg.value;

  bool get disabled => disabledArg.value;

  AuraIconSize get size => sizeArg.value;

  AuraIconButtonVariant get variant => variantArg.value;

  String get tooltip => tooltipArg.value;

  @override
  List<Arg?> get list => [
    iconArg,
    disabledArg,
    sizeArg,
    variantArg,
    tooltipArg,
  ];
}
