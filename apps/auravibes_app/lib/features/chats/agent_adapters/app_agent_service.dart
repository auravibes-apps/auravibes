// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/maybe_auto_compact_conversation_usecase.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_execution_service.dart';
import 'package:auravibes_app/services/agent_harness/continue_agent_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

class AppAgentConversationDataProvider implements AgentDataProvider {
  const AppAgentConversationDataProvider({
    required this.conversationRepository,
    required this.messageRepository,
    required this.autoCompactConversationUsecase,
  });

  final ConversationRepository conversationRepository;
  final MessageRepository messageRepository;
  final MaybeAutoCompactConversationUsecase autoCompactConversationUsecase;

  @override
  Future<void> autoCompactConversation({
    required String conversationId,
  }) {
    return autoCompactConversationUsecase.call(
      conversationId: conversationId,
    );
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
      MessageToCreate(
        conversationId: conversationId,
        content: draft.text,
        messageType: MessageType.text,
        isUser: true,
        status: MessageStatus.sending,
        attachments: draft.attachments,
      ),
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

    final metadata =
        latestAssistantMessage.metadata ?? const MessageMetadataEntity();
    var didUpdate = false;
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      if (!toolCall.isPending) return toolCall;

      didUpdate = true;

      return toolCall.copyWith(
        resultStatus: ToolCallResultStatus.stoppedByUser,
      );
    }).toList();
    if (!didUpdate) return;

    final _ = await messageRepository.patchMessage(
      latestAssistantMessage.id,
      MessagePatch(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
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

class AppAgentService extends AgentLoopRunner {
  AppAgentService({
    required ContinueAgentService continueAgentService,
    required AgentToolExecutionService toolExecutionService,
    required MaybeAutoCompactConversationUsecase autoCompactConversationUsecase,
    required ConversationRepository conversationRepository,
    required MessageRepository messageRepository,
    required ConversationSendQueueRuntime sendQueueRuntime,
    required super.agentCancellationRuntime,
    required ConversationRateLimitRetryRuntime rateLimitRetryRuntime,
    super.rateLimitRetryDelay,
    super.now,
    super.sleep,
  }) : super(
         data: AppAgentConversationDataProvider(
           conversationRepository: conversationRepository,
           messageRepository: messageRepository,
           autoCompactConversationUsecase: autoCompactConversationUsecase,
         ),
         models: AppAgentModelProvider(continueAgentService),
         tools: AppAgentLoopToolProvider(toolExecutionService),
         sendQueueRuntime: sendQueueRuntime,
         rateLimitRetryRuntime: AgentRateLimitRetryRuntime(
           start: rateLimitRetryRuntime.start,
           clear: rateLimitRetryRuntime.clear,
         ),
       );

  AppAgentService._({
    required AppAgentConversationDataProvider data,
    required AppAgentModelProvider models,
    required AppAgentRuntimeProvider runtime,
    required AppAgentLoopToolProvider tools,
    required ConversationSendQueueRuntime sendQueueRuntime,
    required super.agentCancellationRuntime,
  }) : super(
         data: data,
         models: models,
         tools: tools,
         sendQueueRuntime: sendQueueRuntime,
         rateLimitRetryRuntime: runtime.rateLimitRetryRuntime,
       );
}

class AppAgentLoopToolProvider implements AgentLoopToolProvider {
  const AppAgentLoopToolProvider(this._toolExecutionService);

  final AgentToolExecutionService _toolExecutionService;

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

class AppAgentModelProvider implements AgentModelProvider {
  const AppAgentModelProvider(this._continueAgentService);

  final ContinueAgentService _continueAgentService;

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

class AppAgentRuntimeProvider implements AgentRuntimeProvider {
  const AppAgentRuntimeProvider({
    required this.sendQueueRuntime,
    required this.cancellationRuntime,
    required this.retryRuntime,
  });

  @override
  final ConversationSendQueueRuntime sendQueueRuntime;

  @override
  final AgentCancellationRuntime cancellationRuntime;

  final ConversationRateLimitRetryRuntime retryRuntime;

  @override
  AgentRateLimitRetryRuntime get rateLimitRetryRuntime {
    return AgentRateLimitRetryRuntime(
      start: retryRuntime.start,
      clear: retryRuntime.clear,
    );
  }
}

final appAgentDataProvider = Provider<AppAgentConversationDataProvider>((ref) {
  return AppAgentConversationDataProvider(
    conversationRepository: ref.watch(conversationRepositoryProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
    autoCompactConversationUsecase: ref.watch(
      maybeAutoCompactConversationUsecaseProvider,
    ),
  );
});

final appAgentModelProvider = Provider<AppAgentModelProvider>((ref) {
  return AppAgentModelProvider(ref.watch(continueAgentServiceProvider));
});

final appAgentLoopToolProvider = Provider<AppAgentLoopToolProvider>((ref) {
  return AppAgentLoopToolProvider(ref.watch(agentToolExecutionServiceProvider));
});

final appAgentRuntimeProvider = Provider<AppAgentRuntimeProvider>((ref) {
  return AppAgentRuntimeProvider(
    sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
    cancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
    retryRuntime: ref.watch(conversationRateLimitRetryRuntimeProvider),
  );
});

final appAgentServiceProvider = Provider<AppAgentService>((
  ref,
) {
  return AppAgentService._(
    data: ref.watch(appAgentDataProvider),
    models: ref.watch(appAgentModelProvider),
    runtime: ref.watch(appAgentRuntimeProvider),
    tools: ref.watch(appAgentLoopToolProvider),
    sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
    agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
  );
});
