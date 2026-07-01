import 'package:auravibes_agent/src/providers/agent_tool_provider.dart';
import 'package:auravibes_agent/src/tool_call_actions.dart';
import 'package:auravibes_agent/src/tool_resume_service.dart';

class ToolsNamespace<TTool extends Object> {
  ToolsNamespace({required AgentToolProvider<TTool> tools})
    : _approve = ApproveToolCallService(provider: tools),
      _skip = SkipToolCallService(provider: tools),
      _tools = tools,
      _resume = AgentToolResumeService(provider: tools);

  final ApproveToolCallService<TTool> _approve;
  final SkipToolCallService _skip;
  final AgentToolProvider<TTool> _tools;
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
    return _tools.stopPendingToolCalls(messageId: messageId);
  }

  Future<void> resumeIfReady({required String messageId}) {
    return _resume.call(messageId: messageId);
  }
}
