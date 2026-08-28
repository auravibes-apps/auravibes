// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_floating_action_button.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<AuraFloatingActionButton, StoryArgs<AuraFloatingActionButton>>;
typedef _Scenario = AuraFloatingActionButtonScenario;
typedef _Defaults = AuraFloatingActionButtonDefaults;
typedef _Story = AuraFloatingActionButtonStory;
typedef _Args = AuraFloatingActionButtonArgs;
typedef _ExtendedScenario = AuraFloatingActionButtonExtendedScenario;
typedef _ExtendedDefaults = AuraFloatingActionButtonExtendedDefaults;
typedef _ExtendedStory = AuraFloatingActionButtonExtendedStory;
typedef _ExtendedArgs = AuraFloatingActionButtonExtendedArgs;
final AuraFloatingActionButtonComponent =
    Component<AuraFloatingActionButton, StoryArgs<AuraFloatingActionButton>>(
      name: 'AuraFloatingActionButton',
      path: 'aura_ui',
      docComment:
          r'''A customizable floating action button component following the Aura design
system.

This FAB supports different sizes, icons, extended variants with text,
and proper elevation and shadows.''',
      stories: [
        $RegularFAB..$generatedName = 'RegularFAB',
        $ExtendedFAB..$generatedName = 'ExtendedFAB',
      ],
    );
typedef AuraFloatingActionButtonScenario =
    Scenario<AuraFloatingActionButton, AuraFloatingActionButtonArgs>;
typedef AuraFloatingActionButtonDefaults =
    Defaults<AuraFloatingActionButton, AuraFloatingActionButtonArgs>;

class AuraFloatingActionButtonStory
    extends Story<AuraFloatingActionButton, AuraFloatingActionButtonArgs> {
  AuraFloatingActionButtonStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<AuraFloatingActionButton, AuraFloatingActionButtonArgs>?
    builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         builder:
             builder ??
             (context, args) => AuraFloatingActionButton(
               onPressed: args.onPressed,
               icon: args.icon,
               key: args.key,
               size: args.size,
               tint: args.tint,
               heroTag: args.heroTag,
               semanticLabel: args.semanticLabel,
               tooltip: args.tooltip,
             ),
       );
}

class AuraFloatingActionButtonArgs extends StoryArgs<AuraFloatingActionButton> {
  AuraFloatingActionButtonArgs({
    Arg<void Function()?>? onPressed,
    required Arg<IconData> icon,
    Arg<Key?>? key,
    Arg<AuraFABSize>? size,
    Arg<AuraTint?>? tint,
    Arg<LocalKey?>? heroTag,
    Arg<String?>? semanticLabel,
    Arg<String?>? tooltip,
  }) : this.onPressedArg = $initArg('onPressed', onPressed, null),
       this.iconArg = $initArg('icon', icon, null)!,
       this.keyArg = $initArg('key', key, null),
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<AuraFABSize>(AuraFABSize.regular, values: AuraFABSize.values),
       )!,
       this.tintArg = $initArg(
         'tint',
         tint,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!,
       this.heroTagArg = $initArg(
         'heroTag',
         heroTag,
         ConstArg(const ValueKey<String>('aura_floating_action_button')),
       )!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         NullableStringArg(null),
       )!,
       this.tooltipArg = $initArg('tooltip', tooltip, NullableStringArg(null))!;

  AuraFloatingActionButtonArgs.fixed({
    void Function()? onPressed,
    required IconData icon,
    Key? key,
    AuraFABSize size = AuraFABSize.regular,
    AuraTint? tint = null,
    LocalKey? heroTag = const ValueKey<String>('aura_floating_action_button'),
    String? semanticLabel = null,
    String? tooltip = null,
  }) : this.onPressedArg = $initArg(
         'onPressed',
         onPressed == null ? null : Arg.fixed(onPressed),
         null,
       ),
       this.iconArg = $initArg('icon', Arg.fixed(icon), null)!,
       this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.tintArg = $initArg(
         'tint',
         tint == null ? null : Arg.fixed(tint),
         null,
       ),
       this.heroTagArg = $initArg(
         'heroTag',
         heroTag == null ? null : Arg.fixed(heroTag),
         null,
       ),
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel == null ? null : Arg.fixed(semanticLabel),
         null,
       ),
       this.tooltipArg = $initArg(
         'tooltip',
         tooltip == null ? null : Arg.fixed(tooltip),
         null,
       );

  final Arg<void Function()?>? onPressedArg;

  final Arg<IconData> iconArg;

  final Arg<Key?>? keyArg;

  final Arg<AuraFABSize> sizeArg;

  final Arg<AuraTint?>? tintArg;

  final Arg<LocalKey?>? heroTagArg;

  final Arg<String?>? semanticLabelArg;

  final Arg<String?>? tooltipArg;

  void Function()? get onPressed => onPressedArg?.value;

  IconData get icon => iconArg.value;

  Key? get key => keyArg?.value;

  AuraFABSize get size => sizeArg.value;

  AuraTint? get tint => tintArg?.value;

  LocalKey? get heroTag => heroTagArg?.value;

  String? get semanticLabel => semanticLabelArg?.value;

  String? get tooltip => tooltipArg?.value;

  @override
  List<Arg?> get list => [
    onPressedArg,
    iconArg,
    keyArg,
    sizeArg,
    tintArg,
    heroTagArg,
    semanticLabelArg,
    tooltipArg,
  ];
}

typedef AuraFloatingActionButtonExtendedScenario =
    Scenario<AuraFloatingActionButton, AuraFloatingActionButtonExtendedArgs>;
typedef AuraFloatingActionButtonExtendedDefaults =
    Defaults<AuraFloatingActionButton, AuraFloatingActionButtonExtendedArgs>;

class AuraFloatingActionButtonExtendedStory
    extends
        Story<AuraFloatingActionButton, AuraFloatingActionButtonExtendedArgs> {
  AuraFloatingActionButtonExtendedStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<
      AuraFloatingActionButton,
      AuraFloatingActionButtonExtendedArgs
    >?
    builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         builder:
             builder ??
             (context, args) => AuraFloatingActionButton.extended(
               onPressed: args.onPressed,
               icon: args.icon,
               text: args.text,
               key: args.key,
               tint: args.tint,
               heroTag: args.heroTag,
               semanticLabel: args.semanticLabel,
               tooltip: args.tooltip,
             ),
       );
}

class AuraFloatingActionButtonExtendedArgs
    extends StoryArgs<AuraFloatingActionButton> {
  AuraFloatingActionButtonExtendedArgs({
    Arg<void Function()?>? onPressed,
    required Arg<IconData> icon,
    Arg<String?>? text,
    Arg<Key?>? key,
    Arg<AuraTint?>? tint,
    Arg<LocalKey?>? heroTag,
    Arg<String?>? semanticLabel,
    Arg<String?>? tooltip,
  }) : this.onPressedArg = $initArg('onPressed', onPressed, null),
       this.iconArg = $initArg('icon', icon, null)!,
       this.textArg = $initArg('text', text, NullableStringArg(null))!,
       this.keyArg = $initArg('key', key, null),
       this.tintArg = $initArg(
         'tint',
         tint,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!,
       this.heroTagArg = $initArg(
         'heroTag',
         heroTag,
         ConstArg(const ValueKey<String>('aura_floating_action_button')),
       )!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         NullableStringArg(null),
       )!,
       this.tooltipArg = $initArg('tooltip', tooltip, NullableStringArg(null))!;

  AuraFloatingActionButtonExtendedArgs.fixed({
    void Function()? onPressed,
    required IconData icon,
    String? text = null,
    Key? key,
    AuraTint? tint = null,
    LocalKey? heroTag = const ValueKey<String>('aura_floating_action_button'),
    String? semanticLabel = null,
    String? tooltip = null,
  }) : this.onPressedArg = $initArg(
         'onPressed',
         onPressed == null ? null : Arg.fixed(onPressed),
         null,
       ),
       this.iconArg = $initArg('icon', Arg.fixed(icon), null)!,
       this.textArg = $initArg(
         'text',
         text == null ? null : Arg.fixed(text),
         null,
       ),
       this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.tintArg = $initArg(
         'tint',
         tint == null ? null : Arg.fixed(tint),
         null,
       ),
       this.heroTagArg = $initArg(
         'heroTag',
         heroTag == null ? null : Arg.fixed(heroTag),
         null,
       ),
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel == null ? null : Arg.fixed(semanticLabel),
         null,
       ),
       this.tooltipArg = $initArg(
         'tooltip',
         tooltip == null ? null : Arg.fixed(tooltip),
         null,
       );

  final Arg<void Function()?>? onPressedArg;

  final Arg<IconData> iconArg;

  final Arg<String?>? textArg;

  final Arg<Key?>? keyArg;

  final Arg<AuraTint?>? tintArg;

  final Arg<LocalKey?>? heroTagArg;

  final Arg<String?>? semanticLabelArg;

  final Arg<String?>? tooltipArg;

  void Function()? get onPressed => onPressedArg?.value;

  IconData get icon => iconArg.value;

  String? get text => textArg?.value;

  Key? get key => keyArg?.value;

  AuraTint? get tint => tintArg?.value;

  LocalKey? get heroTag => heroTagArg?.value;

  String? get semanticLabel => semanticLabelArg?.value;

  String? get tooltip => tooltipArg?.value;

  @override
  List<Arg?> get list => [
    onPressedArg,
    iconArg,
    textArg,
    keyArg,
    tintArg,
    heroTagArg,
    semanticLabelArg,
    tooltipArg,
  ];
}
