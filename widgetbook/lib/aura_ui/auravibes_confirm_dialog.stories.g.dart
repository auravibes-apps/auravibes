// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_confirm_dialog.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ConfirmDialogDemo, StoryArgs<ConfirmDialogDemo>>;
typedef _Scenario = ConfirmDialogDemoScenario;
typedef _Defaults = ConfirmDialogDemoDefaults;
typedef _Story = ConfirmDialogDemoStory;
typedef _Args = ConfirmDialogDemoArgs;
final ConfirmDialogDemoComponent =
    Component<ConfirmDialogDemo, StoryArgs<ConfirmDialogDemo>>(
      name: component.name ?? 'ConfirmDialogDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment: r'''Demonstrates a confirmation dialog with destructive and tinted states.''',
      stories: [$ConfirmDialog..$generatedName = 'ConfirmDialog'],
    );
typedef ConfirmDialogDemoScenario =
    Scenario<ConfirmDialogDemo, ConfirmDialogDemoArgs>;
typedef ConfirmDialogDemoDefaults =
    Defaults<ConfirmDialogDemo, ConfirmDialogDemoArgs>;

class ConfirmDialogDemoStory
    extends Story<ConfirmDialogDemo, ConfirmDialogDemoArgs> {
  ConfirmDialogDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ConfirmDialogDemoArgs? args,
    StoryWidgetBuilder<ConfirmDialogDemo, ConfirmDialogDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ConfirmDialogDemoArgs(),
         builder:
             builder ??
             (context, args) => ConfirmDialogDemo(
               key: args.key,
               isDestructive: args.isDestructive,
               tint: args.tint,
             ),
       );
}

class ConfirmDialogDemoArgs extends StoryArgs<ConfirmDialogDemo> {
  ConfirmDialogDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? isDestructive,
    Arg<AuraTint?>? tint,
  }) : this.keyArg = $initArg('key', key, null),
       this.isDestructiveArg = $initArg(
         'isDestructive',
         isDestructive,
         BoolArg(false),
       )!,
       this.tintArg = $initArg(
         'tint',
         tint,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!;

  ConfirmDialogDemoArgs.fixed({
    Key? key,
    bool isDestructive = false,
    AuraTint? tint = null,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.isDestructiveArg = $initArg(
         'isDestructive',
         Arg.fixed(isDestructive),
         null,
       )!,
       this.tintArg = $initArg(
         'tint',
         tint == null ? null : Arg.fixed(tint),
         null,
       );

  final Arg<Key?>? keyArg;

  final Arg<bool> isDestructiveArg;

  final Arg<AuraTint?>? tintArg;

  Key? get key => keyArg?.value;

  bool get isDestructive => isDestructiveArg.value;

  AuraTint? get tint => tintArg?.value;

  @override
  List<Arg?> get list => [keyArg, isDestructiveArg, tintArg];
}
