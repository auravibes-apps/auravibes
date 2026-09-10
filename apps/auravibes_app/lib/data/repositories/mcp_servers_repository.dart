// Required: Existing test and UI helpers keep compact return flow.
import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/mcp_servers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/tools_groups_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/database/drift/tables/mcp_servers.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/database/drift/tables/tools.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups.dart';
import 'package:auravibes_app/data/repositories/mcp_servers_repository_contract.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:drift/drift.dart';

export 'mcp_servers_repository_contract.dart';

final _mcpServerTemplate = McpServerEntity(
  id: '',
  workspaceId: '',
  name: '',
  url: '',
  transport: const McpTransportTypeSSE(),
  authenticationType: const McpAuthenticationTypeNone(),
  createdAt: .new(0),
  updatedAt: .new(0),
);

class McpServersRepository implements McpServersRepositoryContract {
  /// Creates a new [McpServersRepository] instance.
  new(this._database)
    : _mcpServersDao = _database.mcpServersDao,
      _toolsGroupsDao = _database.toolsGroupsDao,
      _workspaceToolsDao = _database.workspaceToolsDao;

  final AppDatabase _database;
  final McpServersDao _mcpServersDao;
  final ToolsGroupsDao _toolsGroupsDao;
  final WorkspaceToolsDao _workspaceToolsDao;

  @override
  Future<McpServerEntity> addMcpServerWithTools({
    required String workspaceId,
    required McpServerToCreate serverToCreate,
    required List<McpToolInfo> tools,
  }) async {
    try {
      // Use a transaction to ensure atomicity.
      return await _database.transaction(
        () => this._addMcpServerWithTools(workspaceId, serverToCreate, tools),
      );
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        McpServersException('Failed to add MCP server with tools.', e),
        stackTrace,
      );
    }
  }

  @override
  Future<bool> deleteMcpServer(String serverId) async {
    try {
      return await _database.transaction(() => this._deleteMcpServer(serverId));
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        McpServersException('Failed to delete MCP server.', e),
        stackTrace,
      );
    }
  }

  @override
  Future<void> syncMcpTools({
    required String mcpServerId,
    required List<McpToolInfo> currentTools,
  }) async {
    try {
      await _database.transaction(
        () => this._syncMcpTools(mcpServerId, currentTools),
      );

      // Note: Existing tools are NOT modified - user customizations preserved.
    } on McpServerNotFoundException {
      rethrow;
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        McpServersException('Failed to sync MCP tools.', e),
        stackTrace,
      );
    }
  }

  @override
  Future<List<McpServerEntity>> getMcpServersForWorkspace(
    String workspaceId,
  ) async {
    try {
      final results = await _mcpServersDao.getMcpServersForWorkspace(
        workspaceId,
      );

      return results.map(this._tableToEntity).toList();
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        McpServersException('Failed to get MCP servers for workspace.', e),
        stackTrace,
      );
    }
  }

  @override
  Future<List<McpServerEntity>> getEnabledMcpServersForWorkspace(
    String workspaceId,
  ) async {
    try {
      final results = await _mcpServersDao.getEnabledMcpServersForWorkspace(
        workspaceId,
      );

      return results.map(this._tableToEntity).toList();
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        McpServersException(
          'Failed to get enabled MCP servers for workspace.',
          e,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<McpServerEntity?> getMcpServerById(String serverId) async {
    try {
      final result = await _mcpServersDao.getMcpServerById(serverId);
      if (result == null) return null;

      return this._tableToEntity(result);
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        McpServersException('Failed to get MCP server by ID.', e),
        stackTrace,
      );
    }
  }
}

extension McpServersRepositoryOperations on McpServersRepository {
  Future<McpServersTable> _insertMcpServer(
    String workspaceId,
    McpServerToCreate serverToCreate,
  ) {
    return _mcpServersDao.insertMcpServer(
      .insert(
        workspaceId: workspaceId,
        name: serverToCreate.name,
        url: serverToCreate.url,
        transport: serverToCreate.transport,
        serviceConnectionId: Value(serverToCreate.serviceConnectionId),
        description: Value(serverToCreate.description),
      ),
    );
  }

  Future<McpServerEntity> _addMcpServerWithTools(
    String workspaceId,
    McpServerToCreate serverToCreate,
    List<McpToolInfo> tools,
  ) async {
    final mcpServer = await _insertMcpServer(workspaceId, serverToCreate);
    final toolsGroup = await _insertToolsGroup(mcpServer, serverToCreate);
    await _insertTools(workspaceId, toolsGroup.id, tools);

    return _tableToEntity(mcpServer);
  }

  Future<bool> _deleteMcpServer(String serverId) async {
    final server = await _mcpServersDao.getMcpServerById(serverId);
    if (server == null) return false;

    final deleted = await _mcpServersDao.deleteMcpServer(serverId);
    await _deleteServiceConnection(server, deleted);

    return deleted;
  }

  Future<void> _deleteServiceConnection(
    McpServersTable server,
    bool serverDeleted,
  ) async {
    final serviceConnectionId = server.serviceConnectionId;
    if (!serverDeleted || serviceConnectionId == null) return;

    await _deleteServiceConnectionById(serviceConnectionId);
  }

  Future<void> _deleteServiceConnectionById(String serviceConnectionId) async {
    final statement = _database.delete(_database.serviceConnections)
      ..where((tbl) => _isMcpServiceConnection(tbl, serviceConnectionId));
    final _ = await statement.go();
  }

  Expression<bool> _isMcpServiceConnection(
    ServiceConnections table,
    String serviceConnectionId,
  ) {
    return table.id.equals(serviceConnectionId) &
        table.kind.equals(ServiceConnectionKindTable.mcpServer.name);
  }

  Future<void> _syncMcpTools(
    String mcpServerId,
    List<McpToolInfo> currentTools,
  ) async {
    final group = await _toolsGroupsDao.getToolsGroupByMcpServerId(mcpServerId);
    if (group == null) throw McpServerNotFoundException(mcpServerId);

    await _syncToolsForGroup(group, currentTools);
  }

  Future<ToolsGroupsTable> _insertToolsGroup(
    McpServersTable server,
    McpServerToCreate serverToCreate,
  ) {
    return _toolsGroupsDao.insertToolsGroup(
      .insert(
        workspaceId: server.workspaceId,
        mcpServerId: Value(server.id),
        name: serverToCreate.name,
        permissions: PermissionAccess.ask,
      ),
    );
  }

  Future<void> _insertTools(
    String workspaceId,
    String toolsGroupId,
    List<McpToolInfo> tools,
  ) async {
    if (tools.isEmpty) return;

    await _workspaceToolsDao.insertToolsBatch(
      _toolCompanions(workspaceId, toolsGroupId, tools),
    );
  }

  List<ToolsCompanion> _toolCompanions(
    String workspaceId,
    String toolsGroupId,
    List<McpToolInfo> tools,
  ) {
    return tools
        .map((tool) => _toolCompanion(workspaceId, toolsGroupId, tool))
        .toList();
  }

  ToolsCompanion _toolCompanion(
    String workspaceId,
    String toolsGroupId,
    McpToolInfo tool,
  ) {
    return ToolsCompanion.insert(
      workspaceId: workspaceId,
      workspaceToolsGroupId: .new(toolsGroupId),
      toolId: tool.toolName,
      description: .new(tool.description),
      inputSchema: .new(jsonEncode(tool.inputSchema)),
      isEnabled: const Value(true),
      permissions: const Value(PermissionAccess.ask),
    );
  }

  Future<void> _syncToolsForGroup(
    ToolsGroupsTable group,
    List<McpToolInfo> currentTools,
  ) async {
    final existingTools = await _workspaceToolsDao.getToolsByGroupId(group.id);
    final toolsToAdd = _toolsToAdd(existingTools, currentTools);
    final toolsToRemove = _toolsToRemove(existingTools, currentTools);

    await _insertTools(group.workspaceId, group.id, toolsToAdd);
    await _removeTools(toolsToRemove);
  }

  List<McpToolInfo> _toolsToAdd(
    List<ToolsTable> existingTools,
    List<McpToolInfo> currentTools,
  ) {
    final existingToolIds = existingTools.map((tool) => tool.toolId).toSet();

    return currentTools
        .where((tool) => !existingToolIds.contains(tool.toolName))
        .toList();
  }

  List<ToolsTable> _toolsToRemove(
    List<ToolsTable> existingTools,
    List<McpToolInfo> currentTools,
  ) {
    final currentToolIds = currentTools.map((tool) => tool.toolName).toSet();

    return existingTools
        .where((tool) => !currentToolIds.contains(tool.toolId))
        .toList();
  }

  Future<void> _removeTools(List<ToolsTable> tools) async {
    for (final tool in tools) {
      final _ = await _workspaceToolsDao.deleteWorkspaceToolById(tool.id);
    }
  }

  /// Convert a database table row to an entity.
  McpServerEntity _tableToEntity(McpServersTable table) {
    return _copyServerDetails(table);
  }

  McpServerEntity _copyServerDetails(McpServersTable table) {
    return _copyServerDates(
      _mcpServerTemplate.copyWith(
        id: table.id,
        workspaceId: table.workspaceId,
        name: table.name,
        url: table.url,
        transport: table.transport,
      ),
      table,
    );
  }

  McpServerEntity _copyServerDates(
    McpServerEntity entity,
    McpServersTable table,
  ) {
    return entity.copyWith(
      createdAt: table.createdAt,
      updatedAt: table.updatedAt,
      serviceConnectionId: table.serviceConnectionId,
      description: table.description,
      isEnabled: table.isEnabled,
    );
  }
}

/// Base exception for MCP servers-related operations.
class McpServersException implements Exception {
  // Cause is optional because not all domain failures wrap an exception.
  // ignore: unnecessary-nullable
  /// Creates a new McpServersException.
  const new(this.message, [this.cause]);

  /// Error message describing the exception.
  final String message;

  /// Optional original exception that caused this exception.
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: ${cause.runtimeType})' : '';

    return 'McpServersException: $message$causedBy';
  }
}

/// Exception thrown when an MCP server is not found.
class McpServerNotFoundException extends McpServersException {
  /// Creates a new McpServerNotFoundException.
  const new(this.serverId, [Exception? cause])
    : super('MCP server "$serverId" not found', cause);

  /// ID of the MCP server that was not found.
  final String serverId;

  @override
  String toString() => super.toString();
}
