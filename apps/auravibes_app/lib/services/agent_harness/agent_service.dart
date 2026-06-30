// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:auravibes_agent/auravibes_agent_internal.dart' as agent_loop;
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/maybe_auto_compact_conversation_usecase.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_execution_service.dart';
import 'package:auravibes_app/services/agent_harness/continue_agent_service.dart';
import 'package:riverpod/riverpod.dart';

class AppAgentConversationDataProvider implements AgentDataProvider {
  const AppAgentConversationDataProvider({
    required this.conversationRepository,
    required this.messageRepository,
    required this.continueAgentService,
    required this.toolExecutionService,
    required this.autoCompactConversationUsecase,
  });

  final ConversationRepository conversationRepository;
  final MessageRepository messageRepository;
  final ContinueAgentService continueAgentService;
  final AgentToolExecutionService toolExecutionService;
  final MaybeAutoCompactConversationUsecase autoCompactConversationUsecase;

  @override
  Future<ContinueAgentResult> continueAgent({
    required String conversationId,
    AgentIterationContext? context,
  }) {
    return continueAgentService.call(
      conversationId: conversationId,
      context: context,
    );
  }

  @override
  Future<AgentIterationDecision> runAllowedTools({
    required String conversationId,
    required String workspaceId,
  }) {
    return toolExecutionService.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
  }

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
  }) async {
    final message = await messageRepository.createMessage(
      MessageToCreate(
        conversationId: conversationId,
        content: content,
        messageType: MessageType.text,
        isUser: true,
        status: MessageStatus.sending,
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

class AgentService extends agent_loop.AgentService {
  AgentService({
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
         provider: AppAgentConversationDataProvider(
           conversationRepository: conversationRepository,
           messageRepository: messageRepository,
           continueAgentService: continueAgentService,
           toolExecutionService: toolExecutionService,
           autoCompactConversationUsecase: autoCompactConversationUsecase,
         ),
         sendQueueRuntime: sendQueueRuntime,
         rateLimitRetryRuntime: AgentRateLimitRetryRuntime(
           start: rateLimitRetryRuntime.start,
           clear: rateLimitRetryRuntime.clear,
         ),
       );
}

final agentServiceProvider = Provider<AgentService>((
  ref,
) {
  final rateLimitRetryRuntime = ref.watch(
    conversationRateLimitRetryRuntimeProvider,
  );

  return AgentService(
    continueAgentService: ref.watch(continueAgentServiceProvider),
    toolExecutionService: ref.watch(agentToolExecutionServiceProvider),
    autoCompactConversationUsecase: ref.watch(
      maybeAutoCompactConversationUsecaseProvider,
    ),
    conversationRepository: ref.watch(conversationRepositoryProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
    sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
    agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
    rateLimitRetryRuntime: rateLimitRetryRuntime,
  );
});
