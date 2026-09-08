// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_resume_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/stop_pending_tool_calls_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;

class const AppToolCallActionsDataProvider({
  required final MessageRepository messageRepository,
  required final AgentToolResumeService agentToolResumeService,
  required final void Function() onToolCallChanged,
  final ActiveSubAgentRuntime? activeSubAgents,
}) implements agent.SkipToolCallProvider, agent.StopPendingToolCallsProvider {
  @override
  Future<bool> skipToolCall({
    required String messageId,
    required String toolCallId,
  }) async {
    final message = await messageRepository.getMessageById(messageId);
    if (message == null) return false;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      if (toolCall.id != toolCallId) return toolCall;

      return toolCall.copyWith(
        resultStatus: ToolCallResultStatus.skippedByUser,
      );
    }).toList();

    final _ = await messageRepository.patchMessage(
      messageId,
      MessagePatch(metadata: metadata.copyWith(toolCalls: updatedToolCalls)),
    );
    onToolCallChanged();

    return true;
  }

  @override
  Future<void> resumeConversationIfReady({required String messageId}) {
    return agentToolResumeService.call(messageId: messageId);
  }

  @override
  Future<void> stopPendingToolCalls({required String messageId}) async {
    final conversationId = await StopPendingToolCallsUsecase(messageRepository)
        .call(messageId: messageId);
    if (conversationId == null) return;
    onToolCallChanged();
    final parentId = activeSubAgents?.parentOf(conversationId);
    if (parentId != null) {
      activeSubAgents?.finish(
        parentId: parentId,
        childId: conversationId,
        status: agent.SubAgentCompletionStatus.stopped,
      );
    }
  }
}
