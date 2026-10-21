import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';

class const SyncConnectorToolPermissionsUsecase(final AppDatabase _database) {
  static const groupName = 'Connector tools';

  Future<void> call({required String workspaceId}) async {
    final _ = await _syncTools(workspaceId);
  }

  Future<String?> permissionTableIdFor({
    required String workspaceId,
    required String toolName,
  }) async {
    final tools = await _syncTools(workspaceId);
    for (final tool in tools) {
      if (tool.toolId == toolName) return tool.id;
    }

    return null;
  }

  Future<List<ToolsTable>> _syncTools(String workspaceId) =>
      _database.transaction(() => _syncToolsInTransaction(workspaceId));

  Future<List<ToolsTable>> _syncToolsInTransaction(String workspaceId) async {
    final group = await _getOrCreateGroup(workspaceId);
    final existing = await _database.workspaceToolsDao.getToolsByGroupId(
      group.id,
    );
    final inserted = await _syncToolSpecs(workspaceId, group.id, existing);
    if (!inserted) return existing;

    return await _database.workspaceToolsDao.getToolsByGroupId(group.id);
  }

  Future<ToolsGroupsTable> _getOrCreateGroup(String workspaceId) async {
    final current = await _database.toolsGroupsDao.getToolsGroupByName(
      workspaceId: workspaceId,
      name: groupName,
    );
    if (current != null) return current;

    return await _database.toolsGroupsDao.insertToolsGroup(
      .insert(
        workspaceId: workspaceId,
        name: groupName,
        permissions: PermissionAccess.ask,
      ),
    );
  }

  Future<bool> _syncToolSpecs(
    String workspaceId,
    String groupId,
    List<ToolsTable> existing,
  ) async {
    final toolsByName = {for (final tool in existing) tool.toolId: tool};
    var inserted = false;
    for (final spec in buildConnectorCommandToolSpecs()) {
      inserted =
          await _syncToolSpec(workspaceId, groupId, spec, toolsByName) ||
          inserted;
    }

    return inserted;
  }

  Future<bool> _syncToolSpec(
    String workspaceId,
    String groupId,
    ToolSpec spec,
    Map<String, ToolsTable> toolsByName,
  ) async {
    final inputSchema = jsonEncode(spec.inputJsonSchema);
    final current = toolsByName[spec.name];
    if (current == null) {
      await _insertTool(workspaceId, groupId, spec, inputSchema);

      return true;
    }

    await _updateToolMetadataIfNeeded(current, spec, inputSchema);

    return false;
  }

  Future<void> _insertTool(
    String workspaceId,
    String groupId,
    ToolSpec spec,
    String inputSchema,
  ) => _database.workspaceToolsDao.insertToolsBatch([
    ToolsCompanion.insert(
      workspaceId: workspaceId,
      workspaceToolsGroupId: .new(groupId),
      toolId: spec.name,
      description: .new(spec.description),
      inputSchema: .new(inputSchema),
      isEnabled: const Value(true),
      permissions: const Value(PermissionAccess.ask),
    ),
  ]);

  Future<void> _updateToolMetadataIfNeeded(
    ToolsTable current,
    ToolSpec spec,
    String inputSchema,
  ) async {
    if (current.description == spec.description &&
        current.inputSchema == inputSchema) {
      return;
    }

    await _database.workspaceToolsDao.updateToolMetadata(
      id: current.id,
      description: spec.description,
      inputSchema: inputSchema,
    );
  }
}

final syncConnectorToolPermissionsUsecaseProvider =
    Provider<SyncConnectorToolPermissionsUsecase>(
      (ref) =>
          SyncConnectorToolPermissionsUsecase(ref.watch(appDatabaseProvider)),
    );
