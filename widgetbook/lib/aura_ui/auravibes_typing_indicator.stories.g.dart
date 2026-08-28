// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_typing_indicator.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<AuraTypingIndicator, StoryArgs<AuraTypingIndicator>>;
typedef _Scenario = AuraTypingIndicatorScenario;
typedef _Defaults = AuraTypingIndicatorDefaults;
typedef _Story = AuraTypingIndicatorStory;
typedef _Args = _TypingIndicatorInputArgs;
final AuraTypingIndicatorComponent =
    Component<AuraTypingIndicator, StoryArgs<AuraTypingIndicator>>(
      name: 'AuraTypingIndicator',
      path: 'aura_ui',
      docComment: r'''A typing indicator component that shows animated dots.

This component displays an animated typing indicator typically used to show
that the AI is processing or typing a response.''',
      stories: [
        $DefaultTypingIndicator..$generatedName = 'DefaultTypingIndicator',
      ],
    );
typedef AuraTypingIndicatorScenario =
    Scenario<AuraTypingIndicator, _TypingIndicatorInputArgs>;
typedef AuraTypingIndicatorDefaults =
    Defaults<AuraTypingIndicator, _TypingIndicatorInputArgs>;

class AuraTypingIndicatorStory
    extends Story<AuraTypingIndicator, _TypingIndicatorInputArgs> {
  AuraTypingIndicatorStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _TypingIndicatorInputArgs? args,
    StoryWidgetBuilder<AuraTypingIndicator, _TypingIndicatorInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _TypingIndicatorInputArgs(),
         builder: builder ?? typingIndicatorDefaults.builder!,
       );
}

class _TypingIndicatorInputArgs extends StoryArgs<AuraTypingIndicator> {
  _TypingIndicatorInputArgs({
    Arg<AuraTypingIndicatorSize>? size,
    Arg<Color>? color,
    Arg<bool>? showContainer,
    Arg<int>? animationDurationMs,
  }) : this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<AuraTypingIndicatorSize>(
           AuraTypingIndicatorSize.small,
           values: AuraTypingIndicatorSize.values,
         ),
       )!,
       this.colorArg = $initArg(
         'color',
         color,
         ColorArg(const Color(4278190080)),
       )!,
       this.showContainerArg = $initArg(
         'showContainer',
         showContainer,
         BoolArg(false),
       )!,
       this.animationDurationMsArg = $initArg(
         'animationDurationMs',
         animationDurationMs,
         IntArg(0),
       )!;

  _TypingIndicatorInputArgs.fixed({
    AuraTypingIndicatorSize size = AuraTypingIndicatorSize.small,
    Color color = const Color(4278190080),
    bool showContainer = false,
    int animationDurationMs = 0,
  }) : this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.colorArg = $initArg('color', Arg.fixed(color), null)!,
       this.showContainerArg = $initArg(
         'showContainer',
         Arg.fixed(showContainer),
         null,
       )!,
       this.animationDurationMsArg = $initArg(
         'animationDurationMs',
         Arg.fixed(animationDurationMs),
         null,
       )!;

  final Arg<AuraTypingIndicatorSize> sizeArg;

  final Arg<Color> colorArg;

  final Arg<bool> showContainerArg;

  final Arg<int> animationDurationMsArg;

  AuraTypingIndicatorSize get size => sizeArg.value;

  Color get color => colorArg.value;

  bool get showContainer => showContainerArg.value;

  int get animationDurationMs => animationDurationMsArg.value;

  @override
  List<Arg?> get list => [
    sizeArg,
    colorArg,
    showContainerArg,
    animationDurationMsArg,
  ];
}
