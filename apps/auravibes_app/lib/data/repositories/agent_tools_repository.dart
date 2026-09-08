import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/repositories/agent_tools_repository_contract.dart';
import 'package:auravibes_app/domain/entities/agent_tool_entity.dart';
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
      permission: _mapPermissionMode(permissionMode),
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
      permissionMode: _mapPermissionAccess(table.permissions),
    );
  }

  ToolPermissionMode _mapPermissionAccess(PermissionAccess access) {
    return switch (access) {
      .ask => ToolPermissionMode.alwaysAsk,
      .granted => ToolPermissionMode.alwaysAllow,
      .denied => ToolPermissionMode.alwaysDeny,
    };
  }

  PermissionAccess _mapPermissionMode(ToolPermissionMode mode) {
    return switch (mode) {
      .alwaysAsk => PermissionAccess.ask,
      .alwaysAllow => PermissionAccess.granted,
      .alwaysDeny => PermissionAccess.denied,
    };
  }
}
