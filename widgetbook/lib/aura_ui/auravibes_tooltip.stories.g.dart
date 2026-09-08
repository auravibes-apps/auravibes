// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_tooltip.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraTooltip, StoryArgs<AuraTooltip>>;
typedef _Scenario = AuraTooltipScenario;
typedef _Defaults = AuraTooltipDefaults;
typedef _Story = AuraTooltipStory;
typedef _Args = _TooltipInputArgs;
final AuraTooltipComponent = Component<AuraTooltip, StoryArgs<AuraTooltip>>(
  name: 'AuraTooltip',
  path: 'aura_ui',
  docComment: r'''A custom tooltip widget that follows the Aura design system.

This tooltip uses Flutter's native tooltip behavior with Aura styling.

Example:
```dart
AuraTooltip(
  message: 'This is a helpful tip',
  child: IconButton(
    icon: Icon(Icons.info),
    onPressed: () {},
  ),
)
```''',
  stories: [$DefaultTooltip..$generatedName = 'DefaultTooltip'],
);
typedef AuraTooltipScenario = Scenario<AuraTooltip, _TooltipInputArgs>;
typedef AuraTooltipDefaults = Defaults<AuraTooltip, _TooltipInputArgs>;

class AuraTooltipStory extends Story<AuraTooltip, _TooltipInputArgs> {
  AuraTooltipStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _TooltipInputArgs? args,
    StoryWidgetBuilder<AuraTooltip, _TooltipInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _TooltipInputArgs(),
         builder: builder ?? tooltipDefaults.builder!,
       );
}

class _TooltipInputArgs extends StoryArgs<AuraTooltip> {
  _TooltipInputArgs({
    Arg<String>? message,
    Arg<AuraTint>? tint,
    Arg<double>? showDurationMs,
    Arg<double>? waitDurationMs,
  }) : this.messageArg = $initArg('message', message, StringArg(''))!,
       this.tintArg = $initArg(
         'tint',
         tint,
         EnumArg<AuraTint>(AuraTint.primary, values: AuraTint.values),
       )!,
       this.showDurationMsArg = $initArg(
         'showDurationMs',
         showDurationMs,
         DoubleArg(0.0),
       )!,
       this.waitDurationMsArg = $initArg(
         'waitDurationMs',
         waitDurationMs,
         DoubleArg(0.0),
       )!;

  _TooltipInputArgs.fixed({
    String message = '',
    AuraTint tint = AuraTint.primary,
    double showDurationMs = 0.0,
    double waitDurationMs = 0.0,
  }) : this.messageArg = $initArg('message', Arg.fixed(message), null)!,
       this.tintArg = $initArg('tint', Arg.fixed(tint), null)!,
       this.showDurationMsArg = $initArg(
         'showDurationMs',
         Arg.fixed(showDurationMs),
         null,
       )!,
       this.waitDurationMsArg = $initArg(
         'waitDurationMs',
         Arg.fixed(waitDurationMs),
         null,
       )!;

  final Arg<String> messageArg;

  final Arg<AuraTint> tintArg;

  final Arg<double> showDurationMsArg;

  final Arg<double> waitDurationMsArg;

  String get message => messageArg.value;

  AuraTint get tint => tintArg.value;

  double get showDurationMs => showDurationMsArg.value;

  double get waitDurationMs => waitDurationMsArg.value;

  @override
  List<Arg?> get list => [
    messageArg,
    tintArg,
    showDurationMsArg,
    waitDurationMsArg,
  ];
}
