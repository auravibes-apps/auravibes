// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_message_bubble.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<MessageBubbleDemo, StoryArgs<MessageBubbleDemo>>;
typedef _Scenario = MessageBubbleDemoScenario;
typedef _Defaults = MessageBubbleDemoDefaults;
typedef _Story = MessageBubbleDemoStory;
typedef _Args = _MessageBubbleInputArgs;
final MessageBubbleDemoComponent =
    Component<MessageBubbleDemo, StoryArgs<MessageBubbleDemo>>(
      name: component.name ?? 'MessageBubbleDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment:
          r'''Demonstrates message content, delivery state, sizing, and callbacks.''',
      stories: [$AuraMessageBubble..$generatedName = 'AuraMessageBubble'],
    );
typedef MessageBubbleDemoScenario =
    Scenario<MessageBubbleDemo, _MessageBubbleInputArgs>;
typedef MessageBubbleDemoDefaults =
    Defaults<MessageBubbleDemo, _MessageBubbleInputArgs>;

class MessageBubbleDemoStory
    extends Story<MessageBubbleDemo, _MessageBubbleInputArgs> {
  MessageBubbleDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _MessageBubbleInputArgs? args,
    StoryWidgetBuilder<MessageBubbleDemo, _MessageBubbleInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _MessageBubbleInputArgs(),
         builder: builder ?? messageBubbleDefaults.builder!,
       );
}

class _MessageBubbleInputArgs extends StoryArgs<MessageBubbleDemo> {
  _MessageBubbleInputArgs({
    Arg<String>? content,
    Arg<bool>? isUser,
    Arg<AuraMessageDeliveryStatus>? status,
    Arg<DateTime?>? timestamp,
    Arg<AuraMessageContentType>? contentType,
    Arg<double?>? maxWidth,
    Arg<bool>? enableTap,
    Arg<bool>? enableLongPress,
  }) : this.contentArg = $initArg('content', content, StringArg(''))!,
       this.isUserArg = $initArg('isUser', isUser, BoolArg(false))!,
       this.statusArg = $initArg(
         'status',
         status,
         EnumArg<AuraMessageDeliveryStatus>(
           AuraMessageDeliveryStatus.sending,
           values: AuraMessageDeliveryStatus.values,
         ),
       )!,
       this.timestampArg = $initArg(
         'timestamp',
         timestamp,
         NullableDateTimeArg(null),
       )!,
       this.contentTypeArg = $initArg(
         'contentType',
         contentType,
         EnumArg<AuraMessageContentType>(
           AuraMessageContentType.text,
           values: AuraMessageContentType.values,
         ),
       )!,
       this.maxWidthArg = $initArg(
         'maxWidth',
         maxWidth,
         NullableDoubleArg(null),
       )!,
       this.enableTapArg = $initArg('enableTap', enableTap, BoolArg(false))!,
       this.enableLongPressArg = $initArg(
         'enableLongPress',
         enableLongPress,
         BoolArg(false),
       )!;

  _MessageBubbleInputArgs.fixed({
    String content = '',
    bool isUser = false,
    AuraMessageDeliveryStatus status = AuraMessageDeliveryStatus.sending,
    DateTime? timestamp = null,
    AuraMessageContentType contentType = AuraMessageContentType.text,
    double? maxWidth = null,
    bool enableTap = false,
    bool enableLongPress = false,
  }) : this.contentArg = $initArg('content', Arg.fixed(content), null)!,
       this.isUserArg = $initArg('isUser', Arg.fixed(isUser), null)!,
       this.statusArg = $initArg('status', Arg.fixed(status), null)!,
       this.timestampArg = $initArg(
         'timestamp',
         timestamp == null ? null : Arg.fixed(timestamp),
         null,
       ),
       this.contentTypeArg = $initArg(
         'contentType',
         Arg.fixed(contentType),
         null,
       )!,
       this.maxWidthArg = $initArg(
         'maxWidth',
         maxWidth == null ? null : Arg.fixed(maxWidth),
         null,
       ),
       this.enableTapArg = $initArg('enableTap', Arg.fixed(enableTap), null)!,
       this.enableLongPressArg = $initArg(
         'enableLongPress',
         Arg.fixed(enableLongPress),
         null,
       )!;

  final Arg<String> contentArg;

  final Arg<bool> isUserArg;

  final Arg<AuraMessageDeliveryStatus> statusArg;

  final Arg<DateTime?>? timestampArg;

  final Arg<AuraMessageContentType> contentTypeArg;

  final Arg<double?>? maxWidthArg;

  final Arg<bool> enableTapArg;

  final Arg<bool> enableLongPressArg;

  String get content => contentArg.value;

  bool get isUser => isUserArg.value;

  AuraMessageDeliveryStatus get status => statusArg.value;

  DateTime? get timestamp => timestampArg?.value;

  AuraMessageContentType get contentType => contentTypeArg.value;

  double? get maxWidth => maxWidthArg?.value;

  bool get enableTap => enableTapArg.value;

  bool get enableLongPress => enableLongPressArg.value;

  @override
  List<Arg?> get list => [
    contentArg,
    isUserArg,
    statusArg,
    timestampArg,
    contentTypeArg,
    maxWidthArg,
    enableTapArg,
    enableLongPressArg,
  ];
}
