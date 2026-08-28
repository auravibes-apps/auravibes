// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_alert_dialog.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AlertDialogDemo, StoryArgs<AlertDialogDemo>>;
typedef _Scenario = AlertDialogDemoScenario;
typedef _Defaults = AlertDialogDemoDefaults;
typedef _Story = AlertDialogDemoStory;
typedef _Args = AlertDialogDemoArgs;
final AlertDialogDemoComponent =
    Component<AlertDialogDemo, StoryArgs<AlertDialogDemo>>(
      name: component.name ?? 'AlertDialogDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment:
          r'''Demonstrates the alert dialog trigger and dismissible dialog content.''',
      stories: [$AlertDialog..$generatedName = 'AlertDialog'],
    );
typedef AlertDialogDemoScenario =
    Scenario<AlertDialogDemo, AlertDialogDemoArgs>;
typedef AlertDialogDemoDefaults =
    Defaults<AlertDialogDemo, AlertDialogDemoArgs>;

class AlertDialogDemoStory extends Story<AlertDialogDemo, AlertDialogDemoArgs> {
  AlertDialogDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    AlertDialogDemoArgs? args,
    StoryWidgetBuilder<AlertDialogDemo, AlertDialogDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AlertDialogDemoArgs(),
         builder:
             builder ??
             (context, args) => AlertDialogDemo(key: args.key, tint: args.tint),
       );
}

class AlertDialogDemoArgs extends StoryArgs<AlertDialogDemo> {
  AlertDialogDemoArgs({Arg<Key?>? key, Arg<AuraTint?>? tint})
    : this.keyArg = $initArg('key', key, null),
      this.tintArg = $initArg(
        'tint',
        tint,
        NullableEnumArg<AuraTint>(null, values: AuraTint.values),
      )!;

  AlertDialogDemoArgs.fixed({Key? key, AuraTint? tint = null})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.tintArg = $initArg(
        'tint',
        tint == null ? null : Arg.fixed(tint),
        null,
      );

  final Arg<Key?>? keyArg;

  final Arg<AuraTint?>? tintArg;

  Key? get key => keyArg?.value;

  AuraTint? get tint => tintArg?.value;

  @override
  List<Arg?> get list => [keyArg, tintArg];
}
