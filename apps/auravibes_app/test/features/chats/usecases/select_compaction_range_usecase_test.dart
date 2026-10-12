import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/usecases/select_compaction_range_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import 'compaction_context_fixture.dart';

void main() {
  const usecase = SelectCompactionRangeUsecase();

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
      createdAt: .new(2026),
      updatedAt: .new(2026),
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

    test('selects fork context within recent and output reserve budgets', () {
      final transcript = CompactionContextFixture();
      const model = ApiModelEntity(
        modelProvider: 'test',
        id: 'offline-model',
        name: 'Offline test model',
        limitContext: 64,
        limitOutput: 32,
        modalitiesInput: [],
        modalitiesOutput: [],
      );
      const reserveTokens = 16;
      const keepRecentTokens = 20;
      const override = CompactionModelOverride(
        reserveTokens: reserveTokens,
        keepRecentTokens: keepRecentTokens,
      );

      final range = usecase(
        transcript.messages,
        apiModel: model,
        modelOverride: override,
      );

      expect(range, isNotNull);
      final selectedRange = range ?? fail('Expected range to be non-null');
      expect(selectedRange.messageIds, [
        'parent-01-constraint',
        'parent-02-decision',
        'parent-03-tool-exchange',
        'parent-04-pending-task',
        transcript.forkThroughMessageId,
        'child-01-continuation',
        'child-02-decision',
      ]);
      expect(selectedRange.keptTailMessageIds, [
        'child-03-current-request',
        'child-04-latest-response',
      ]);
      expect(
        selectedRange.messageIds,
        isNot(contains(transcript.parentMessageAfterForkBoundary.id)),
      );

      final retainedTail = transcript.messages.where(
        (message) => selectedRange.keptTailMessageIds.contains(message.id),
      );
      final retainedTailTokens = _estimatedTokenCount(retainedTail);
      expect(retainedTailTokens, greaterThanOrEqualTo(keepRecentTokens));
      expect(
        retainedTailTokens + reserveTokens,
        lessThanOrEqualTo(model.limitContext),
      );
    });

    test(
      'returns no range when recent tool output exceeds the context budget',
      () {
        final messages = [
          _makeMessage(content: 'Earlier request.'),
          _makeMessage(id: 'msg-2', isUser: false, content: 'Earlier answer.'),
          _makeMessage(id: 'msg-3', content: 'Recent request.'),
          _makeMessage(
            id: 'msg-4',
            isUser: false,
            content: '',
            metadata: .new(
              toolCalls: [
                MessageToolCallEntity(
                  id: 'large-recent-result',
                  name: 'read_large_file',
                  argumentsRaw: '{"path":"local.txt"}',
                  responseRaw: List.filled(400, 'x').join(),
                  resultStatus: .success,
                ),
              ],
            ),
          ),
        ];

        final range = usecase(
          messages,
          apiModel: const .new(
            modelProvider: 'test',
            id: 'offline-model',
            name: 'Offline test model',
            limitContext: 64,
            limitOutput: 32,
            modalitiesInput: [],
            modalitiesOutput: [],
          ),
          modelOverride: const .new(reserveTokens: 16),
        );

        expect(range, isNull);
      },
    );

    test('excludes error messages from compactable range', () {
      final messages = [
        _makeMessage(status: .error),
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
        _makeMessage(status: .sending),
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
        _makeMessage(metadata: const MessageMetadataEntity()),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(
          id: 'msg-4',
          isUser: false,
          messageType: .system,
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
                resultStatus: .success,
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

int _estimatedTokenCount(Iterable<MessageEntity> messages) {
  num characterCount = 0;
  for (final message in messages) {
    characterCount += message.content.length;
    for (final toolCall
        in message.metadata?.toolCalls ?? const <MessageToolCallEntity>[]) {
      characterCount += toolCall.argumentsRaw.length;
      characterCount += toolCall.getResponseForAI().length;
    }
  }

  return (characterCount / 4).ceil();
}
