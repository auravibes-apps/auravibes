// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_agent/auravibes_agent.dart' as agent;
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_resume_service.dart';

class AppToolCallActionsDataProvider
    implements agent.SkipToolCallProvider, agent.StopPendingToolCallsProvider {
  const AppToolCallActionsDataProvider({
    required this.messageRepository,
    required this.agentToolResumeService,
  });

  final MessageRepository messageRepository;
  final AgentToolResumeService agentToolResumeService;

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
      MessagePatch(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );

    return true;
  }

  @override
  Future<void> resumeConversationIfReady({required String messageId}) {
    return agentToolResumeService.call(messageId: messageId);
  }

  @override
  Future<void> stopPendingToolCalls({required String messageId}) async {
    final message = await messageRepository.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
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
      messageId,
      MessagePatch(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );
  }
}
