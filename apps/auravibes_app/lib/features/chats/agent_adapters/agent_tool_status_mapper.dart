import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;

abstract final class AgentToolStatusMapper {
  static const Map<agent.AgentToolResultStatus, ToolCallResultStatus> _resultStatuses = {
    agent.AgentToolResultStatus.success: ToolCallResultStatus.success,
    agent.AgentToolResultStatus.toolNotFound: ToolCallResultStatus.toolNotFound,
    agent.AgentToolResultStatus.executionError:
        ToolCallResultStatus.executionError,
    agent.AgentToolResultStatus.disabledInConversation:
        ToolCallResultStatus.disabledInConversation,
    agent.AgentToolResultStatus.disabledByAgent:
        ToolCallResultStatus.disabledByAgent,
    agent.AgentToolResultStatus.disabledInWorkspace:
        ToolCallResultStatus.disabledInWorkspace,
    agent.AgentToolResultStatus.notConfigured:
        ToolCallResultStatus.notConfigured,
    agent.AgentToolResultStatus.stoppedByUser:
        ToolCallResultStatus.stoppedByUser,
  };

  static agent.AgentToolPermissionResult toPermissionResult(
    ToolPermissionResult result,
  ) {
    return switch (result) {
      .granted => agent.AgentToolPermissionResult.granted,
      .needsConfirmation => agent.AgentToolPermissionResult.needsConfirmation,
      .disabledInConversation =>
        agent.AgentToolPermissionResult.disabledInConversation,
      .disabledByAgent => agent.AgentToolPermissionResult.disabledByAgent,
      .disabledInWorkspace =>
        agent.AgentToolPermissionResult.disabledInWorkspace,
      .notConfigured => agent.AgentToolPermissionResult.notConfigured,
    };
  }

  static ToolCallResultStatus toResultStatus(
    agent.AgentToolResultStatus status,
  ) => _resultStatuses[status]!;

  static agent.AgentToolCallLifecycle toLifecycle(
    ToolCallResultStatus? status,
  ) {
    return status?.agentLifecycle ?? agent.AgentToolCallLifecycle.pending;
  }
}
