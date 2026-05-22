import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/usecases/select_prompt_messages_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late MockMessageRepository mockRepository;
  late SelectPromptMessagesUsecase usecase;

  setUp(() {
    mockRepository = MockMessageRepository();
    usecase = SelectPromptMessagesUsecase(messageRepository: mockRepository);
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

  group('SelectPromptMessagesUsecase', () {
    test(
      'returns all eligible messages when no compaction summary exists',
      () async {
        final messages = [
          _makeMessage(),
          _makeMessage(id: 'msg-2', isUser: false),
          _makeMessage(id: 'msg-3'),
        ];

        when(
          () => mockRepository.getMessagesByConversation('conv-1'),
        ).thenAnswer((_) async => messages);

        final result = await usecase('conv-1');

        expect(result.length, 3);
        expect(result[0].id, 'msg-1');
      },
    );

    test(
      'returns summary and subsequent messages when summary exists',
      () async {
        final messages = [
          _makeMessage(),
          _makeMessage(id: 'msg-2', isUser: false),
          _makeMessage(
            id: 'msg-summary',
            isUser: false,
            messageType: MessageType.system,
            metadata: const MessageMetadataEntity(
              isCompactionSummary: true,
              compactedMessageIds: ['msg-1', 'msg-2'],
            ),
          ),
          _makeMessage(id: 'msg-4'),
          _makeMessage(id: 'msg-5', isUser: false),
        ];

        when(
          () => mockRepository.getMessagesByConversation('conv-1'),
        ).thenAnswer((_) async => messages);

        final result = await usecase('conv-1');

        expect(result.length, 3);
        expect(result[0].id, 'msg-summary');
        expect(result[1].id, 'msg-4');
        expect(result[2].id, 'msg-5');
      },
    );

    test('does not include pre-summary messages', () async {
      final messages = [
        _makeMessage(),
        _makeMessage(
          id: 'msg-summary',
          isUser: false,
          messageType: MessageType.system,
          metadata: const MessageMetadataEntity(
            isCompactionSummary: true,
            compactedMessageIds: ['msg-1'],
          ),
        ),
        _makeMessage(id: 'msg-3'),
      ];

      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);

      final result = await usecase('conv-1');

      expect(result.length, 2);
      expect(result.any((m) => m.id == 'msg-1'), isFalse);
    });

    test('uses latest summary when multiple summaries exist', () async {
      final messages = [
        _makeMessage(
          id: 'summary-1',
          isUser: false,
          messageType: MessageType.system,
          metadata: const MessageMetadataEntity(isCompactionSummary: true),
        ),
        _makeMessage(id: 'msg-2'),
        _makeMessage(
          id: 'summary-2',
          isUser: false,
          messageType: MessageType.system,
          metadata: const MessageMetadataEntity(
            isCompactionSummary: true,
            compactedMessageIds: ['summary-1', 'msg-2'],
          ),
        ),
        _makeMessage(id: 'msg-4'),
      ];

      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);

      final result = await usecase('conv-1');

      expect(result.length, 2);
      expect(result[0].id, 'summary-2');
    });

    test(
      'includes messages of all statuses including error and sending',
      () async {
        final messages = [
          _makeMessage(
            id: 'err-1',
            status: MessageStatus.error,
          ),
          _makeMessage(
            id: 'send-1',
            status: MessageStatus.sending,
          ),
          _makeMessage(id: 'msg-2'),
          _makeMessage(id: 'msg-3', isUser: false),
        ];

        when(
          () => mockRepository.getMessagesByConversation('conv-1'),
        ).thenAnswer((_) async => messages);

        final result = await usecase('conv-1');

        expect(result.length, 4);
        expect(result[0].id, 'err-1');
      },
    );

    test('no duplicated compacted predecessors in result', () async {
      final messages = [
        _makeMessage(id: 'old-1'),
        _makeMessage(id: 'old-2', isUser: false),
        _makeMessage(
          id: 'summary',
          isUser: false,
          messageType: MessageType.system,
          metadata: const MessageMetadataEntity(
            isCompactionSummary: true,
            compactedMessageIds: ['old-1', 'old-2'],
          ),
        ),
        _makeMessage(id: 'new-1'),
      ];

      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);

      final result = await usecase('conv-1');

      expect(result.length, 2);
      expect(result[0].id, 'summary');
      expect(result[1].id, 'new-1');
    });

    test(
      'uses compactedThroughMessageId boundary to keep only tail',
      () async {
        final messages = [
          _makeMessage(id: 'old-1'),
          _makeMessage(id: 'old-2', isUser: false),
          _makeMessage(id: 'old-3'),
          _makeMessage(id: 'kept-1'),
          _makeMessage(id: 'kept-2', isUser: false),
          _makeMessage(
            id: 'summary',
            isUser: false,
            messageType: MessageType.system,
            metadata: const MessageMetadataEntity(
              isCompactionSummary: true,
              compactedFromMessageId: 'old-1',
              compactedThroughMessageId: 'old-3',
              compactedMessageIds: ['old-1', 'old-2', 'old-3'],
            ),
          ),
        ];

        when(
          () => mockRepository.getMessagesByConversation('conv-1'),
        ).thenAnswer((_) async => messages);

        final result = await usecase('conv-1');

        expect(result.length, 3);
        expect(result[0].id, 'summary');
        expect(result[1].id, 'kept-1');
        expect(result[2].id, 'kept-2');
      },
    );

    test(
      'multiple compactions do not resurrect pre-boundary messages',
      () async {
        final messages = [
          _makeMessage(id: 'a-1'),
          _makeMessage(id: 'a-2', isUser: false),
          _makeMessage(
            id: 'summary-1',
            isUser: false,
            messageType: MessageType.system,
            metadata: const MessageMetadataEntity(
              isCompactionSummary: true,
              compactedThroughMessageId: 'a-2',
              compactedMessageIds: ['a-1', 'a-2'],
            ),
          ),
          _makeMessage(id: 'b-1'),
          _makeMessage(
            id: 'summary-2',
            isUser: false,
            messageType: MessageType.system,
            metadata: const MessageMetadataEntity(
              isCompactionSummary: true,
              compactedThroughMessageId: 'b-1',
              compactedMessageIds: ['summary-1', 'b-1'],
            ),
          ),
        ];

        when(
          () => mockRepository.getMessagesByConversation('conv-1'),
        ).thenAnswer((_) async => messages);

        final result = await usecase('conv-1');

        expect(result.length, 1);
        expect(result[0].id, 'summary-2');
        expect(result.any((m) => m.id == 'a-1'), isFalse);
        expect(result.any((m) => m.id == 'a-2'), isFalse);
        expect(result.any((m) => m.id == 'summary-1'), isFalse);
        expect(result.any((m) => m.id == 'b-1'), isFalse);
      },
    );

    test(
      'falls back to sublist when compactedThroughMessageId is missing',
      () async {
        final messages = [
          _makeMessage(id: 'old-1'),
          _makeMessage(
            id: 'summary',
            isUser: false,
            messageType: MessageType.system,
            metadata: const MessageMetadataEntity(
              isCompactionSummary: true,
              compactedMessageIds: ['old-1'],
            ),
          ),
          _makeMessage(id: 'kept-1'),
        ];

        when(
          () => mockRepository.getMessagesByConversation('conv-1'),
        ).thenAnswer((_) async => messages);

        final result = await usecase('conv-1');

        expect(result.length, 2);
        expect(result[0].id, 'summary');
        expect(result[1].id, 'kept-1');
      },
    );

    test('drops assistant messages before the first user in tail', () async {
      final messages = [
        _makeMessage(id: 'old-1'),
        _makeMessage(
          id: 'summary',
          isUser: false,
          messageType: MessageType.system,
          metadata: const MessageMetadataEntity(
            isCompactionSummary: true,
            compactedThroughMessageId: 'old-1',
            compactedMessageIds: ['old-1'],
          ),
        ),
        _makeMessage(id: 'assistant', isUser: false),
        _makeMessage(id: 'latest-user'),
      ];

      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);

      final result = await usecase('conv-1');

      expect(result.length, 2);
      expect(result[0].id, 'summary');
      expect(result[1].id, 'latest-user');
      expect(result.any((m) => m.id == 'assistant'), isFalse);
    });

    test('returns only summary when no user exists in tail', () async {
      final messages = [
        _makeMessage(
          id: 'summary',
          isUser: false,
          messageType: MessageType.system,
          metadata: const MessageMetadataEntity(
            isCompactionSummary: true,
            compactedThroughMessageId: 'assistant',
            compactedMessageIds: ['assistant'],
          ),
        ),
        _makeMessage(id: 'model-1', isUser: false),
        _makeMessage(id: 'model-2', isUser: false),
      ];

      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);

      final result = await usecase('conv-1');

      expect(result.length, 1);
      expect(result[0].id, 'summary');
    });

    test('preserves tool messages after first user in tail', () async {
      final messages = [
        _makeMessage(id: 'old-1'),
        _makeMessage(
          id: 'summary',
          isUser: false,
          messageType: MessageType.system,
          metadata: const MessageMetadataEntity(
            isCompactionSummary: true,
            compactedThroughMessageId: 'old-1',
            compactedMessageIds: ['old-1'],
          ),
        ),
        _makeMessage(id: 'assistant', isUser: false),
        _makeMessage(id: 'user-msg'),
        _makeMessage(id: 'tool-result', isUser: false),
      ];

      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);

      final result = await usecase('conv-1');

      expect(result.length, 3);
      expect(result[0].id, 'summary');
      expect(result[1].id, 'user-msg');
      expect(result[2].id, 'tool-result');
    });
  });
}
