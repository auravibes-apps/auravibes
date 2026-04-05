import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/usecases/get_conversation_busy_state_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'get_conversation_busy_state_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  group('GetConversationBusyStateUsecase', () {
    late MockMessageRepository messageRepository;
    late ProviderContainer container;
    late GetConversationBusyStateUsecase usecase;

    setUp(() {
      messageRepository = MockMessageRepository();
      container = ProviderContainer();
      usecase = GetConversationBusyStateUsecase(
        messageRepository: messageRepository,
        conversationStreamingNotifier: container.read(
          conversationStreamingProvider.notifier,
        ),
      );

      when(messageRepository.getMessagesByConversation(any)).thenAnswer(
        (_) async => const [],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('returns busy when the conversation is actively streaming', () async {
      container
          .read(conversationStreamingProvider.notifier)
          .start(
            'conversation-1',
          );

      final result = await usecase.call(conversationId: 'conversation-1');

      expect(result.isStreaming, isTrue);
      expect(result.hasPendingTools, isFalse);
      expect(result.isBusy, isTrue);
    });

    test(
      'returns busy when the latest assistant message has pending tools',
      () async {
        when(
          messageRepository.getMessagesByConversation('conversation-1'),
        ).thenAnswer(
          (_) async => [
            _message(
              id: 'assistant-1',
              isUser: false,
              metadata: const MessageMetadataEntity(
                toolCalls: [
                  MessageToolCallEntity(
                    id: 'tool-1',
                    name: 'weather.lookup',
                    argumentsRaw: '{}',
                  ),
                ],
              ),
            ),
          ],
        );

        final result = await usecase.call(conversationId: 'conversation-1');

        expect(result.isStreaming, isFalse);
        expect(result.hasPendingTools, isTrue);
        expect(result.isBusy, isTrue);
      },
    );

    test(
      'returns not busy when there is no stream and no pending tools',
      () async {
        when(
          messageRepository.getMessagesByConversation('conversation-1'),
        ).thenAnswer(
          (_) async => [
            _message(
              id: 'assistant-1',
              isUser: false,
              metadata: const MessageMetadataEntity(
                toolCalls: [
                  MessageToolCallEntity(
                    id: 'tool-1',
                    name: 'weather.lookup',
                    argumentsRaw: '{}',
                    resultStatus: ToolCallResultStatus.success,
                  ),
                ],
              ),
            ),
          ],
        );

        final result = await usecase.call(conversationId: 'conversation-1');

        expect(result.isStreaming, isFalse);
        expect(result.hasPendingTools, isFalse);
        expect(result.isBusy, isFalse);
      },
    );
  });
}

MessageEntity _message({
  required String id,
  required bool isUser,
  MessageMetadataEntity? metadata,
}) {
  return MessageEntity(
    id: id,
    conversationId: 'conversation-1',
    content: isUser ? 'Hi' : 'Hello',
    messageType: MessageType.text,
    isUser: isUser,
    status: MessageStatus.sent,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
    metadata: metadata,
  );
}
