// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_message_status.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraMessageStatus, StoryArgs<AuraMessageStatus>>;
typedef _Scenario = AuraMessageStatusScenario;
typedef _Defaults = AuraMessageStatusDefaults;
typedef _Story = AuraMessageStatusStory;
typedef _Args = _MessageStatusInputArgs;
final AuraMessageStatusComponent =
    Component<AuraMessageStatus, StoryArgs<AuraMessageStatus>>(
      name: 'AuraMessageStatus',
      path: 'aura_ui',
      docComment: r'''A message delivery status indicator component.

This component displays the delivery status of messages with appropriate
icons and colors, typically used alongside message bubbles.''',
      stories: [$SendingStatus..$generatedName = 'SendingStatus'],
    );
typedef AuraMessageStatusScenario =
    Scenario<AuraMessageStatus, _MessageStatusInputArgs>;
typedef AuraMessageStatusDefaults =
    Defaults<AuraMessageStatus, _MessageStatusInputArgs>;

class AuraMessageStatusStory
    extends Story<AuraMessageStatus, _MessageStatusInputArgs> {
  AuraMessageStatusStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _MessageStatusInputArgs? args,
    StoryWidgetBuilder<AuraMessageStatus, _MessageStatusInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _MessageStatusInputArgs(),
         builder: builder ?? messageStatusDefaults.builder!,
       );
}

class _MessageStatusInputArgs extends StoryArgs<AuraMessageStatus> {
  _MessageStatusInputArgs({
    Arg<AuraMessageDeliveryStatus>? status,
    Arg<AuraMessageStatusSize>? size,
    Arg<AuraTint?>? tint,
    Arg<bool>? showAnimation,
    Arg<String?>? semanticLabel,
  }) : this.statusArg = $initArg(
         'status',
         status,
         EnumArg<AuraMessageDeliveryStatus>(
           AuraMessageDeliveryStatus.sending,
           values: AuraMessageDeliveryStatus.values,
         ),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<AuraMessageStatusSize>(
           AuraMessageStatusSize.small,
           values: AuraMessageStatusSize.values,
         ),
       )!,
       this.tintArg = $initArg(
         'tint',
         tint,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!,
       this.showAnimationArg = $initArg(
         'showAnimation',
         showAnimation,
         BoolArg(false),
       )!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         NullableStringArg(null),
       )!;

  _MessageStatusInputArgs.fixed({
    AuraMessageDeliveryStatus status = AuraMessageDeliveryStatus.sending,
    AuraMessageStatusSize size = AuraMessageStatusSize.small,
    AuraTint? tint = null,
    bool showAnimation = false,
    String? semanticLabel = null,
  }) : this.statusArg = $initArg('status', Arg.fixed(status), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.tintArg = $initArg(
         'tint',
         tint == null ? null : Arg.fixed(tint),
         null,
       ),
       this.showAnimationArg = $initArg(
         'showAnimation',
         Arg.fixed(showAnimation),
         null,
       )!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel == null ? null : Arg.fixed(semanticLabel),
         null,
       );

  final Arg<AuraMessageDeliveryStatus> statusArg;

  final Arg<AuraMessageStatusSize> sizeArg;

  final Arg<AuraTint?>? tintArg;

  final Arg<bool> showAnimationArg;

  final Arg<String?>? semanticLabelArg;

  AuraMessageDeliveryStatus get status => statusArg.value;

  AuraMessageStatusSize get size => sizeArg.value;

  AuraTint? get tint => tintArg?.value;

  bool get showAnimation => showAnimationArg.value;

  String? get semanticLabel => semanticLabelArg?.value;

  @override
  List<Arg?> get list => [
    statusArg,
    sizeArg,
    tintArg,
    showAnimationArg,
    semanticLabelArg,
  ];
}
