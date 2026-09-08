import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/agent_tools_repository_contract.dart';
import 'package:auravibes_app/data/repositories/tool_permission_mapper.dart';
import 'package:auravibes_app/domain/entities/agent_tool_override_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';

export 'agent_tools_repository_contract.dart';

class const AgentToolsRepository(final AppDatabase _database)
    implements AgentToolsRepositoryContract {
  @override
  Future<List<AgentToolOverrideEntity>> getAgentTools(String agentId) async {
    final rows = await _database.agentToolsDao.getAgentTools(agentId);

    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<AgentToolOverrideEntity> setAgentToolPermission(
    String agentId,
    String toolId, {
    required ToolPermissionMode permissionMode,
  }) async {
    final row = await _database.agentToolsDao.setAgentToolPermission(
      agentId,
      toolId,
      permission: mapPermissionMode(permissionMode),
    );

    return _mapToEntity(row);
  }

  @override
  Future<bool> clearAgentToolPermission(String agentId, String toolId) {
    return _database.agentToolsDao.clearAgentToolPermission(agentId, toolId);
  }

  AgentToolOverrideEntity _mapToEntity(AgentToolsTable table) {
    return AgentToolOverrideEntity(
      agentId: table.agentId,
      toolId: table.toolId,
      permissionMode: mapPermissionAccess(table.permissions),
    );
  }
}
