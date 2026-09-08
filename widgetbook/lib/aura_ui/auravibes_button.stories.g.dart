// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_button.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraButton, StoryArgs<AuraButton>>;
typedef _Scenario = AuraButtonScenario;
typedef _Defaults = AuraButtonDefaults;
typedef _Story = AuraButtonStory;
typedef _Args = _ButtonInputArgs;
final AuraButtonComponent = Component<AuraButton, StoryArgs<AuraButton>>(
  name: 'AuraButton',
  path: 'aura_ui',
  docComment:
      r'''A customizable button component following the Aura design system.

This button supports multiple variants, sizes, and states while maintaining
consistency with the design tokens.''',
  stories: [$PrimaryButton..$generatedName = 'PrimaryButton'],
);
typedef AuraButtonScenario = Scenario<AuraButton, _ButtonInputArgs>;
typedef AuraButtonDefaults = Defaults<AuraButton, _ButtonInputArgs>;

class AuraButtonStory extends Story<AuraButton, _ButtonInputArgs> {
  AuraButtonStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _ButtonInputArgs? args,
    StoryWidgetBuilder<AuraButton, _ButtonInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _ButtonInputArgs(),
         builder: builder ?? buttonDefaults.builder!,
       );
}

class _ButtonInputArgs extends StoryArgs<AuraButton> {
  _ButtonInputArgs({
    Arg<String>? buttonContent,
    Arg<AuraButtonVariant>? variant,
    Arg<AuraButtonSize>? size,
    Arg<bool>? isLoading,
    Arg<bool>? isFullWidth,
    Arg<bool>? disabled,
    Arg<String>? semanticLabel,
  }) : this.buttonContentArg = $initArg(
         'buttonContent',
         buttonContent,
         StringArg(''),
       )!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<AuraButtonVariant>(
           AuraButtonVariant.primary,
           values: AuraButtonVariant.values,
         ),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<AuraButtonSize>(
           AuraButtonSize.small,
           values: AuraButtonSize.values,
         ),
       )!,
       this.isLoadingArg = $initArg('isLoading', isLoading, BoolArg(false))!,
       this.isFullWidthArg = $initArg(
         'isFullWidth',
         isFullWidth,
         BoolArg(false),
       )!,
       this.disabledArg = $initArg('disabled', disabled, BoolArg(false))!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         StringArg(''),
       )!;

  _ButtonInputArgs.fixed({
    String buttonContent = '',
    AuraButtonVariant variant = AuraButtonVariant.primary,
    AuraButtonSize size = AuraButtonSize.small,
    bool isLoading = false,
    bool isFullWidth = false,
    bool disabled = false,
    String semanticLabel = '',
  }) : this.buttonContentArg = $initArg(
         'buttonContent',
         Arg.fixed(buttonContent),
         null,
       )!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.isLoadingArg = $initArg('isLoading', Arg.fixed(isLoading), null)!,
       this.isFullWidthArg = $initArg(
         'isFullWidth',
         Arg.fixed(isFullWidth),
         null,
       )!,
       this.disabledArg = $initArg('disabled', Arg.fixed(disabled), null)!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         Arg.fixed(semanticLabel),
         null,
       )!;

  final Arg<String> buttonContentArg;

  final Arg<AuraButtonVariant> variantArg;

  final Arg<AuraButtonSize> sizeArg;

  final Arg<bool> isLoadingArg;

  final Arg<bool> isFullWidthArg;

  final Arg<bool> disabledArg;

  final Arg<String> semanticLabelArg;

  String get buttonContent => buttonContentArg.value;

  AuraButtonVariant get variant => variantArg.value;

  AuraButtonSize get size => sizeArg.value;

  bool get isLoading => isLoadingArg.value;

  bool get isFullWidth => isFullWidthArg.value;

  bool get disabled => disabledArg.value;

  String get semanticLabel => semanticLabelArg.value;

  @override
  List<Arg?> get list => [
    buttonContentArg,
    variantArg,
    sizeArg,
    isLoadingArg,
    isFullWidthArg,
    disabledArg,
    semanticLabelArg,
  ];
}
