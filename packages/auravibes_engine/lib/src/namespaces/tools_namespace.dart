import 'package:auravibes_engine/src/tool_call_actions.dart';
import 'package:auravibes_engine/src/tool_resume_service.dart';

class ToolsNamespace<TTool extends Object>({
  required ApproveToolCallProvider<TTool> approvals,
  required SkipToolCallProvider skips,
  required final StopPendingToolCallsProvider _stopPending,
  required AgentToolResumeProvider resume,
}) {
  final ApproveToolCallService<TTool> _approve = ApproveToolCallService(
    provider: approvals,
  );
  final SkipToolCallService _skip = SkipToolCallService(provider: skips);
  final AgentToolResumeService _resume = AgentToolResumeService(
    provider: resume,
  );

  Future<void> approve({
    required String toolCallId,
    required String messageId,
    required AgentToolGrantLevel level,
  }) {
    return _approve.call(
      toolCallId: toolCallId,
      messageId: messageId,
      level: level,
    );
  }

  Future<void> skip({required String toolCallId, required String messageId}) {
    return _skip.call(toolCallId: toolCallId, messageId: messageId);
  }

  Future<void> stopPending({required String messageId}) {
    return _stopPending.stopPendingToolCalls(messageId: messageId);
  }

  Future<void> resumeIfReady({required String messageId}) {
    return _resume.call(messageId: messageId);
  }
}
