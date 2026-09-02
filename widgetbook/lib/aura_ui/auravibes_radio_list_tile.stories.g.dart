// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_radio_list_tile.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<RadioListTileDemo, StoryArgs<RadioListTileDemo>>;
typedef _Scenario = RadioListTileDemoScenario;
typedef _Defaults = RadioListTileDemoDefaults;
typedef _Story = RadioListTileDemoStory;
typedef _Args = RadioListTileDemoArgs;
final RadioListTileDemoComponent =
    Component<RadioListTileDemo, StoryArgs<RadioListTileDemo>>(
      name: component.name ?? 'RadioListTileDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment: r'''Demonstrates settings-style radio list tiles with optional subtitles.''',
      stories: [$RadioListTile..$generatedName = 'RadioListTile'],
    );
typedef RadioListTileDemoScenario =
    Scenario<RadioListTileDemo, RadioListTileDemoArgs>;
typedef RadioListTileDemoDefaults =
    Defaults<RadioListTileDemo, RadioListTileDemoArgs>;

class RadioListTileDemoStory
    extends Story<RadioListTileDemo, RadioListTileDemoArgs> {
  RadioListTileDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    RadioListTileDemoArgs? args,
    StoryWidgetBuilder<RadioListTileDemo, RadioListTileDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? RadioListTileDemoArgs(),
         builder:
             builder ??
             (context, args) => RadioListTileDemo(
               key: args.key,
               tint: args.tint,
               disabled: args.disabled,
               showSubtitle: args.showSubtitle,
             ),
       );
}

class RadioListTileDemoArgs extends StoryArgs<RadioListTileDemo> {
  RadioListTileDemoArgs({
    Arg<Key?>? key,
    Arg<AuraTint?>? tint,
    Arg<bool>? disabled,
    Arg<bool>? showSubtitle,
  }) : this.keyArg = $initArg('key', key, null),
       this.tintArg = $initArg(
         'tint',
         tint,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!,
       this.disabledArg = $initArg('disabled', disabled, BoolArg(false))!,
       this.showSubtitleArg = $initArg(
         'showSubtitle',
         showSubtitle,
         BoolArg(false),
       )!;

  RadioListTileDemoArgs.fixed({
    Key? key,
    AuraTint? tint = null,
    bool disabled = false,
    bool showSubtitle = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.tintArg = $initArg(
         'tint',
         tint == null ? null : Arg.fixed(tint),
         null,
       ),
       this.disabledArg = $initArg('disabled', Arg.fixed(disabled), null)!,
       this.showSubtitleArg = $initArg(
         'showSubtitle',
         Arg.fixed(showSubtitle),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<AuraTint?>? tintArg;

  final Arg<bool> disabledArg;

  final Arg<bool> showSubtitleArg;

  Key? get key => keyArg?.value;

  AuraTint? get tint => tintArg?.value;

  bool get disabled => disabledArg.value;

  bool get showSubtitle => showSubtitleArg.value;

  @override
  List<Arg?> get list => [keyArg, tintArg, disabledArg, showSubtitleArg];
}
