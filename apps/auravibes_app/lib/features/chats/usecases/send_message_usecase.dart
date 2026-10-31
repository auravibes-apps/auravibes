// ignore_for_file: implementation_imports
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:async';

import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/provider_recovery_metadata.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/providers/aura_agent_service_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_chat_attachment_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_activity_gate.dart';
import 'package:auravibes_app/features/chats/providers/conversation_agent_language_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_message_sender.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/usecases/message_persisted_exception.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show
        AgentIterationContext,
        AgentIterationDecision,
        AgentIterationDecisionX,
        AgentIterationOrigin;
import 'package:riverpod/src/providers/provider.dart';

typedef ContinueAgentTurn = Future<AgentIterationDecision> Function({
  required String conversationId,
  required AgentIterationContext context,
  String? languageCode,
});

class SendMessageUsecase {
  const new({
    required ContinueAgentTurn this.continueAgentTurn,
    required this.messageRepository,
    required this.getConversationBusyStateUsecase,
    required this.sendQueueRuntime,
    required this.conversationActivityGate,
  }) : cloudSend = null;

  const new cloud(
    Future<void> Function(String conversationId, ChatDraft draft)
    this.cloudSend,
  ) : continueAgentTurn = null,
      messageRepository = null,
      getConversationBusyStateUsecase = null,
      sendQueueRuntime = null,
      conversationActivityGate = null;

  final ContinueAgentTurn? continueAgentTurn;
  final MessageRepository? messageRepository;
  final GetConversationBusyStateUsecase? getConversationBusyStateUsecase;
  final ConversationSendQueueRuntime? sendQueueRuntime;
  final ConversationActivityGate? conversationActivityGate;
  final Future<void> Function(String conversationId, ChatDraft draft)?
  cloudSend;

  Future<AgentIterationDecision?> call({
    required String conversationId,
    required ChatDraft draft,
  }) => _send(conversationId, draft);

  Future<MessageEntity> createUserMessage({
    required String conversationId,
    required ChatDraft draft,
  }) {
    if (draft.isEmpty) return Future.error(ArgumentError('Draft is empty'));

    final repository = messageRepository;
    if (repository == null) {
      return Future.error(StateError('Local message repository unavailable'));
    }

    return repository.createMessage(
      .new(
        conversationId: conversationId,
        content: draft.text,
        messageType: .text,
        isUser: true,
        status: .sending,
        metadata: draft.metadataJson,
        attachments: draft.attachments,
      ),
    );
  }

  Future<AgentIterationDecision> continueFromUserMessage({
    required String conversationId,
    required String messageId,
    String? languageCode,
  }) => _withConversationActivity(
    conversationActivityGate,
    conversationId,
    () => _continueFromUserMessage(
      conversationId: conversationId,
      messageId: messageId,
      origin: .userMessage,
      languageCode: languageCode,
    ),
  );

  Future<AgentIterationDecision> retryUserMessage({
    required String conversationId,
    required String messageId,
    String languageCode = 'en',
  }) => _withConversationActivity(
    conversationActivityGate,
    conversationId,
    () => _retryUserMessage(
      this,
      conversationId: conversationId,
      messageId: messageId,
      languageCode: languageCode,
    ),
  );

  Future<AgentIterationDecision> _continueFromUserMessage({
    required String conversationId,
    required String messageId,
    required AgentIterationOrigin origin,
    String? languageCode,
  }) async {
    final continueTurn = continueAgentTurn;
    if (continueTurn == null) {
      throw StateError('Local agent runtime unavailable');
    }

    return await continueTurn(
      conversationId: conversationId,
      context: AgentIterationContext(
        origin: origin,
        ackMessageIds: [messageId],
      ),
      languageCode: languageCode,
    );
  }

  Future<AgentIterationDecision?> _send(
    String conversationId,
    ChatDraft draft,
  ) async {
    if (draft.isEmpty) return null;
    if (cloudSend case final send?) {
      await send(conversationId, draft);

      return null;
    }

    return await _withConversationActivity(
      conversationActivityGate,
      conversationId,
      () => _sendLocal(conversationId, draft),
    );
  }

  Future<AgentIterationDecision?> _sendLocal(
    String conversationId,
    ChatDraft draft,
  ) async {
    final getBusyState = getConversationBusyStateUsecase;
    final queue = sendQueueRuntime;
    if (getBusyState == null || queue == null) {
      throw StateError('Local send dependencies unavailable');
    }

    final busyState = await getBusyState.call(conversationId: conversationId);
    if (busyState.isBusy) {
      final _ = queue.enqueue(conversationId: conversationId, draft: draft);

      return null;
    }

    return await _sendNow(conversationId: conversationId, draft: draft);
  }

  Future<AgentIterationDecision> _sendNow({
    required String conversationId,
    required ChatDraft draft,
  }) async {
    final createdMessage = await createUserMessage(
      conversationId: conversationId,
      draft: draft,
    );
    try {
      return await _continueFromUserMessage(
        conversationId: conversationId,
        messageId: createdMessage.id,
        origin: .userMessage,
        languageCode: draft.languageCode,
      );
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        MessagePersistedException(
          message: error.toString(),
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }
}

Future<T> _withConversationActivity<T>(
  ConversationActivityGate? gate,
  String conversationId,
  Future<T> Function() action,
) {
  if (gate == null) {
    throw StateError('Local conversation activity gate unavailable');
  }

  return gate.runActivity(conversationId, action);
}

Future<AgentIterationDecision> _retryUserMessage(
  SendMessageUsecase usecase, {
  required String conversationId,
  required String messageId,
  required String languageCode,
}) async {
  final repository =
      usecase.messageRepository ??
      (throw StateError('Local message repository unavailable'));
  final message = await repository.getMessageById(messageId);
  if (!_isRetryableUserMessage(message, conversationId)) {
    throw StateError('Message cannot be retried');
  }

  return await usecase._continueFromUserMessage(
    conversationId: conversationId,
    messageId: messageId,
    origin: .manualContinue,
    languageCode: languageCode,
  );
}

typedef _FirstMessageCallbacks = ({
  void Function(Object error, StackTrace stackTrace) onContinueError,
  void Function(String conversationId, AgentIterationDecision decision)?
  onAgentStop,
});

typedef _FirstMessageRequest = ({
  SendMessageUsecase usecase,
  String conversationId,
  String messageId,
  String? languageCode,
  _FirstMessageCallbacks callbacks,
});

Future<void> _createAndContinueFirstMessage(
  SendMessageUsecase usecase, {
  required String conversationId,
  required ChatDraft draft,
  required _FirstMessageCallbacks callbacks,
}) async {
  final createdMessage = await usecase.createUserMessage(
    conversationId: conversationId,
    draft: draft,
  );
  unawaited(
    _continueFirstMessage((
      usecase: usecase,
      conversationId: conversationId,
      messageId: createdMessage.id,
      languageCode: draft.languageCode,
      callbacks: callbacks,
    )),
  );
}

Future<void> _continueFirstMessage(_FirstMessageRequest request) async {
  try {
    final decision = await request.usecase.continueFromUserMessage(
      conversationId: request.conversationId,
      messageId: request.messageId,
      languageCode: request.languageCode,
    );
    _reportFirstMessageAgentStop(
      request.callbacks,
      request.conversationId,
      decision,
    );
  } on Object catch (error, stackTrace) {
    request.callbacks.onContinueError(error, stackTrace);
  }
}

void _reportFirstMessageAgentStop(
  _FirstMessageCallbacks callbacks,
  String conversationId,
  AgentIterationDecision decision,
) {
  if (decision.needsUserNotice)
    callbacks.onAgentStop?.call(conversationId, decision);
}

bool _isRetryableUserMessage(MessageEntity? message, String conversationId) {
  if (message == null || message.conversationId != conversationId) {
    return false;
  }
  if (!message.isUser || message.isForkReference || !message.hasValidContent) {
    return false;
  }

  return message.status == .unfinished ||
      (message.status == .error &&
          ProviderRecoveryMetadata.isRetryEligible(message));
}

extension SendMessageUsecaseNewConversation on SendMessageUsecase {
  Future<void> sendFirstMessage({
    required String conversationId,
    required ChatDraft draft,
    required void Function(Object error, StackTrace stackTrace) onContinueError,
    void Function(String conversationId, AgentIterationDecision decision)?
    onAgentStop,
  }) async {
    if (draft.isEmpty) return;
    if (cloudSend case final send?) {
      final _ = await send(conversationId, draft);

      return;
    }

    await _withConversationActivity(
      conversationActivityGate,
      conversationId,
      () => _createAndContinueFirstMessage(
        this,
        conversationId: conversationId,
        draft: draft,
        callbacks: (onContinueError: onContinueError, onAgentStop: onAgentStop),
      ),
    );
  }
}

final ProviderFamily<SendMessageUsecase, String>
sendMessageUsecaseProvider = Provider.family<SendMessageUsecase, String>(
  // Keep callback and scoped dependencies as distinct arguments.
  (ref, workspaceId) {
    final session = ref
        .watch(workspaceSessionForRouteProvider(workspaceId))
        .requireValue;
    session.capabilities.require(
      supported: session.capabilities.agentExecution,
    );
    if (session.cloud != null) {
      final sender = CloudChatMessageSender(
        gateway: () async {
          final stateGateway = await ref.read(
            cloudWorkspaceStateGatewayProvider(session).future,
          );

          return stateGateway == null ? null : CloudChatGateway(stateGateway);
        },
        attachments: () =>
            ref.read(cloudChatAttachmentUsecaseProvider(workspaceId).future),
        capabilities: session.capabilities,
        invalidateMessages: (conversationId) => ref.invalidate(
          chatMessagesByConversationProvider(workspaceId, conversationId),
        ),
      );

      return SendMessageUsecase.cloud(sender.call);
    }
    final agentService = ref.watch(auraAgentServiceProvider);

    return SendMessageUsecase(
      continueAgentTurn:
          ({required conversationId, required context, languageCode}) async {
            ref
                .read(conversationAgentLanguageRuntimeProvider)
                .remember(conversationId, languageCode);

            return await agentService.agent.continueTurn(
              conversationId: conversationId,
              context: context,
            );
          },
      messageRepository: ref.watch(messageRepositoryProvider),
      getConversationBusyStateUsecase: ref.watch(
        getConversationBusyStateUsecaseProvider,
      ),
      sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
      conversationActivityGate: ref.watch(conversationActivityGateProvider),
    );
  },
  dependencies: [auraAgentServiceProvider],
);
