import 'package:auravibes_engine/src/agent_runtime.dart';
import 'package:auravibes_engine/src/tool_call_actions.dart';
import 'package:auravibes_engine/src/tool_resume_service.dart';

class ToolsNamespace<TTool extends Object>({
  required ApproveToolCallProvider<TTool> approvals,
  required SkipToolCallProvider skips,
  required final StopPendingToolCallsProvider _stopPending,
  required AgentToolResumeProvider resume,
  required final AgentCancellationEffects cancellationEffects,
}) {
  final ApproveToolCallService<TTool> _approve = .new(provider: approvals);
  final SkipToolCallService _skip = .new(provider: skips);
  final AgentToolResumeService _resume = .new(provider: resume);
  final AgentCancellationEffects _cancellationEffects = cancellationEffects;

  Future<void> approve({
    required String toolCallId,
    required String messageId,
    required String conversationId,
    required AgentToolGrantLevel level,
  }) async {
    final cancellationScope = _cancellationEffects.start(conversationId);
    try {
      await _approve.call(
        toolCallId: toolCallId,
        messageId: messageId,
        conversationId: conversationId,
        level: level,
      );
    } finally {
      _cancellationEffects.clear(conversationId, cancellationScope);
    }
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
