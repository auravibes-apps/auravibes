import 'package:auravibes_app/domain/entities/agent_tool_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';

/// Contract for agent tool persistence.
abstract interface class AgentToolsRepositoryContract {
  Future<List<AgentToolOverrideEntity>> getAgentTools(String agentId);

  Future<AgentToolOverrideEntity> setAgentToolPermission(
    String agentId,
    String toolId, {
    required ToolPermissionMode permissionMode,
  });

  Future<bool> clearAgentToolPermission(String agentId, String toolId);
}
