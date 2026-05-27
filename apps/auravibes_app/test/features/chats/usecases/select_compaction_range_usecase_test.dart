// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/usecases/select_compaction_range_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SelectCompactionRangeUsecase usecase;

  setUp(() {
    usecase = const SelectCompactionRangeUsecase();
  });

  MessageEntity _makeMessage({
    String id = 'msg-1',
    String conversationId = 'conv-1',
    String content = 'Hello',
    bool isUser = true,
    MessageType messageType = MessageType.text,
    MessageStatus status = MessageStatus.sent,
    MessageMetadataEntity? metadata,
  }) {
    return MessageEntity(
      id: id,
      conversationId: conversationId,
      content: content,
      messageType: messageType,
      isUser: isUser,
      status: status,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      metadata: metadata,
    );
  }

  group('SelectCompactionRangeUsecase', () {
    test('returns null for fewer than 3 messages', () {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
      ];

      final range = usecase(messages);
      expect(range, isNull);
    });

    test('returns valid range for safe messages', () {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      final range = usecase(messages);
      expect(range, isNotNull);
      expect(
        (range ?? fail('Expected range to be non-null')).fromMessageId,
        'msg-1',
      );
      expect(range.keptTailMessageIds, isNotEmpty);
    });

    test('excludes error messages from compactable range', () {
      final messages = [
        _makeMessage(
          status: MessageStatus.error,
        ),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      final range = usecase(messages);
      expect(range, isNotNull);
      expect(
        (range ?? fail('Expected range to be non-null')).messageIds,
        isNot(contains('msg-1')),
      );
    });

    test('excludes sending messages from compactable range', () {
      final messages = [
        _makeMessage(
          status: MessageStatus.sending,
        ),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      final range = usecase(messages);
      expect(range, isNotNull);
      expect(
        (range ?? fail('Expected range to be non-null')).messageIds,
        isNot(contains('msg-1')),
      );
    });

    test('excludes existing compaction summaries', () {
      final messages = [
        _makeMessage(
          metadata: const MessageMetadataEntity(),
        ),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(
          id: 'msg-4',
          isUser: false,
          messageType: MessageType.system,
          metadata: const MessageMetadataEntity(isCompactionSummary: true),
        ),
      ];

      final range = usecase(messages);
      expect(range, isNotNull);
      expect(
        (range ?? fail('Expected range to be non-null')).messageIds,
        isNot(contains('msg-4')),
      );
    });

    test('keeps safe tail starting at latest user message', () {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      final range = usecase(messages);
      expect(range, isNotNull);
      expect(
        (range ?? fail('Expected range to be non-null')).keptTailMessageIds,
        contains('msg-3'),
      );
      expect(range.keptTailMessageIds, contains('msg-4'));
    });

    test('tail excludes assistant before latest user', () {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
      ];

      final range = usecase(messages);
      expect(range, isNotNull);
      expect(
        (range ?? fail('Expected range to be non-null')).keptTailMessageIds,
        contains('msg-3'),
      );
      expect(range.keptTailMessageIds, isNot(contains('msg-2')));
    });

    test('throws CompactionUnsafeException for unresolved tool calls', () {
      final messages = [
        _makeMessage(),
        _makeMessage(
          id: 'msg-2',
          isUser: false,
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tc-1',
                name: 'read_file',
                argumentsRaw: '{}',
              ),
            ],
          ),
        ),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      expect(
        () => usecase(messages),
        throwsA(isA<CompactionUnsafeException>()),
      );
    });

    test('handles resolved tool calls correctly', () {
      final messages = [
        _makeMessage(),
        _makeMessage(
          id: 'msg-2',
          isUser: false,
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tc-1',
                name: 'read_file',
                argumentsRaw: '{}',
                responseRaw: 'file content',
                resultStatus: ToolCallResultStatus.success,
              ),
            ],
          ),
        ),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      final range = usecase(messages);
      expect(range, isNotNull);
    });

    test('excludes pending approval messages from compactable range', () {
      final messages = [
        _makeMessage(),
        _makeMessage(
          id: 'msg-2',
          isUser: false,
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tc-1',
                name: 'delete_file',
                argumentsRaw: '{}',
              ),
            ],
          ),
        ),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      expect(
        () => usecase(messages),
        throwsA(isA<CompactionUnsafeException>()),
      );
    });

    test('returns range with tail starting at latest user for 3 messages', () {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
      ];

      final range = usecase(messages);
      expect(range, isNotNull);
      expect(
        (range ?? fail('Expected range to be non-null')).keptTailMessageIds,
        contains('msg-3'),
      );
      expect(range.keptTailMessageIds, isNot(contains('msg-2')));
    });
  });
}
