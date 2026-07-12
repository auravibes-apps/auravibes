import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;

agent.AgentToolPermissionResult toAgentToolPermissionResult(
  ToolPermissionResult result,
) {
  return switch (result) {
    ToolPermissionResult.granted => agent.AgentToolPermissionResult.granted,
    ToolPermissionResult.needsConfirmation =>
      agent.AgentToolPermissionResult.needsConfirmation,
    ToolPermissionResult.disabledInConversation =>
      agent.AgentToolPermissionResult.disabledInConversation,
    ToolPermissionResult.disabledByAgent =>
      agent.AgentToolPermissionResult.disabledByAgent,
    ToolPermissionResult.disabledInWorkspace =>
      agent.AgentToolPermissionResult.disabledInWorkspace,
    ToolPermissionResult.notConfigured =>
      agent.AgentToolPermissionResult.notConfigured,
  };
}

ToolCallResultStatus toAppToolCallResultStatus(
  agent.AgentToolResultStatus status,
) {
  return switch (status) {
    agent.AgentToolResultStatus.success => ToolCallResultStatus.success,
    agent.AgentToolResultStatus.toolNotFound =>
      ToolCallResultStatus.toolNotFound,
    agent.AgentToolResultStatus.executionError =>
      ToolCallResultStatus.executionError,
    agent.AgentToolResultStatus.disabledInConversation =>
      ToolCallResultStatus.disabledInConversation,
    agent.AgentToolResultStatus.disabledByAgent =>
      ToolCallResultStatus.disabledByAgent,
    agent.AgentToolResultStatus.disabledInWorkspace =>
      ToolCallResultStatus.disabledInWorkspace,
    agent.AgentToolResultStatus.notConfigured =>
      ToolCallResultStatus.notConfigured,
    agent.AgentToolResultStatus.stoppedByUser =>
      ToolCallResultStatus.stoppedByUser,
  };
}

agent.AgentToolCallLifecycle toAgentToolCallLifecycle(
  ToolCallResultStatus? status,
) {
  return status?.agentLifecycle ?? agent.AgentToolCallLifecycle.pending;
}
