// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_checkbox_single.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<SingleCheckboxDemo, StoryArgs<SingleCheckboxDemo>>;
typedef _Scenario = SingleCheckboxDemoScenario;
typedef _Defaults = SingleCheckboxDemoDefaults;
typedef _Story = SingleCheckboxDemoStory;
typedef _Args = SingleCheckboxDemoArgs;
final SingleCheckboxDemoComponent =
    Component<SingleCheckboxDemo, StoryArgs<SingleCheckboxDemo>>(
      name: component.name ?? 'SingleCheckboxDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment: r'''Demonstrates a controlled checkbox with focus, tint, and disabled states.''',
      stories: [$SingleCheckbox..$generatedName = 'SingleCheckbox'],
    );
typedef SingleCheckboxDemoScenario =
    Scenario<SingleCheckboxDemo, SingleCheckboxDemoArgs>;
typedef SingleCheckboxDemoDefaults =
    Defaults<SingleCheckboxDemo, SingleCheckboxDemoArgs>;

class SingleCheckboxDemoStory
    extends Story<SingleCheckboxDemo, SingleCheckboxDemoArgs> {
  SingleCheckboxDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    SingleCheckboxDemoArgs? args,
    StoryWidgetBuilder<SingleCheckboxDemo, SingleCheckboxDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SingleCheckboxDemoArgs(),
         builder:
             builder ??
             (context, args) => SingleCheckboxDemo(
               key: args.key,
               tint: args.tint,
               disabled: args.disabled,
               autofocus: args.autofocus,
             ),
       );
}

class SingleCheckboxDemoArgs extends StoryArgs<SingleCheckboxDemo> {
  SingleCheckboxDemoArgs({
    Arg<Key?>? key,
    Arg<AuraTint?>? tint,
    Arg<bool>? disabled,
    Arg<bool>? autofocus,
  }) : this.keyArg = $initArg('key', key, null),
       this.tintArg = $initArg(
         'tint',
         tint,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!,
       this.disabledArg = $initArg('disabled', disabled, BoolArg(false))!,
       this.autofocusArg = $initArg('autofocus', autofocus, BoolArg(false))!;

  SingleCheckboxDemoArgs.fixed({
    Key? key,
    AuraTint? tint = null,
    bool disabled = false,
    bool autofocus = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.tintArg = $initArg(
         'tint',
         tint == null ? null : Arg.fixed(tint),
         null,
       ),
       this.disabledArg = $initArg('disabled', Arg.fixed(disabled), null)!,
       this.autofocusArg = $initArg('autofocus', Arg.fixed(autofocus), null)!;

  final Arg<Key?>? keyArg;

  final Arg<AuraTint?>? tintArg;

  final Arg<bool> disabledArg;

  final Arg<bool> autofocusArg;

  Key? get key => keyArg?.value;

  AuraTint? get tint => tintArg?.value;

  bool get disabled => disabledArg.value;

  bool get autofocus => autofocusArg.value;

  @override
  List<Arg?> get list => [keyArg, tintArg, disabledArg, autofocusArg];
}
