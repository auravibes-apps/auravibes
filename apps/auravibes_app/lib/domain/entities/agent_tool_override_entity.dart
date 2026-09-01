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
      AgentToolPermissionMode.workspaceDefault => null,
      AgentToolPermissionMode.alwaysAsk => ToolPermissionMode.alwaysAsk,
      AgentToolPermissionMode.alwaysAllow => ToolPermissionMode.alwaysAllow,
      AgentToolPermissionMode.alwaysDeny => ToolPermissionMode.alwaysDeny,
    };
  }
}

extension ToolPermissionModeAgentX on ToolPermissionMode {
  AgentToolPermissionMode get agentMode {
    return switch (this) {
      ToolPermissionMode.alwaysAsk => AgentToolPermissionMode.alwaysAsk,
      ToolPermissionMode.alwaysAllow => AgentToolPermissionMode.alwaysAllow,
      ToolPermissionMode.alwaysDeny => AgentToolPermissionMode.alwaysDeny,
    };
  }
}
