import 'dart:async';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/providers/conversation_activity_gate.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/usecases/message_persisted_exception.dart';
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
      final _ = await fixture.usecase.call(
        conversationId: 'conversation-1',
        draft: const ChatDraft(text: 'Hello', languageCode: 'es'),
      );

      expect(
        () => verify(
          () => fixture.runAgentIterationUsecase.call(
            conversationId: 'conversation-1',
            context: any(named: 'context'),
          ),
        ).called(1),
        returnsNormally,
      );
      expect(fixture.callbackLanguageCodes, ['es']);
    });

    test('returns iteration limit decision from foreground send', () async {
      when(
        () => fixture.runAgentIterationUsecase.call(
          conversationId: any(named: 'conversationId'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async => AgentIterationDecision.iterationLimitReached);

      final result = await fixture.usecase.call(
        conversationId: 'conversation-1',
        draft: const ChatDraft(text: 'Hello'),
      );

      expect(result, AgentIterationDecision.iterationLimitReached);
      verify(() => fixture.messageRepository.createMessage(any())).called(1);
    });

    test(
      'distinguishes a continuation failure after message persistence',
      () async {
        when(
          () => fixture.runAgentIterationUsecase.call(
            conversationId: any(named: 'conversationId'),
            context: any(named: 'context'),
          ),
        ).thenThrow(StateError('continuation failed'));

        await expectLater(
          fixture.usecase.call(
            conversationId: 'conversation-1',
            draft: const ChatDraft(text: 'Hello'),
          ),
          throwsA(isA<MessagePersistedException>()),
        );
        verify(() => fixture.messageRepository.createMessage(any())).called(1);
      },
    );

    test('keeps persistence failures eligible for draft restoration', () async {
      when(() => fixture.messageRepository.createMessage(any()))
          .thenThrow(StateError('persistence failed'));

      await expectLater(
        fixture.usecase.call(
          conversationId: 'conversation-1',
          draft: const ChatDraft(text: 'Hello'),
        ),
        throwsA(isA<StateError>()),
      );
      final _ = verifyNever(
        () => fixture.runAgentIterationUsecase.call(
          conversationId: any(named: 'conversationId'),
          context: any(named: 'context'),
        ),
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

        final _ = await fixture.usecase.retryUserMessage(
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
        expect(fixture.callbackLanguageCodes, ['en']);
        final _ = verifyNever(
          () => fixture.messageRepository.createMessage(any()),
        );
      });
    }

    test(
      'preserves the requested locale when retrying a user message',
      () async {
        final message = MessageEntity(
          id: 'failed-user',
          conversationId: 'conversation-1',
          content: 'Original prompt',
          messageType: .text,
          isUser: true,
          status: .unfinished,
          createdAt: .new(2025),
          updatedAt: .new(2025),
        );
        when(() => fixture.messageRepository.getMessageById(message.id))
            .thenAnswer((_) async => message);

        final _ = await fixture.usecase.retryUserMessage(
          conversationId: 'conversation-1',
          messageId: message.id,
          languageCode: 'es',
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
        expect(fixture.callbackLanguageCodes, ['es']);
      },
    );

    test(
      'does not dispatch a retry for a persisted non-retryable failure',
      () async {
        final message = MessageEntity(
          id: 'auth-failure',
          conversationId: 'conversation-1',
          content: 'Original prompt',
          messageType: .text,
          isUser: true,
          status: .error,
          createdAt: .new(2025),
          updatedAt: .new(2025),
          metadata: const MessageMetadataEntity(
            modelMetadata: {
              'providerError': true,
              'providerRecovery': {
                'classification': 'authentication',
                'retryable': false,
              },
            },
          ),
        );
        when(() => fixture.messageRepository.getMessageById(message.id))
            .thenAnswer((_) async => message);

        await expectLater(
          fixture.usecase.retryUserMessage(
            conversationId: 'conversation-1',
            messageId: message.id,
          ),
          throwsA(isA<StateError>()),
        );
        final _ = verifyNever(
          () => fixture.runAgentIterationUsecase.call(
            conversationId: any(named: 'conversationId'),
            context: any(named: 'context'),
          ),
        );
      },
    );

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

        final _ = await fixture.usecase.call(
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

    test(
      'holds the conversation activity gate while checking busy state',
      () async {
        final busyCheckStarted = Completer<void>();
        final releaseBusyCheck = Completer<ConversationBusyState>();
        when(
          () => fixture.getConversationBusyStateUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer((_) {
          busyCheckStarted.complete();

          return releaseBusyCheck.future;
        });

        final sendFuture = fixture.usecase.call(
          conversationId: 'conversation-1',
          draft: const ChatDraft(text: 'Hello'),
        );
        await busyCheckStarted.future;

        final gate = fixture.container.read(conversationActivityGateProvider);
        expect(gate.tryBeginCheckpointRestore('conversation-1'), isFalse);

        releaseBusyCheck.complete(
          const ConversationBusyState(
            isStreaming: false,
            hasPendingTools: false,
          ),
        );
        final _ = await sendFuture;
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
        draft: const ChatDraft(text: 'Hello', languageCode: 'es'),
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
      expect(fixture.callbackLanguageCodes, ['es']);
      expect(errors, isEmpty);

      completer.complete();
    });

    test('reports an agent stop from a first message', () async {
      final agentStopReported = Completer<void>();
      when(
        () => fixture.runAgentIterationUsecase.call(
          conversationId: any(named: 'conversationId'),
          context: any(named: 'context'),
        ),
      ).thenAnswer(
        (_) async => AgentIterationDecision.repeatedToolLoopDetected,
      );

      await fixture.usecase.sendFirstMessage(
        conversationId: 'conversation-1',
        draft: const ChatDraft(text: 'Hello'),
        onContinueError: (error, stackTrace) =>
            fail('Unexpected continuation error: $error'),
        onAgentStop: (conversationId, decision) {
          expect(conversationId, 'conversation-1');
          expect(decision, AgentIterationDecision.repeatedToolLoopDetected);
          agentStopReported.complete();
        },
      );
      await agentStopReported.future;
    });
  });
}

class _SendMessageUsecaseFixture({
  required final MockAgentLoopRunner runAgentIterationUsecase,
  required final List<String?> callbackLanguageCodes,
  required final MockMessageRepository messageRepository,
  required final MockGetConversationBusyStateUsecase
  getConversationBusyStateUsecase,
  required final ProviderContainer container,
  required final SendMessageUsecase usecase,
}) {
  factory create() {
    final runAgentIterationUsecase = MockAgentLoopRunner();
    final callbackLanguageCodes = <String?>[];
    final messageRepository = MockMessageRepository();
    final getConversationBusyStateUsecase =
        MockGetConversationBusyStateUsecase();
    final container = ProviderContainer();
    final queueNotifier = container.read(
      conversationSendQueueProvider.notifier,
    );

    return _SendMessageUsecaseFixture(
      runAgentIterationUsecase: runAgentIterationUsecase,
      callbackLanguageCodes: callbackLanguageCodes,
      messageRepository: messageRepository,
      getConversationBusyStateUsecase: getConversationBusyStateUsecase,
      container: container,
      usecase: .new(
        continueAgentTurn:
            ({required conversationId, required context, languageCode}) {
              callbackLanguageCodes.add(languageCode);

              return runAgentIterationUsecase.call(
                conversationId: conversationId,
                context: context,
              );
            },
        messageRepository: messageRepository,
        getConversationBusyStateUsecase: getConversationBusyStateUsecase,
        conversationActivityGate: container.read(
          conversationActivityGateProvider,
        ),
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
