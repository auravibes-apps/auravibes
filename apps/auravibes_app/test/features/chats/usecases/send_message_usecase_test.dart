import 'package:auravibes_agent/auravibes_agent.dart'
    show AgentIterationContext, AgentIterationDecision, AgentIterationOrigin;
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import '../../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('SendMessageUsecase', () {
    var fixture = _SendMessageUsecaseFixture.create();

    setUp(() {
      fixture.dispose();
      fixture = _SendMessageUsecaseFixture.create();

      when(() => fixture.messageRepository.createMessage(any())).thenAnswer(
        (_) async => MessageEntity(
          id: 'user-1',
          conversationId: 'conversation-1',
          content: 'Hello',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      );
      when(
        () => fixture.runAgentIterationUsecase.call(
          conversationId: any(named: 'conversationId'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async => AgentIterationDecision.done);
      when(
        () => fixture.getConversationBusyStateUsecase.call(
          conversationId: any(named: 'conversationId'),
        ),
      ).thenAnswer(
        (_) async => const ConversationBusyState(
          isStreaming: false,
          hasPendingTools: false,
        ),
      );
    });

    tearDown(() {
      fixture.dispose();
    });

    test('forwards the created user message id as the ack target', () async {
      await fixture.usecase.call(
        conversationId: 'conversation-1',
        content: 'Hello',
      );

      expect(
        () => verify(
          () => fixture.runAgentIterationUsecase.call(
            conversationId: 'conversation-1',
            context: const AgentIterationContext(
              origin: AgentIterationOrigin.userMessage,
              ackMessageIds: ['user-1'],
            ),
          ),
        ).called(1),
        returnsNormally,
      );
    });

    test(
      'queues the draft instead of persisting when the conversation is busy',
      () async {
        when(
          () => fixture.getConversationBusyStateUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => const ConversationBusyState(
            isStreaming: true,
            hasPendingTools: false,
          ),
        );

        await fixture.usecase.call(
          conversationId: 'conversation-1',
          content: 'Queued hello',
        );

        final _ = verifyNever(
          () => fixture.messageRepository.createMessage(any()),
        );
        final _ = verifyNever(
          () => fixture.runAgentIterationUsecase.call(
            conversationId: any(named: 'conversationId'),
            context: any(named: 'context'),
          ),
        );
        expect(
          fixture.container
              .read(conversationSendQueueProvider.notifier)
              .peek('conversation-1')
              ?.content,
          'Queued hello',
        );
      },
    );
  });
}

class _SendMessageUsecaseFixture {
  _SendMessageUsecaseFixture({
    required this.runAgentIterationUsecase,
    required this.messageRepository,
    required this.getConversationBusyStateUsecase,
    required this.container,
    required this.usecase,
  });

  factory _SendMessageUsecaseFixture.create() {
    final runAgentIterationUsecase = MockAgentService();
    final messageRepository = MockMessageRepository();
    final getConversationBusyStateUsecase =
        MockGetConversationBusyStateUsecase();
    final container = ProviderContainer();
    final queueNotifier = container.read(
      conversationSendQueueProvider.notifier,
    );

    return _SendMessageUsecaseFixture(
      runAgentIterationUsecase: runAgentIterationUsecase,
      messageRepository: messageRepository,
      getConversationBusyStateUsecase: getConversationBusyStateUsecase,
      container: container,
      usecase: SendMessageUsecase(
        continueAgentTurn: runAgentIterationUsecase.call,
        messageRepository: messageRepository,
        getConversationBusyStateUsecase: getConversationBusyStateUsecase,
        sendQueueRuntime: ConversationSendQueueRuntime(
          enqueue: queueNotifier.enqueue,
          dequeueAll: queueNotifier.dequeueAll,
          clear: queueNotifier.clear,
        ),
      ),
    );
  }

  final MockAgentService runAgentIterationUsecase;
  final MockMessageRepository messageRepository;
  final MockGetConversationBusyStateUsecase getConversationBusyStateUsecase;
  final ProviderContainer container;
  final SendMessageUsecase usecase;
  var _isDisposed = false;

  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    container.dispose();
  }
}
