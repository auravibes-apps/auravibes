// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_execution_service.dart';
import 'package:auravibes_app/features/chats/agent_adapters/continue_agent_service.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/maybe_auto_compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/stop_pending_tool_calls_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

class const AppAgentConversationDataProvider({
  required final ConversationRepository conversationRepository,
  required final MessageRepository messageRepository,
  required final MaybeAutoCompactConversationUsecase
  autoCompactConversationUsecase,
}) implements AgentDataProvider {
  @override
  Future<void> autoCompactConversation({required String conversationId}) {
    return autoCompactConversationUsecase.call(conversationId: conversationId);
  }

  @override
  Future<String?> getWorkspaceId(String conversationId) async {
    final conversation = await conversationRepository.getConversationById(
      conversationId,
    );

    return conversation?.workspaceId;
  }

  @override
  Future<List<AgentConversationMessage>> getMessages(
    String conversationId,
  ) async {
    final messages = await messageRepository.getMessagesByConversation(
      conversationId,
    );

    return messages.map(_toAgentConversationMessage).toList();
  }

  @override
  Future<AgentCreatedMessage> createQueuedUserMessage({
    required String conversationId,
    required String content,
    Object? payload,
  }) async {
    final draft = payload is ChatDraft ? payload : ChatDraft(text: content);
    final message = await messageRepository.createMessage(
      draft.toMessage(conversationId),
    );

    return AgentCreatedMessage(id: message.id);
  }

  @override
  Future<void> markMessagesSent(List<String> messageIds) async {
    final _ = await Future.wait(
      messageIds.map(
        (messageId) => messageRepository.patchMessage(
          messageId,
          const MessagePatch(status: MessageStatus.sent),
        ),
      ),
    );
  }

  @override
  Future<void> stopLatestPendingTools(String conversationId) async {
    final messages = await messageRepository.getMessagesByConversation(
      conversationId,
    );
    final latestAssistantMessage = _latestAssistantMessage(messages);
    if (latestAssistantMessage == null) return;

    final metadata = stopPendingToolMetadata(latestAssistantMessage.metadata);
    if (identical(metadata, latestAssistantMessage.metadata)) return;

    final _ = await messageRepository.patchMessage(
      latestAssistantMessage.id,
      MessagePatch(metadata: metadata),
    );
  }
}

MessageEntity? _latestAssistantMessage(List<MessageEntity> messages) {
  for (final message in messages.reversed) {
    if (!message.isUser) return message;
  }

  return null;
}

AgentConversationMessage _toAgentConversationMessage(MessageEntity message) {
  return AgentConversationMessage(
    id: message.id,
    conversationId: message.conversationId,
    content: message.content,
    type: message.messageType.value,
    status: message.status.value,
    isUser: message.isUser,
    createdAt: message.createdAt,
    updatedAt: message.updatedAt,
  );
}

class const AppAgentLoopToolProvider(
  final AgentToolExecutionService _toolExecutionService,
) implements AgentLoopToolProvider {
  @override
  Future<AgentIterationDecision> runAllowedTools({
    required String conversationId,
    required String workspaceId,
  }) {
    return _toolExecutionService.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
  }
}

class const AppAgentModelProvider(
  final ContinueAgentService _continueAgentService,
) implements AgentModelProvider {
  @override
  Future<ContinueAgentResult> continueAgent({
    required String conversationId,
    AgentIterationContext? context,
  }) {
    return _continueAgentService.call(
      conversationId: conversationId,
      context: context,
    );
  }
}

AppAgentConversationDataProvider _buildAppAgentDataProvider(Ref ref) {
  return AppAgentConversationDataProvider(
    conversationRepository: ref.watch(conversationRepositoryProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
    autoCompactConversationUsecase: ref.watch(
      maybeAutoCompactConversationUsecaseProvider,
    ),
  );
}

final appAgentDataProvider = Provider<AppAgentConversationDataProvider>(
  _buildAppAgentDataProvider,
  dependencies: [maybeAutoCompactConversationUsecaseProvider],
);

final appAgentModelProvider = Provider<AppAgentModelProvider>(
  (ref) => AppAgentModelProvider(ref.watch(continueAgentServiceProvider)),
  dependencies: [continueAgentServiceProvider],
);

final appAgentLoopToolProvider = Provider<AppAgentLoopToolProvider>((ref) {
  return AppAgentLoopToolProvider(ref.watch(agentToolExecutionServiceProvider));
});

AgentLoopRunner _buildAppAgentLoop(Ref ref) {
  final retryRuntime = ref.watch(conversationRateLimitRetryRuntimeProvider);

  return AgentLoopRunner(
    data: ref.watch(appAgentDataProvider),
    models: ref.watch(appAgentModelProvider),
    tools: ref.watch(appAgentLoopToolProvider),
    sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
    cancellationEffects: ref.watch(agentCancellationRuntimeProvider),
    rateLimitRetryRuntime: AgentRateLimitRetryRuntime(
      start: retryRuntime.start,
      clear: retryRuntime.clear,
    ),
  );
}

final appAgentLoopProvider = Provider<AgentLoopRunner>(
  _buildAppAgentLoop,
  dependencies: [appAgentDataProvider, appAgentModelProvider],
);
