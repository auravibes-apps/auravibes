// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_checkbox_list_tile.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<CheckboxListTileDemo, StoryArgs<CheckboxListTileDemo>>;
typedef _Scenario = CheckboxListTileDemoScenario;
typedef _Defaults = CheckboxListTileDemoDefaults;
typedef _Story = CheckboxListTileDemoStory;
typedef _Args = CheckboxListTileDemoArgs;
final CheckboxListTileDemoComponent =
    Component<CheckboxListTileDemo, StoryArgs<CheckboxListTileDemo>>(
      name: component.name ?? 'CheckboxListTileDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment:
          r'''Demonstrates a settings-style checkbox tile with optional supporting text.''',
      stories: [$CheckboxListTile..$generatedName = 'CheckboxListTile'],
    );
typedef CheckboxListTileDemoScenario =
    Scenario<CheckboxListTileDemo, CheckboxListTileDemoArgs>;
typedef CheckboxListTileDemoDefaults =
    Defaults<CheckboxListTileDemo, CheckboxListTileDemoArgs>;

class CheckboxListTileDemoStory
    extends Story<CheckboxListTileDemo, CheckboxListTileDemoArgs> {
  CheckboxListTileDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CheckboxListTileDemoArgs? args,
    StoryWidgetBuilder<CheckboxListTileDemo, CheckboxListTileDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? CheckboxListTileDemoArgs(),
         builder:
             builder ??
             (context, args) => CheckboxListTileDemo(
               key: args.key,
               tint: args.tint,
               disabled: args.disabled,
               showSubtitle: args.showSubtitle,
               autofocus: args.autofocus,
             ),
       );
}

class CheckboxListTileDemoArgs extends StoryArgs<CheckboxListTileDemo> {
  CheckboxListTileDemoArgs({
    Arg<Key?>? key,
    Arg<AuraTint?>? tint,
    Arg<bool>? disabled,
    Arg<bool>? showSubtitle,
    Arg<bool>? autofocus,
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
       )!,
       this.autofocusArg = $initArg('autofocus', autofocus, BoolArg(false))!;

  CheckboxListTileDemoArgs.fixed({
    Key? key,
    AuraTint? tint = null,
    bool disabled = false,
    bool showSubtitle = false,
    bool autofocus = false,
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
       )!,
       this.autofocusArg = $initArg('autofocus', Arg.fixed(autofocus), null)!;

  final Arg<Key?>? keyArg;

  final Arg<AuraTint?>? tintArg;

  final Arg<bool> disabledArg;

  final Arg<bool> showSubtitleArg;

  final Arg<bool> autofocusArg;

  Key? get key => keyArg?.value;

  AuraTint? get tint => tintArg?.value;

  bool get disabled => disabledArg.value;

  bool get showSubtitle => showSubtitleArg.value;

  bool get autofocus => autofocusArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    tintArg,
    disabledArg,
    showSubtitleArg,
    autofocusArg,
  ];
}
