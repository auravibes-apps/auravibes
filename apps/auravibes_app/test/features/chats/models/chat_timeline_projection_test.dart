import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/models/chat_timeline_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chat timeline projection', () {
    test('keeps streaming responses visible without response actions', () {
      final source = ResolvedChatMessage(
        message: _message(
          id: 'streaming-response',
          content: 'partial response',
          status: MessageStatus.unfinished,
        ),
        isStreaming: true,
      );

      final items = buildChatTimelineItems([source], const {});

      expect(items, hasLength(1));
      expect(items.single, isA<MessageTimelineItem>());
      expect((items.single as MessageTimelineItem).source, source);
      expect(
        (items.single as MessageTimelineItem).showResponseActions,
        isFalse,
      );
      expect(hasAssistantResponseCandidate(source, const {}), isTrue);
    });

    test('projects thinking and forked tool calls into activity entries', () {
      const toolCall = MessageToolCallEntity(
        id: 'search-call',
        name: 'search',
        argumentsRaw: '{"query":"birds"}',
      );
      final source = ResolvedChatMessage(
        message: _message(
          id: 'forked-activity',
          isForkReference: true,
          metadata: const MessageMetadataEntity(
            thinking: '  Searching sources  ',
            toolCalls: [toolCall],
          ),
        ),
        isStreaming: true,
      );

      final items = buildChatTimelineItems(
        [source],
        const {},
        pendingToolCallKeys: {
          activityToolCallKey('forked-activity', 'search-call'),
        },
      );
      final item = items.single as ActivityRunTimelineItem;
      final entries = buildActivityRunEntries(item.run);

      expect(item.run.id, 'forked-activity');
      expect(entries, hasLength(2));
      expect(
        (entries.first as ActivityThinkingEntry).content,
        'Searching sources',
      );
      final toolGroup = entries.last as ActivityToolGroupEntry;
      expect(toolGroup.toolCalls, hasLength(1));
      expect(toolGroup.toolCalls.single.isForkReference, isTrue);
      expect(toolGroup.toolCalls.single.isStreaming, isTrue);
      expect(toolGroup.toolCalls.single.hideArguments, isTrue);
    });

    test('keeps A2UI replay content as a message timeline item', () {
      final message = _message(
        id: 'a2ui-response',
        status: MessageStatus.unfinished,
        metadata: const MessageMetadataEntity(a2uiMessages: ['surface']),
      );
      final source = ResolvedChatMessage(message: message, isStreaming: false);

      final items = buildChatTimelineItems(
        [source],
        const {'a2ui-response': ['submitted-answer']},
      );

      expect(hasA2uiMessageState(message), isTrue);
      expect(items, hasLength(1));
      expect(items.single, isA<MessageTimelineItem>());
      expect((items.single as MessageTimelineItem).source, source);
    });

    test('places compaction summaries between separate activity runs', () {
      const beforeTool = MessageToolCallEntity(
        id: 'before-call',
        name: 'before',
        argumentsRaw: '{}',
      );
      const afterTool = MessageToolCallEntity(
        id: 'after-call',
        name: 'after',
        argumentsRaw: '{}',
      );
      final before = ResolvedChatMessage(
        message: _message(
          id: 'before-summary',
          metadata: const MessageMetadataEntity(toolCalls: [beforeTool]),
        ),
        isStreaming: false,
      );
      final summary = ResolvedChatMessage(
        message: _message(
          id: 'compaction-summary',
          messageType: MessageType.system,
          content: 'Earlier conversation summary',
          metadata: const MessageMetadataEntity(isCompactionSummary: true),
        ),
        isStreaming: false,
      );
      final after = ResolvedChatMessage(
        message: _message(
          id: 'after-summary',
          metadata: const MessageMetadataEntity(toolCalls: [afterTool]),
        ),
        isStreaming: false,
      );

      final items = buildChatTimelineItems([before, summary, after], const {});

      expect(items, hasLength(3));
      expect(items[0], isA<ActivityRunTimelineItem>());
      expect(items[1], isA<MessageTimelineItem>());
      expect((items[1] as MessageTimelineItem).source, summary);
      expect(items[2], isA<ActivityRunTimelineItem>());
      expect((items[0] as ActivityRunTimelineItem).run.id, 'before-summary');
      expect((items[2] as ActivityRunTimelineItem).run.id, 'after-summary');
    });

    test('projects retry eligibility and excludes fork references', () {
      final retryable = ResolvedChatMessage(
        message: _message(
          id: 'retryable-user',
          isUser: true,
          status: MessageStatus.error,
          content: 'Try this again',
        ),
        isStreaming: false,
      );
      final response = ResolvedChatMessage(
        message: _message(id: 'assistant-response', content: 'Failed.'),
        isStreaming: false,
      );
      final forkReference = ResolvedChatMessage(
        message: _message(
          id: 'forked-user',
          isUser: true,
          isForkReference: true,
          status: MessageStatus.unfinished,
          content: 'Inherited prompt',
        ),
        isStreaming: false,
      );

      expect(retryableUserMessageId([retryable, response]), 'retryable-user');
      expect(retryableUserMessageId([forkReference]), isNull);
    });
  });
}

MessageEntity _message({
  required String id,
  String content = '',
  MessageType messageType = MessageType.text,
  bool isUser = false,
  MessageStatus status = MessageStatus.sent,
  MessageMetadataEntity? metadata,
  bool isForkReference = false,
}) => MessageEntity(
  id: id,
  conversationId: 'conversation',
  content: content,
  messageType: messageType,
  isUser: isUser,
  status: status,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  metadata: metadata,
  isForkReference: isForkReference,
);
