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
    await _syncConnectorTargets(workspaceId);
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
      name: SyncConnectorToolPermissionsUsecase.groupName,
    );
    if (current != null) return current;

    return await _database.toolsGroupsDao.insertToolsGroup(
      .insert(
        workspaceId: workspaceId,
        name: SyncConnectorToolPermissionsUsecase.groupName,
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

extension ConnectorTargetPermissions on SyncConnectorToolPermissionsUsecase {
  Future<void> requireEnabledTarget({
    required String workspaceId,
    required String toolId,
  }) async {
    final tool = await _database.workspaceToolsDao.getWorkspaceToolByToolId(
      workspaceId,
      toolId,
    );
    final group = await _database.toolsGroupsDao.getToolsGroupByName(
      workspaceId: workspaceId,
      name: SyncConnectorToolPermissionsUsecase.groupName,
    );
    await _requireCommandEnabled(group);

    if (_targetDenied(tool)) {
      _denyTarget();
    }
  }

  Never _denyTarget() => throw AgentToolExecutionFailure(
    responseRaw: jsonEncode({
      'error': {
        'code': 'tool_access_denied',
        'message': 'This Connector tool is disabled in workspace settings.',
      },
      'recoverable': true,
    }),
    error: StateError('Connector tool access denied'),
    stackTrace: .current,
    failurePhase: 'connector.authorization',
  );

  Future<void> _syncConnectorTargets(String workspaceId) =>
      _database.transaction(() async {
        for (final connector in connectorDefinitions) {
          await _syncConnector(workspaceId, connector);
        }
      });

  Future<void> _requireCommandEnabled(ToolsGroupsTable? group) async {
    if (_groupDenied(group)) _denyTarget();
    final command = await _executeCommand(group);
    if (command?.isEnabled == false ||
        command?.permissions == PermissionAccess.denied) {
      _denyTarget();
    }
  }

  bool _groupDenied(ToolsGroupsTable? group) =>
      group?.isEnabled == false ||
      group?.permissions == PermissionAccess.denied;
  Future<void> _syncConnector(
    String workspaceId,
    ConnectorDefinition connector,
  ) async {
    for (final tool in connector.tools) {
      if (tool.urlTemplate == null) continue;
      await _syncTarget(workspaceId, connectorToolId(connector, tool), tool);
    }
  }

  Future<void> _syncTarget(
    String workspaceId,
    String id,
    ConnectorToolDefinition tool,
  ) async {
    final existing = await _database.workspaceToolsDao.getWorkspaceToolByToolId(
      workspaceId,
      id,
    );
    if (existing != null) return;
    await _database.workspaceToolsDao.insertToolsBatch([
      _targetCompanion(workspaceId, id, tool),
    ]);
  }

  ToolsCompanion _targetCompanion(
    String workspaceId,
    String id,
    ConnectorToolDefinition tool,
  ) => ToolsCompanion.insert(
    workspaceId: workspaceId,
    toolId: id,
    description: .new(tool.description),
    inputSchema: .new(jsonEncode(tool.inputJsonSchema)),
    isEnabled: const Value(false),
    permissions: const Value(PermissionAccess.granted),
  );
}

bool _targetDenied(ToolsTable? tool) =>
    tool == null ||
    !tool.isEnabled ||
    tool.permissions == PermissionAccess.denied;

extension ConnectorCommandLookup on SyncConnectorToolPermissionsUsecase {
  Future<ToolsTable?> _executeCommand(ToolsGroupsTable? group) async {
    if (group == null) return null;
    final commands = await _database.workspaceToolsDao.getToolsByGroupId(
      group.id,
    );

    return commands
        .where((item) => item.toolId == executeConnectorToolName)
        .firstOrNull;
  }
}
