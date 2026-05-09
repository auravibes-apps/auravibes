import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/usecases/estimate_conversation_prompt_tokens_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

MessageEntity _makeMessage({
  String id = 'msg-1',
  String content = '',
  bool isUser = true,
  MessageMetadataEntity? metadata,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return MessageEntity(
    id: id,
    conversationId: 'conv-1',
    content: content,
    messageType: MessageType.text,
    isUser: isUser,
    status: MessageStatus.sent,
    metadata: metadata,
    createdAt: createdAt ?? DateTime(2026),
    updatedAt: updatedAt ?? DateTime(2026),
  );
}

void main() {
  late MockMessageRepository mockRepository;
  late EstimateConversationPromptTokensUsecase usecase;

  setUp(() {
    mockRepository = MockMessageRepository();
    usecase = EstimateConversationPromptTokensUsecase(
      messageRepository: mockRepository,
    );
  });

  test('estimates token count from message metadata usedTokens', () async {
    when(
      () => mockRepository.getMessagesByConversation('conv-1'),
    ).thenAnswer(
      (_) async => [
        _makeMessage(
          content: 'hello world',
        ),
        _makeMessage(
          id: 'msg-2',
          isUser: false,
          content: 'response',
          metadata: const MessageMetadataEntity(totalTokens: 5000),
        ),
      ],
    );

    final estimate = await usecase(
      conversationId: 'conv-1',
      selectedModelId: 'model-1',
      selectedProviderId: 'provider-1',
      maxOutputTokens: 4096,
      contextLimit: 128000,
    );

    expect(estimate.estimatedPromptTokens, 5000);
    expect(estimate.remainingTokens, 128000 - 5000);
    expect(estimate.usagePercentage, closeTo(3.9, 0.1));
  });

  test('falls back to character-based estimation when no usage data', () async {
    when(
      () => mockRepository.getMessagesByConversation('conv-1'),
    ).thenAnswer(
      (_) async => [
        _makeMessage(content: 'hello world'),
      ],
    );

    final estimate = await usecase(
      conversationId: 'conv-1',
      selectedModelId: 'model-1',
      selectedProviderId: 'provider-1',
      maxOutputTokens: 4096,
      contextLimit: 128000,
    );

    expect(estimate.estimatedPromptTokens, 3); // 11 chars / 4 = 2.75 → 3
  });

  test(
    'includes tool call arguments and responses in character estimation',
    () async {
      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer(
        (_) async => [
          _makeMessage(
            id: 'msg-2',
            isUser: false,
            metadata: const MessageMetadataEntity(
              toolCalls: [
                MessageToolCallEntity(
                  id: 'tc-1',
                  name: 'read_file',
                  argumentsRaw: '{"path":"/tmp"}',
                ),
              ],
            ),
          ),
        ],
      );

      final estimate = await usecase(
        conversationId: 'conv-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
        contextLimit: 128000,
      );

      // 16 chars of arguments / 4 = 4
      expect(estimate.estimatedPromptTokens, 4);
    },
  );

  test('handles null contextLimit gracefully', () async {
    when(
      () => mockRepository.getMessagesByConversation('conv-1'),
    ).thenAnswer(
      (_) async => [
        _makeMessage(content: 'test'),
      ],
    );

    final estimate = await usecase(
      conversationId: 'conv-1',
      selectedModelId: 'model-1',
      selectedProviderId: 'provider-1',
      maxOutputTokens: 4096,
    );

    expect(estimate.remainingTokens, isNull);
    expect(estimate.usagePercentage, isNull);
    expect(estimate.estimatedPromptTokens, greaterThan(0));
  });

  test('uses the latest message with usedTokens, not the sum', () async {
    when(
      () => mockRepository.getMessagesByConversation('conv-1'),
    ).thenAnswer(
      (_) async => [
        _makeMessage(
          id: 'old',
          content: 'old message',
          metadata: const MessageMetadataEntity(totalTokens: 100),
        ),
        _makeMessage(
          id: 'newer',
          isUser: false,
          content: 'newer',
          metadata: const MessageMetadataEntity(totalTokens: 8000),
        ),
      ],
    );

    final estimate = await usecase(
      conversationId: 'conv-1',
      selectedModelId: 'model-1',
      selectedProviderId: 'provider-1',
      maxOutputTokens: 4096,
      contextLimit: 128000,
    );

    expect(estimate.estimatedPromptTokens, 8000);
  });

  test(
    'skips zero-value usedTokens and falls back to character count',
    () async {
      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer(
        (_) async => [
          _makeMessage(
            isUser: false,
            content: 'short',
            metadata: const MessageMetadataEntity(totalTokens: 0),
          ),
        ],
      );

      final estimate = await usecase(
        conversationId: 'conv-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
        contextLimit: 128000,
      );

      // 5 chars / 4 = 1.25 → 2
      expect(estimate.estimatedPromptTokens, 2);
    },
  );
}
