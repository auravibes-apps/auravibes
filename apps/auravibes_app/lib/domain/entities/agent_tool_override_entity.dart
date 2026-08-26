import 'package:auravibes_app/domain/entities/agent_tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';

export 'agent_tool_permission_mode.dart';

class AgentToolOverrideEntity {
  const AgentToolOverrideEntity({
    required this.agentId,
    required this.toolId,
    required this.permissionMode,
  });

  final String agentId;
  final String toolId;
  final ToolPermissionMode permissionMode;
}

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
