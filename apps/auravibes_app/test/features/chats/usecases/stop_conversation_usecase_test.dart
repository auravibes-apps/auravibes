import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_send_queue_notifier.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/send_queue_runtime_provider.dart';
import 'package:auravibes_app/features/chats/usecases/stop_conversation_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'stop_conversation_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  group('StopConversationUsecase', () {
    late MockMessageRepository messageRepository;
    late AgentCancellationRuntime agentCancellationRuntime;
    late ProviderContainer container;
    late StopConversationUsecase usecase;

    setUp(() {
      messageRepository = MockMessageRepository();
      agentCancellationRuntime = AgentCancellationRuntime()
        ..start('conversation-1');
      container = ProviderContainer();
      final queueNotifier = container.read(
        conversationSendQueueProvider.notifier,
      );
      usecase = StopConversationUsecase(
        agentCancellationRuntime: agentCancellationRuntime,
        sendQueueRuntime: ConversationSendQueueRuntime(
          enqueue: queueNotifier.enqueue,
          dequeueAll: queueNotifier.dequeueAll,
          clear: queueNotifier.clearAll,
        ),
        messageRepository: messageRepository,
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'requests cancellation, clears queue, and stops pending tools',
      () async {
        container
            .read(conversationSendQueueProvider.notifier)
            .enqueue(
              conversationId: 'conversation-1',
              content: 'Queued follow-up',
            );
        final message = MessageEntity(
          id: 'assistant-1',
          conversationId: 'conversation-1',
          content: 'assistant',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tool-1',
                name: 'built_in_calc_calculator',
                argumentsRaw: '{"input":"1+1"}',
              ),
            ],
          ),
        );

        when(
          messageRepository.getMessagesByConversation('conversation-1'),
        ).thenAnswer((_) async => [message]);
        when(
          messageRepository.patchMessage('assistant-1', any),
        ).thenAnswer((_) async => message);

        await usecase.call(conversationId: 'conversation-1');

        expect(
          agentCancellationRuntime.isCancellationRequested('conversation-1'),
          isTrue,
        );
        expect(
          container
              .read(conversationSendQueueProvider.notifier)
              .peek('conversation-1'),
          isNull,
        );
        final patch =
            verify(
                  messageRepository.patchMessage('assistant-1', captureAny),
                ).captured.single
                as MessagePatch;
        expect(
          patch.metadata?.toolCalls.single.resultStatus,
          ToolCallResultStatus.stoppedByUser,
        );
      },
    );
  });
}
