import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/send_queue_runtime_provider.dart';
import 'package:riverpod/riverpod.dart';

class StopConversationUsecase {
  const StopConversationUsecase({
    required AgentCancellationRuntime agentCancellationRuntime,
    required ConversationSendQueueRuntime sendQueueRuntime,
    required MessageRepository messageRepository,
  }) : _agentCancellationRuntime = agentCancellationRuntime,
       _sendQueueRuntime = sendQueueRuntime,
       _messageRepository = messageRepository;

  final AgentCancellationRuntime _agentCancellationRuntime;
  final ConversationSendQueueRuntime _sendQueueRuntime;
  final MessageRepository _messageRepository;

  Future<void> call({required String conversationId}) async {
    _agentCancellationRuntime.requestStop(conversationId);
    _sendQueueRuntime.clear(conversationId);
    await _stopLatestPendingTools(conversationId);
  }

  Future<void> _stopLatestPendingTools(String conversationId) async {
    final messages = await _messageRepository.getMessagesByConversation(
      conversationId,
    );
    MessageEntity? latestAssistantMessage;
    for (final message in messages.reversed) {
      if (!message.isUser) {
        latestAssistantMessage = message;
        break;
      }
    }
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

    await _messageRepository.patchMessage(
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
    messageRepository: ref.watch(messageRepositoryProvider),
  );
});
