import 'package:auravibes_engine/src/tool_call_actions.dart';
import 'package:auravibes_engine/src/tool_resume_service.dart';

class ToolsNamespace<TTool extends Object> {
  ToolsNamespace({
    required ApproveToolCallProvider<TTool> approvals,
    required SkipToolCallProvider skips,
    required this._stopPending,
    required AgentToolResumeProvider resume,
  }) : _approve = ApproveToolCallService(provider: approvals),
       _skip = SkipToolCallService(provider: skips),
       _resume = AgentToolResumeService(provider: resume);

  final ApproveToolCallService<TTool> _approve;
  final SkipToolCallService _skip;
  final StopPendingToolCallsProvider _stopPending;
  final AgentToolResumeService _resume;

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

  Future<void> skip({
    required String toolCallId,
    required String messageId,
  }) {
    return _skip.call(toolCallId: toolCallId, messageId: messageId);
  }

  Future<void> stopPending({required String messageId}) {
    return _stopPending.stopPendingToolCalls(messageId: messageId);
  }

  Future<void> resumeIfReady({required String messageId}) {
    return _resume.call(messageId: messageId);
  }
}
