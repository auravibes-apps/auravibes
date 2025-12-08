import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';

/// Implementation of [ToolsGroupsRepository] using Drift database.
class ToolsGroupsRepositoryImpl implements ToolsGroupsRepository {
  /// Creates a new [ToolsGroupsRepositoryImpl] instance.
  ToolsGroupsRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<ToolsGroupEntity>> getToolsGroupsForWorkspace(
    String workspaceId,
  ) async {
    final rows = await _database.toolsGroupsDao.getToolsGroupsForWorkspace(
      workspaceId,
    );
    return rows.map(_tableToEntity).toList();
  }

  @override
  Future<ToolsGroupEntity?> getToolsGroupById(String id) async {
    final row = await _database.toolsGroupsDao.getToolsGroupById(id);
    return row != null ? _tableToEntity(row) : null;
  }

  @override
  Future<ToolsGroupEntity?> getToolsGroupByMcpServerId(
    String mcpServerId,
  ) async {
    final row = await _database.toolsGroupsDao.getToolsGroupByMcpServerId(
      mcpServerId,
    );
    return row != null ? _tableToEntity(row) : null;
  }

  @override
  Future<bool> setToolsGroupEnabled(
    String groupId, {
    required bool isEnabled,
  }) async {
    return _database.toolsGroupsDao.updateToolsGroupEnabled(
      groupId,
      isEnabled: isEnabled,
    );
  }

  @override
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
