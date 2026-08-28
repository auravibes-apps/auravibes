// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_snackbar.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SnackBarDemo, StoryArgs<SnackBarDemo>>;
typedef _Scenario = SnackBarDemoScenario;
typedef _Defaults = SnackBarDemoDefaults;
typedef _Story = SnackBarDemoStory;
typedef _Args = _SnackBarInputArgs;
final SnackBarDemoComponent = Component<SnackBarDemo, StoryArgs<SnackBarDemo>>(
  name: component.name ?? 'SnackBarDemo',
  path: component.path ?? 'aura_ui',
  docsBuilder: component.docsBuilder,
  docComment:
      r'''Demonstrates snackbar variants, actions, and display duration.''',
  stories: [$SnackbarVariants..$generatedName = 'SnackbarVariants'],
);
typedef SnackBarDemoScenario = Scenario<SnackBarDemo, _SnackBarInputArgs>;
typedef SnackBarDemoDefaults = Defaults<SnackBarDemo, _SnackBarInputArgs>;

class SnackBarDemoStory extends Story<SnackBarDemo, _SnackBarInputArgs> {
  SnackBarDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _SnackBarInputArgs? args,
    StoryWidgetBuilder<SnackBarDemo, _SnackBarInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _SnackBarInputArgs(),
         builder: builder ?? snackbarDefaults.builder!,
       );
}

class _SnackBarInputArgs extends StoryArgs<SnackBarDemo> {
  _SnackBarInputArgs({
    Arg<AuraSnackBarVariant>? variant,
    Arg<bool>? showAction,
    Arg<int>? durationSeconds,
  }) : this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<AuraSnackBarVariant>(
           AuraSnackBarVariant.default_,
           values: AuraSnackBarVariant.values,
         ),
       )!,
       this.showActionArg = $initArg('showAction', showAction, BoolArg(false))!,
       this.durationSecondsArg = $initArg(
         'durationSeconds',
         durationSeconds,
         IntArg(0),
       )!;

  _SnackBarInputArgs.fixed({
    AuraSnackBarVariant variant = AuraSnackBarVariant.default_,
    bool showAction = false,
    int durationSeconds = 0,
  }) : this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.showActionArg = $initArg(
         'showAction',
         Arg.fixed(showAction),
         null,
       )!,
       this.durationSecondsArg = $initArg(
         'durationSeconds',
         Arg.fixed(durationSeconds),
         null,
       )!;

  final Arg<AuraSnackBarVariant> variantArg;

  final Arg<bool> showActionArg;

  final Arg<int> durationSecondsArg;

  AuraSnackBarVariant get variant => variantArg.value;

  bool get showAction => showActionArg.value;

  int get durationSeconds => durationSecondsArg.value;

  @override
  List<Arg?> get list => [variantArg, showActionArg, durationSecondsArg];
}
