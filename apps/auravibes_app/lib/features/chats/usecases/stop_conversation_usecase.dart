// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:riverpod/riverpod.dart';

class StopConversationUsecase {
  const StopConversationUsecase({
    required this._agentCancellationRuntime,
    required this._sendQueueRuntime,
    required this._conversationStreamingRuntime,
    required this._rateLimitRetryRuntime,
    required this._messageRepository,
  });

  final AgentCancellationRuntime _agentCancellationRuntime;
  final ConversationSendQueueRuntime _sendQueueRuntime;
  final ConversationStreamingRuntime _conversationStreamingRuntime;
  final ConversationRateLimitRetryRuntime _rateLimitRetryRuntime;
  final MessageRepository _messageRepository;

  Future<void> call({required String conversationId}) async {
    _agentCancellationRuntime.requestStop(conversationId);
    _sendQueueRuntime.clear(conversationId);
    _conversationStreamingRuntime.remove(conversationId);
    _rateLimitRetryRuntime.clear(conversationId);
    await _stopLatestPendingTools(conversationId);
  }

  Future<void> _stopLatestPendingTools(String conversationId) async {
    final messages = await _messageRepository.getMessagesByConversation(
      conversationId,
    );
    final latestAssistantMessage = findLatestAssistantMessage(messages);
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

    final _ = await _messageRepository.patchMessage(
      latestAssistantMessage.id,
      MessagePatch(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );
  }
}

final stopConversationUsecaseProvider = Provider<StopConversationUsecase>((
  ref,
) {
  return StopConversationUsecase(
    agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
    sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
    conversationStreamingRuntime: ref.watch(
      conversationStreamingRuntimeProvider,
    ),
    rateLimitRetryRuntime: ref.watch(conversationRateLimitRetryRuntimeProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
  );
});
