import 'package:auravibes_engine/src/tool_call_actions.dart';
import 'package:auravibes_engine/src/tool_resume_service.dart';

class ToolsNamespace<TTool extends Object>({
  required ApproveToolCallProvider<TTool> approvals,
  required SkipToolCallProvider skips,
  required final StopPendingToolCallsProvider _stopPending,
  required AgentToolResumeProvider resume,
}) {
  final ApproveToolCallService<TTool> _approve = .new(provider: approvals);
  final SkipToolCallService _skip = .new(provider: skips);
  final AgentToolResumeService _resume = .new(provider: resume);

  Future<void> approve({
    required String toolCallId,
    required String messageId,
    required String conversationId,
    required AgentToolGrantLevel level,
  }) {
    return _approve.call(
      toolCallId: toolCallId,
      messageId: messageId,
      conversationId: conversationId,
      level: level,
    );
  }

  Future<void> skip({
    required String toolCallId,
    required String messageId,
    required String conversationId,
  }) {
    return _skip.call(
      toolCallId: toolCallId,
      messageId: messageId,
      conversationId: conversationId,
    );
  }

  Future<void> stopPending({
    required String messageId,
    required String conversationId,
  }) {
    return _stopPending.stopPendingToolCalls(
      messageId: messageId,
      conversationId: conversationId,
    );
  }

  Future<void> resumeIfReady({required String messageId}) {
    return _resume.call(messageId: messageId);
  }
}
