import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/agent_tool_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';

class AgentToolsRepository {
  const AgentToolsRepository(this._database);

  final AppDatabase _database;

  Future<List<AgentToolOverrideEntity>> getAgentTools(String agentId) async {
    final rows = await _database.agentToolsDao.getAgentTools(agentId);

    return rows.map(_mapToEntity).toList();
  }

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
      PermissionAccess.ask => ToolPermissionMode.alwaysAsk,
      PermissionAccess.granted => ToolPermissionMode.alwaysAllow,
      PermissionAccess.denied => ToolPermissionMode.alwaysDeny,
    };
  }

  PermissionAccess _mapPermissionMode(ToolPermissionMode mode) {
    return switch (mode) {
      ToolPermissionMode.alwaysAsk => PermissionAccess.ask,
      ToolPermissionMode.alwaysAllow => PermissionAccess.granted,
      ToolPermissionMode.alwaysDeny => PermissionAccess.denied,
    };
  }
}
