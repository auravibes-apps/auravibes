import 'package:auravibes_app/domain/entities/agent_tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';

export 'agent_tool_permission_mode.dart';

class const AgentToolOverrideEntity({
  required final String agentId,
  required final String toolId,
  required final ToolPermissionMode permissionMode,
});

extension AgentToolPermissionModeX on AgentToolPermissionMode {
  ToolPermissionMode? get overridePermission {
    return switch (this) {
      .workspaceDefault => null,
      .alwaysAsk => ToolPermissionMode.alwaysAsk,
      .alwaysAllow => ToolPermissionMode.alwaysAllow,
      .alwaysDeny => ToolPermissionMode.alwaysDeny,
    };
  }
}

extension ToolPermissionModeAgentX on ToolPermissionMode {
  AgentToolPermissionMode get agentMode {
    return switch (this) {
      .alwaysAsk => AgentToolPermissionMode.alwaysAsk,
      .alwaysAllow => AgentToolPermissionMode.alwaysAllow,
      .alwaysDeny => AgentToolPermissionMode.alwaysDeny,
    };
  }
}
