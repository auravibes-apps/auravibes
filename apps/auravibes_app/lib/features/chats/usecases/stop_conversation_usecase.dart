// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:riverpod/riverpod.dart';

class StopConversationUsecase {
  const StopConversationUsecase({
    required this._agentCancellationRuntime,
    required this._sendQueueRuntime,
    required this._messageRepository,
  });

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
    messageRepository: ref.watch(messageRepositoryProvider),
  );
});
