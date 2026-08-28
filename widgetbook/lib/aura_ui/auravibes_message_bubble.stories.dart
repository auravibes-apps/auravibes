// Required: Widgetbook stories use intentional no-op callbacks.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_message_bubble.stories.g.dart';

class _MessageBubbleInput {
  const _MessageBubbleInput({
    required this.content,
    required this.isUser,
    required this.status,
    required this.timestamp,
    required this.contentType,
    required this.maxWidth,
    required this.enableTap,
    required this.enableLongPress,
  });

  final String content;
  final bool isUser;
  final AuraMessageDeliveryStatus status;
  final DateTime? timestamp;
  final AuraMessageContentType contentType;
  final double? maxWidth;
  final bool enableTap;
  final bool enableLongPress;
}

const component = ComponentMeta(name: 'AuraMessageBubble');
const meta = Meta(MessageBubbleDemo.new, argsType: _MessageBubbleInput.new);

final _Defaults messageBubbleDefaults = _Defaults(
  builder: (context, args) => MessageBubbleDemo(
    content: args.content,
    isUser: args.isUser,
    status: args.status,
    timestamp: args.timestamp,
    contentType: args.contentType,
    maxWidth: args.maxWidth,
    enableTap: args.enableTap,
    enableLongPress: args.enableLongPress,
    imageProvider: auraSampleImageProvider(),
    now: () => DateTime(2026, 8, 28, 12),
  ),
);

final $AuraMessageBubble = _Story(
  name: 'Aura Message Bubble',
  setup: (context, child, args) => constrainStoryWidth(
    Padding(padding: const EdgeInsets.all(16), child: child),
  ),
  args: _Args(
    content: StringArg(
      'Hello! How can you help me with my Flutter project today?',
      name: 'Content',
    ),
    isUser: BoolArg(true, name: 'Is User'),
    status: EnumArg(
      AuraMessageDeliveryStatus.values.first,
      name: 'Status',
      values: AuraMessageDeliveryStatus.values,
    ),
    timestamp: NullableDateTimeArg(
      DateTime(2026, 8, 28, 12, 0),
      name: 'Show Timestamp',
      start: DateTime(2023),
      end: DateTime(2030),
    ),
    contentType: EnumArg(
      AuraMessageContentType.values.first,
      name: 'Content Type',
      values: AuraMessageContentType.values,
    ),
    maxWidth: NullableDoubleArg(
      null,
      name: 'Max Width',
      style: const SliderDoubleArgStyle(min: 160, max: 420, divisions: 26),
    ),
    enableTap: BoolArg(true, name: 'Enable Tap'),
    enableLongPress: BoolArg(true, name: 'Enable Long Press'),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(
      name: 'Landscape Phone',
      modes: [ViewportMode(landscapePhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
    _Scenario(
      name: 'Tapped',
      run: (tester, args) async {
        await tester.tap(find.byType(AuraMessageBubble));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
    _Scenario(
      name: 'Long Pressed',
      run: (tester, args) async {
        await tester.longPress(find.byType(AuraMessageBubble));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates message content, delivery state, sizing, and callbacks.
class MessageBubbleDemo extends StatefulWidget {
  const MessageBubbleDemo({
    super.key,
    required this.content,
    required this.isUser,
    required this.status,
    required this.timestamp,
    required this.contentType,
    required this.maxWidth,
    required this.enableTap,
    required this.enableLongPress,
    this.imageProvider,
    this.now,
  });

  final String content;
  final bool isUser;
  final AuraMessageDeliveryStatus status;
  final DateTime? timestamp;
  final AuraMessageContentType contentType;
  final double? maxWidth;
  final bool enableTap;
  final bool enableLongPress;
  final ImageProvider<Object>? imageProvider;
  final DateTime Function()? now;

  @override
  State<MessageBubbleDemo> createState() => _MessageBubbleDemoState();
}

class _MessageBubbleDemoState extends State<MessageBubbleDemo> {
  String? _lastInteraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuraMessageBubble(
          content: widget.content,
          isUser: widget.isUser,
          status: widget.status,
          timestamp: widget.timestamp,
          contentType: widget.contentType,
          onTap: widget.enableTap
              ? () => setState(() => _lastInteraction = 'Tapped')
              : null,
          onLongPress: widget.enableLongPress
              ? () => setState(() => _lastInteraction = 'Long pressed')
              : null,
          maxWidth: widget.maxWidth,
          manageAlignment: false,
          imageProvider: widget.imageProvider,
          now: widget.now,
        ),
        if (_lastInteraction case final interaction?)
          Center(child: Text('Last interaction: $interaction')),
      ],
    );
  }
}
