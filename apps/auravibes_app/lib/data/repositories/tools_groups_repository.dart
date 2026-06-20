// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';

/// Implementation of [ToolsGroupsRepository] using Drift database.
class ToolsGroupsRepository {
  /// Creates a new [ToolsGroupsRepository] instance.
  ToolsGroupsRepository(this._database);

  final AppDatabase _database;

  Future<List<ToolsGroupEntity>> getToolsGroupsForWorkspace(
    String workspaceId,
  ) async {
    final rows = await _database.toolsGroupsDao.getToolsGroupsForWorkspace(
      workspaceId,
    );

    return rows.map(_tableToEntity).toList();
  }

  Future<ToolsGroupEntity?> getToolsGroupById(String id) async {
    final row = await _database.toolsGroupsDao.getToolsGroupById(id);

    return row != null ? _tableToEntity(row) : null;
  }

  Future<ToolsGroupEntity?> getToolsGroupByMcpServerId(
    String mcpServerId,
  ) async {
    final row = await _database.toolsGroupsDao.getToolsGroupByMcpServerId(
      mcpServerId,
    );

    return row != null ? _tableToEntity(row) : null;
  }

  Future<bool> setToolsGroupEnabled(
    String groupId, {
    required bool isEnabled,
  }) async {
    return _database.toolsGroupsDao.setToolsGroupEnabled(
      groupId,
      isEnabled: isEnabled,
    );
  }

  Future<bool> deleteToolsGroup(String id) async {
    return _database.toolsGroupsDao.deleteToolsGroupById(id);
  }

  /// Converts a database table row to a domain entity.
  ToolsGroupEntity _tableToEntity(ToolsGroupsTable row) {
    return ToolsGroupEntity(
      id: row.id,
      workspaceId: row.workspaceId,
      name: row.name,
      isEnabled: row.isEnabled,
      permissions: row.permissions,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      mcpServerId: row.mcpServerId,
    );
  }
}
