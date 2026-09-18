import 'dart:async';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AgentIterationContext, AgentIterationDecision;
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
          messageType: .text,
          isUser: true,
          status: .sending,
          createdAt: .new(2025),
          updatedAt: .new(2025),
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
        draft: const ChatDraft(text: 'Hello'),
      );

      expect(
        () => verify(
          () => fixture.runAgentIterationUsecase.call(
            conversationId: 'conversation-1',
            context: const AgentIterationContext(
              origin: .userMessage,
              ackMessageIds: ['user-1'],
            ),
          ),
        ).called(1),
        returnsNormally,
      );
    });

    for (final status in [MessageStatus.error, MessageStatus.unfinished]) {
      test('retries the existing $status user message', () async {
        final message = MessageEntity(
          id: 'failed-user',
          conversationId: 'conversation-1',
          content: '',
          messageType: .text,
          isUser: true,
          status: status,
          createdAt: .new(2025),
          updatedAt: .new(2025),
          attachments: [
            MessageAttachmentEntity(
              id: 'attachment-1',
              messageId: 'failed-user',
              localPath: '/tmp/image.png',
              fileName: 'image.png',
              displayName: 'image.png',
              mimeType: 'image/png',
              modality: .image,
              sizeBytes: 10,
              createdAt: .new(2025),
              updatedAt: .new(2025),
            ),
          ],
        );
        when(() => fixture.messageRepository.getMessageById('failed-user'))
            .thenAnswer((_) async => message);

        await fixture.usecase.retryUserMessage(
          conversationId: 'conversation-1',
          messageId: 'failed-user',
        );

        verify(
          () => fixture.runAgentIterationUsecase.call(
            conversationId: 'conversation-1',
            context: const AgentIterationContext(
              origin: .manualContinue,
              ackMessageIds: ['failed-user'],
            ),
          ),
        ).called(1);
        final _ = verifyNever(
          () => fixture.messageRepository.createMessage(any()),
        );
      });
    }

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
          draft: const ChatDraft(text: 'Queued hello'),
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

    test('sendFirstMessage returns after persisting user message', () async {
      final completer = Completer<void>();
      final errors = <Object>[];
      when(
        () => fixture.runAgentIterationUsecase.call(
          conversationId: any(named: 'conversationId'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {
        await completer.future;

        return AgentIterationDecision.done;
      });

      await fixture.usecase.sendFirstMessage(
        conversationId: 'conversation-1',
        draft: const ChatDraft(text: 'Hello'),
        onContinueError: (error, stackTrace) => errors.add(error),
      );

      verify(() => fixture.messageRepository.createMessage(any())).called(1);
      verify(
        () => fixture.runAgentIterationUsecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: .userMessage,
            ackMessageIds: ['user-1'],
          ),
        ),
      ).called(1);
      expect(errors, isEmpty);

      completer.complete();
    });
  });
}

class _SendMessageUsecaseFixture({
  required final MockAgentLoopRunner runAgentIterationUsecase,
  required final MockMessageRepository messageRepository,
  required final MockGetConversationBusyStateUsecase
  getConversationBusyStateUsecase,
  required final ProviderContainer container,
  required final SendMessageUsecase usecase,
}) {
  factory create() {
    final runAgentIterationUsecase = MockAgentLoopRunner();
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
      usecase: .new(
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

  var _isDisposed = false;

  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    container.dispose();
  }
}
