// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_resume_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
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
    final message = await _loadMessage(messageId);
    if (message == null) return false;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    final updatedToolCalls = _skippedToolCalls(metadata.toolCalls, toolCallId);

    await _patchToolCalls(messageId, metadata, updatedToolCalls);
    onToolCallChanged();

    return true;
  }

  @override
  Future<void> resumeConversationIfReady({required String messageId}) {
    return agentToolResumeService.call(messageId: messageId);
  }

  @override
  Future<void> stopPendingToolCalls({required String messageId}) async {
    final message = await _loadMessage(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    final updatedToolCalls = _stoppedToolCalls(metadata.toolCalls);
    if (updatedToolCalls == null) return;

    await _patchToolCalls(messageId, metadata, updatedToolCalls);
    onToolCallChanged();
    _finishActiveSubAgent(message);
  }

  Future<MessageEntity?> _loadMessage(String messageId) {
    return messageRepository.getMessageById(messageId);
  }

  List<MessageToolCallEntity> _skippedToolCalls(
    List<MessageToolCallEntity> toolCalls,
    String toolCallId,
  ) => toolCalls.map((toolCall) {
    if (toolCall.id != toolCallId) return toolCall;

    return toolCall.copyWith(resultStatus: ToolCallResultStatus.skippedByUser);
  }).toList();

  List<MessageToolCallEntity>? _stoppedToolCalls(
    List<MessageToolCallEntity> toolCalls,
  ) {
    var didUpdate = false;
    final updatedToolCalls = toolCalls.map((toolCall) {
      if (!toolCall.isPending) return toolCall;

      didUpdate = true;

      return toolCall.copyWith(
        resultStatus: ToolCallResultStatus.stoppedByUser,
      );
    }).toList();

    return didUpdate ? updatedToolCalls : null;
  }

  Future<void> _patchToolCalls(
    String messageId,
    MessageMetadataEntity metadata,
    List<MessageToolCallEntity> toolCalls,
  ) async {
    final _ = await messageRepository.patchMessage(
      messageId,
      .new(metadata: metadata.copyWith(toolCalls: toolCalls)),
    );
  }

  void _finishActiveSubAgent(MessageEntity message) {
    final parentId = activeSubAgents?.parentOf(message.conversationId);
    if (parentId == null) return;

    activeSubAgents?.finish(
      parentId: parentId,
      childId: message.conversationId,
      status: agent.SubAgentCompletionStatus.stopped,
    );
  }
}
