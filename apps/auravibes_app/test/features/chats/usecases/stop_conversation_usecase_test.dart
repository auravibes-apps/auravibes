// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/stop_conversation_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'stop_conversation_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  group('StopConversationUsecase', () {
    final fixture = _StopConversationFixture();

    setUp(fixture.reset);

    tearDown(fixture.dispose);

    test(
      'requests cancellation, clears queue, and stops pending tools',
      () async {
        final _ = fixture.container
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
          fixture.messageRepository.getMessagesByConversation('conversation-1'),
        ).thenAnswer((_) async => [message]);
        when(
          fixture.messageRepository.patchMessage('assistant-1', any),
        ).thenAnswer((_) async => message);

        await fixture.usecase.call(conversationId: 'conversation-1');

        expect(
          fixture.agentCancellationRuntime.isCancellationRequested(
            'conversation-1',
          ),
          isTrue,
        );
        expect(
          fixture.container
              .read(conversationSendQueueProvider.notifier)
              .peek('conversation-1'),
          isNull,
        );
        final patch =
            verify(
                  fixture.messageRepository.patchMessage(
                    'assistant-1',
                    captureAny,
                  ),
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

class _StopConversationFixture {
  MockMessageRepository? _messageRepository;
  AgentCancellationRuntime? _agentCancellationRuntime;
  ProviderContainer? _container;
  StopConversationUsecase? _usecase;

  MockMessageRepository get messageRepository =>
      _messageRepository ?? fail('Fixture not initialized');

  AgentCancellationRuntime get agentCancellationRuntime =>
      _agentCancellationRuntime ?? fail('Fixture not initialized');

  ProviderContainer get container =>
      _container ?? fail('Fixture not initialized');

  StopConversationUsecase get usecase =>
      _usecase ?? fail('Fixture not initialized');

  void reset() {
    final messageRepository = MockMessageRepository();
    final agentCancellationRuntime = AgentCancellationRuntime()
      ..start('conversation-1');
    final container = ProviderContainer();
    final queueNotifier = container.read(
      conversationSendQueueProvider.notifier,
    );
    _messageRepository = messageRepository;
    _agentCancellationRuntime = agentCancellationRuntime;
    _container = container;
    _usecase = StopConversationUsecase(
      agentCancellationRuntime: agentCancellationRuntime,
      sendQueueRuntime: ConversationSendQueueRuntime(
        enqueue: queueNotifier.enqueue,
        dequeueAll: queueNotifier.dequeueAll,
        clear: queueNotifier.clear,
      ),
      messageRepository: messageRepository,
    );
  }

  void dispose() {
    container.dispose();
    _messageRepository = null;
    _agentCancellationRuntime = null;
    _container = null;
    _usecase = null;
  }
}
