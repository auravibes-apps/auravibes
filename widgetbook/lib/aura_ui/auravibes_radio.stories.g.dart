// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_radio.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SingleRadioDemo, StoryArgs<SingleRadioDemo>>;
typedef _Scenario = SingleRadioDemoScenario;
typedef _Defaults = SingleRadioDemoDefaults;
typedef _Story = SingleRadioDemoStory;
typedef _Args = _RadioInputArgs;
final SingleRadioDemoComponent =
    Component<SingleRadioDemo, StoryArgs<SingleRadioDemo>>(
      name: component.name ?? 'SingleRadioDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment: r'''Demonstrates a single controlled radio button.''',
      stories: [$SingleRadio..$generatedName = 'SingleRadio'],
    );
typedef SingleRadioDemoScenario = Scenario<SingleRadioDemo, _RadioInputArgs>;
typedef SingleRadioDemoDefaults = Defaults<SingleRadioDemo, _RadioInputArgs>;

class SingleRadioDemoStory extends Story<SingleRadioDemo, _RadioInputArgs> {
  SingleRadioDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _RadioInputArgs? args,
    StoryWidgetBuilder<SingleRadioDemo, _RadioInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _RadioInputArgs(),
         builder: builder ?? radioDefaults.builder!,
       );
}

class _RadioInputArgs extends StoryArgs<SingleRadioDemo> {
  _RadioInputArgs({
    Arg<AuraTint?>? tint,
    Arg<bool>? disabled,
    Arg<int>? itemCount,
  }) : this.tintArg = $initArg(
         'tint',
         tint,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!,
       this.disabledArg = $initArg('disabled', disabled, BoolArg(false))!,
       this.itemCountArg = $initArg('itemCount', itemCount, IntArg(0))!;

  _RadioInputArgs.fixed({
    AuraTint? tint = null,
    bool disabled = false,
    int itemCount = 0,
  }) : this.tintArg = $initArg(
         'tint',
         tint == null ? null : Arg.fixed(tint),
         null,
       ),
       this.disabledArg = $initArg('disabled', Arg.fixed(disabled), null)!,
       this.itemCountArg = $initArg('itemCount', Arg.fixed(itemCount), null)!;

  final Arg<AuraTint?>? tintArg;

  final Arg<bool> disabledArg;

  final Arg<int> itemCountArg;

  AuraTint? get tint => tintArg?.value;

  bool get disabled => disabledArg.value;

  int get itemCount => itemCountArg.value;

  @override
  List<Arg?> get list => [tintArg, disabledArg, itemCountArg];
}
