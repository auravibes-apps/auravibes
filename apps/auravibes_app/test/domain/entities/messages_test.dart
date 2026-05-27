// ignore_for_file: avoid-non-null-assertion
// Required: Tests inspect nullable values after arranging expected state.

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageToolCallEntity', () {
    test('arguments parses raw JSON arguments', () {
      const toolCall = MessageToolCallEntity(
        id: 'call_1',
        name: 'test_tool',
        argumentsRaw: '{"key": "value"}',
      );
      expect(toolCall.arguments, {'key': 'value'});
    });

    test('arguments returns empty map for invalid raw', () {
      const toolCall = MessageToolCallEntity(
        id: 'call_2',
        name: 'test_tool',
        argumentsRaw: 'not json',
      );
      expect(toolCall.arguments, <String, dynamic>{});
    });

    test('isResolved true when resultStatus is non-null', () {
      const toolCall = MessageToolCallEntity(
        id: 'call_3',
        name: 'test_tool',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.success,
      );
      expect(toolCall.isResolved, isTrue);
    });

    test('isResolved false when resultStatus is null', () {
      const toolCall = MessageToolCallEntity(
        id: 'call_4',
        name: 'test_tool',
        argumentsRaw: '{}',
      );
      expect(toolCall.isResolved, isFalse);
    });

    test('isPending true when resultStatus is null', () {
      const toolCall = MessageToolCallEntity(
        id: 'call_5',
        name: 'test_tool',
        argumentsRaw: '{}',
      );
      expect(toolCall.isPending, isTrue);
    });

    test('isPending false when resultStatus is non-null', () {
      const toolCall = MessageToolCallEntity(
        id: 'call_6',
        name: 'test_tool',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.success,
      );
      expect(toolCall.isPending, isFalse);
    });

    test('getResponseForAI returns responseRaw when available', () {
      const toolCall = MessageToolCallEntity(
        id: 'call_7',
        name: 'test_tool',
        argumentsRaw: '{}',
        responseRaw: 'custom response',
        resultStatus: ToolCallResultStatus.success,
      );
      expect(toolCall.getResponseForAI(), 'custom response');
    });

    test('getResponseForAI falls back to resultStatus response', () {
      const toolCall = MessageToolCallEntity(
        id: 'call_8',
        name: 'test_tool',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.executionError,
      );
      expect(toolCall.getResponseForAI(), 'Tool execution failed.');
    });

    test('getResponseForAI returns empty when both are null', () {
      const toolCall = MessageToolCallEntity(
        id: 'call_9',
        name: 'test_tool',
        argumentsRaw: '{}',
      );
      expect(toolCall.getResponseForAI(), '');
    });
  });

  group('MessageMetadataEntity', () {
    test('fromJsonString returns null for null input', () {
      expect(MessageMetadataEntity.fromJsonString(null), isNull);
    });

    test('fromJsonString parses valid JSON metadata', () {
      final metadata = MessageMetadataEntity.fromJsonString(
        '{"promptTokens": 10, "completionTokens": 5, "totalTokens": 15}',
      );
      expect(metadata, isNotNull);
      expect(metadata!.promptTokens, 10);
      expect(metadata.completionTokens, 5);
      expect(metadata.totalTokens, 15);
    });

    test('fromJsonString returns null for invalid JSON', () {
      final metadata = MessageMetadataEntity.fromJsonString('not json');
      expect(metadata, isNull);
    });

    test('fromJsonString parses metadata with tool calls', () {
      const json = '{"promptTokens": 10, "toolCalls": []}';
      final metadata = MessageMetadataEntity.fromJsonString(json);
      expect(metadata, isNotNull);
      expect(metadata!.promptTokens, 10);
      expect(metadata.toolCalls, isEmpty);
    });

    group('usedTokens', () {
      test('returns totalTokens when set', () {
        const metadata = MessageMetadataEntity(totalTokens: 100);
        expect(metadata.usedTokens, 100);
      });

      test('returns sum of prompt and completion when total is null', () {
        const metadata = MessageMetadataEntity(
          promptTokens: 30,
          completionTokens: 20,
        );
        expect(metadata.usedTokens, 50);
      });

      test('returns promptTokens when completion is null', () {
        const metadata = MessageMetadataEntity(promptTokens: 30);
        expect(metadata.usedTokens, 30);
      });

      test('returns completionTokens when prompt is null', () {
        const metadata = MessageMetadataEntity(completionTokens: 20);
        expect(metadata.usedTokens, 20);
      });

      test('returns 0 when all tokens are null', () {
        const metadata = MessageMetadataEntity();
        expect(metadata.usedTokens, 0);
      });

      test('totalTokens takes precedence over sum', () {
        const metadata = MessageMetadataEntity(
          promptTokens: 30,
          completionTokens: 20,
          totalTokens: 100,
        );
        expect(metadata.usedTokens, 100);
      });
    });

    group('compaction fields', () {
      test('defaults are non-summary with empty range', () {
        const metadata = MessageMetadataEntity();
        expect(metadata.metadataVersion, 1);
        expect(metadata.isCompactionSummary, isFalse);
        expect(metadata.compactionKind, isNull);
        expect(metadata.compactedFromMessageId, isNull);
        expect(metadata.compactedThroughMessageId, isNull);
        expect(metadata.compactedMessageIds, isEmpty);
        expect(metadata.compactionCreatedAt, isNull);
      });

      test('parses compaction summary metadata from JSON', () {
        final metadata = MessageMetadataEntity.fromJsonString('''
          {
            "metadataVersion": 2,
            "isCompactionSummary": true,
            "compactionKind": "auto",
            "compactedFromMessageId": "msg-1",
            "compactedThroughMessageId": "msg-5",
            "compactedMessageIds": ["msg-1", "msg-2", "msg-3", "msg-4", "msg-5"],
            "compactionCreatedAt": "2026-05-03T10:00:00.000Z"
          }
        ''');
        expect(metadata, isNotNull);
        expect(metadata!.isCompactionSummary, isTrue);
        expect(metadata.compactionKind, CompactionKind.auto);
        expect(metadata.compactedFromMessageId, 'msg-1');
        expect(metadata.compactedThroughMessageId, 'msg-5');
        expect(metadata.compactedMessageIds, hasLength(5));
        expect(metadata.compactionCreatedAt, isNotNull);
      });

      test('old rows without compaction fields are non-summary', () {
        final metadata = MessageMetadataEntity.fromJsonString('''
          {"promptTokens": 10, "completionTokens": 5, "totalTokens": 15}
        ''');
        expect(metadata, isNotNull);
        expect(metadata!.isCompactionSummary, isFalse);
        expect(metadata.compactionKind, isNull);
        expect(metadata.compactedMessageIds, isEmpty);
      });

      test('no tool metadata invariant for compaction summaries', () {
        const metadata = MessageMetadataEntity(
          isCompactionSummary: true,
          compactionKind: CompactionKind.manual,
          compactedFromMessageId: 'msg-1',
          compactedThroughMessageId: 'msg-3',
          compactedMessageIds: ['msg-1', 'msg-2', 'msg-3'],
        );
        expect(metadata.toolCalls, isEmpty);
        expect(metadata.isCompactionSummary, isTrue);
      });

      test('serializes and deserializes round-trip', () {
        final now = DateTime(2026, 5, 3);
        final metadata = MessageMetadataEntity(
          metadataVersion: 2,
          isCompactionSummary: true,
          compactionKind: CompactionKind.auto,
          compactedFromMessageId: 'a',
          compactedThroughMessageId: 'b',
          compactedMessageIds: ['a', 'b'],
          compactionCreatedAt: now,
        );
        final json = metadata.toJson();
        final restored = MessageMetadataEntity.fromJson(json);
        expect(restored.isCompactionSummary, isTrue);
        expect(restored.compactionKind, CompactionKind.auto);
        expect(restored.compactedMessageIds, ['a', 'b']);
        expect(restored.metadataVersion, 2);
      });
    });
  });

  group('MessageEntity', () {
    final now = DateTime.now();
    final validMessage = MessageEntity(
      id: 'msg_1',
      conversationId: 'conv_1',
      content: 'Hello',
      messageType: MessageType.text,
      isUser: true,
      status: MessageStatus.sent,
      createdAt: now,
      updatedAt: now,
    );

    test('hasValidContent true when content is not empty', () {
      expect(validMessage.hasValidContent, isTrue);
    });

    test('hasValidContent false when content is empty', () {
      final empty = MessageEntity(
        id: 'msg_2',
        conversationId: 'conv_1',
        content: '',
        messageType: MessageType.text,
        isUser: true,
        status: MessageStatus.sent,
        createdAt: now,
        updatedAt: now,
      );
      expect(empty.hasValidContent, isFalse);
    });

    test('isValid true when content and conversationId are valid', () {
      expect(validMessage.isValid, isTrue);
    });

    test('isValid false when conversationId is empty', () {
      final invalid = MessageEntity(
        id: 'msg_3',
        conversationId: '',
        content: 'Hello',
        messageType: MessageType.text,
        isUser: true,
        status: MessageStatus.sent,
        createdAt: now,
        updatedAt: now,
      );
      expect(invalid.isValid, isFalse);
    });

    test('isValid false when content is empty', () {
      final invalid = MessageEntity(
        id: 'msg_4',
        conversationId: 'conv_1',
        content: '',
        messageType: MessageType.text,
        isUser: true,
        status: MessageStatus.sent,
        createdAt: now,
        updatedAt: now,
      );
      expect(invalid.isValid, isFalse);
    });
  });

  group('MessageToCreate', () {
    test('hasValidContent true when content is not empty', () {
      const msg = MessageToCreate(
        conversationId: 'conv_1',
        content: 'Hello',
        messageType: MessageType.text,
        isUser: true,
        status: MessageStatus.sent,
      );
      expect(msg.hasValidContent, isTrue);
    });

    test('hasValidContent false when content is empty', () {
      const msg = MessageToCreate(
        conversationId: 'conv_1',
        content: '',
        messageType: MessageType.text,
        isUser: true,
        status: MessageStatus.sending,
      );
      expect(msg.hasValidContent, isFalse);
    });

    test(
      'isValid true when hasValidContent and conversationId is not empty',
      () {
        const msg = MessageToCreate(
          conversationId: 'conv_1',
          content: 'Hello',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        );
        expect(msg.isValid, isTrue);
      },
    );

    test('isValid false when conversationId is empty', () {
      const msg = MessageToCreate(
        conversationId: '',
        content: 'Hello',
        messageType: MessageType.text,
        isUser: true,
        status: MessageStatus.sending,
      );
      expect(msg.isValid, isFalse);
    });
  });

  group('MessagePatch', () {
    test('isValid true when at least one field is set', () {
      const patch = MessagePatch(content: 'updated');
      expect(patch.isValid, isTrue);
    });

    test('isValid true when metadata is set', () {
      const patch = MessagePatch(
        metadata: MessageMetadataEntity(totalTokens: 10),
      );
      expect(patch.isValid, isTrue);
    });

    test('isValid true when status is set', () {
      const patch = MessagePatch(status: MessageStatus.sent);
      expect(patch.isValid, isTrue);
    });

    test('isValid false when all fields are null', () {
      const patch = MessagePatch();
      expect(patch.isValid, isFalse);
    });
  });
}
