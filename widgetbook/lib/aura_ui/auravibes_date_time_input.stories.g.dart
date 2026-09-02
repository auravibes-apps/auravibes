// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_date_time_input.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<DateTimeInputDemo, StoryArgs<DateTimeInputDemo>>;
typedef _Scenario = DateTimeInputDemoScenario;
typedef _Defaults = DateTimeInputDemoDefaults;
typedef _Story = DateTimeInputDemoStory;
typedef _Args = _DateTimeInputControlsArgs;
final DateTimeInputDemoComponent =
    Component<DateTimeInputDemo, StoryArgs<DateTimeInputDemo>>(
      name: component.name ?? 'DateTimeInputDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment: r'''Demonstrates the controlled date and time picker in its supported modes.''',
      stories: [$DateAndTime..$generatedName = 'DateAndTime'],
    );
typedef DateTimeInputDemoScenario =
    Scenario<DateTimeInputDemo, _DateTimeInputControlsArgs>;
typedef DateTimeInputDemoDefaults =
    Defaults<DateTimeInputDemo, _DateTimeInputControlsArgs>;

class DateTimeInputDemoStory
    extends Story<DateTimeInputDemo, _DateTimeInputControlsArgs> {
  DateTimeInputDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _DateTimeInputControlsArgs? args,
    StoryWidgetBuilder<DateTimeInputDemo, _DateTimeInputControlsArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _DateTimeInputControlsArgs(),
         builder: builder ?? dateTimeInputDefaults.builder!,
       );
}

class _DateTimeInputControlsArgs extends StoryArgs<DateTimeInputDemo> {
  _DateTimeInputControlsArgs({
    Arg<bool>? enableDate,
    Arg<bool>? enableTime,
    Arg<bool>? enabled,
    Arg<DateTime>? initialValue,
  }) : this.enableDateArg = $initArg('enableDate', enableDate, BoolArg(false))!,
       this.enableTimeArg = $initArg('enableTime', enableTime, BoolArg(false))!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(false))!,
       this.initialValueArg = $initArg(
         'initialValue',
         initialValue,
         DateTimeArg(DateTime.now()),
       )!;

  _DateTimeInputControlsArgs.fixed({
    bool enableDate = false,
    bool enableTime = false,
    bool enabled = false,
    DateTime? initialValue,
  }) : this.enableDateArg = $initArg(
         'enableDate',
         Arg.fixed(enableDate),
         null,
       )!,
       this.enableTimeArg = $initArg(
         'enableTime',
         Arg.fixed(enableTime),
         null,
       )!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.initialValueArg = $initArg(
         'initialValue',
         Arg.fixed(initialValue ?? DateTime.now()),
         null,
       )!;

  final Arg<bool> enableDateArg;

  final Arg<bool> enableTimeArg;

  final Arg<bool> enabledArg;

  final Arg<DateTime> initialValueArg;

  bool get enableDate => enableDateArg.value;

  bool get enableTime => enableTimeArg.value;

  bool get enabled => enabledArg.value;

  DateTime get initialValue => initialValueArg.value;

  @override
  List<Arg?> get list => [
    enableDateArg,
    enableTimeArg,
    enabledArg,
    initialValueArg,
  ];
}
