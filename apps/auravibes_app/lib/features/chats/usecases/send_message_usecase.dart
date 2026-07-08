// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:auravibes_agent/auravibes_agent.dart'
    show AgentIterationContext, AgentIterationDecision, AgentIterationOrigin;
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/services/agent_harness/aura_agent_service.dart';
import 'package:riverpod/riverpod.dart';

typedef ContinueAgentTurn =
    Future<AgentIterationDecision> Function({
      required String conversationId,
      required AgentIterationContext context,
    });

class SendMessageUsecase {
  const SendMessageUsecase({
    required this.continueAgentTurn,
    required this.messageRepository,
    required this.getConversationBusyStateUsecase,
    required this.sendQueueRuntime,
  });

  final ContinueAgentTurn continueAgentTurn;
  final MessageRepository messageRepository;
  final GetConversationBusyStateUsecase getConversationBusyStateUsecase;
  final ConversationSendQueueRuntime sendQueueRuntime;

  Future<void> call({
    required String conversationId,
    required ChatDraft draft,
  }) async {
    if (draft.isEmpty) return;

    final busyState = await getConversationBusyStateUsecase.call(
      conversationId: conversationId,
    );
    if (busyState.isBusy) {
      final _ = sendQueueRuntime.enqueue(
        conversationId: conversationId,
        draft: draft,
      );

      return;
    }

    await _sendNow(
      conversationId: conversationId,
      draft: draft,
    );
  }

  Future<void> _sendNow({
    required String conversationId,
    required ChatDraft draft,
  }) async {
    final createdMessage = await createUserMessage(
      conversationId: conversationId,
      draft: draft,
    );
    await continueFromUserMessage(
      conversationId: conversationId,
      messageId: createdMessage.id,
    );
  }

  Future<MessageEntity> createUserMessage({
    required String conversationId,
    required ChatDraft draft,
  }) {
    if (draft.isEmpty) return Future.error(ArgumentError('Draft is empty'));

    return messageRepository.createMessage(
      .new(
        conversationId: conversationId,
        content: draft.text,
        messageType: .text,
        isUser: true,
        status: .sending,
        attachments: draft.attachments,
      ),
    );
  }

  Future<void> continueFromUserMessage({
    required String conversationId,
    required String messageId,
  }) async {
    final _ = await continueAgentTurn(
      conversationId: conversationId,
      context: AgentIterationContext(
        origin: AgentIterationOrigin.userMessage,
        ackMessageIds: [messageId],
      ),
    );
  }
}

extension SendMessageUsecaseNewConversation on SendMessageUsecase {
  Future<void> sendFirstMessage({
    required String conversationId,
    required ChatDraft draft,
    required void Function(Object error, StackTrace stackTrace) onContinueError,
  }) async {
    if (draft.isEmpty) return;

    final createdMessage = await createUserMessage(
      conversationId: conversationId,
      draft: draft,
    );

    unawaited(
      continueFromUserMessage(
        conversationId: conversationId,
        messageId: createdMessage.id,
      ).catchError(onContinueError),
    );
  }
}

final sendMessageUsecaseProvider = Provider<SendMessageUsecase>(
  (ref) {
    final agentService = ref.watch(auraAgentServiceProvider);

    return SendMessageUsecase(
      continueAgentTurn: agentService.agent.continueTurn,
      messageRepository: ref.watch(messageRepositoryProvider),
      getConversationBusyStateUsecase: ref.watch(
        getConversationBusyStateUsecaseProvider,
      ),
      sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
    );
  },
  dependencies: [auraAgentServiceProvider],
);
