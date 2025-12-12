import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/mcp_servers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/tools_groups_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/database/drift/tables/mcp_servers_table.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups_table.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_table.dart';
import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/domain/repositories/mcp_servers_repository.dart';
import 'package:drift/drift.dart';

/// Implementation of the McpServersRepository
class McpServersRepositoryImpl implements McpServersRepository {
  /// Creates a new [McpServersRepositoryImpl] instance.
  McpServersRepositoryImpl(this._database) {
    _mcpServersDao = _database.mcpServersDao;
    _toolsGroupsDao = _database.toolsGroupsDao;
    _workspaceToolsDao = _database.workspaceToolsDao;
  }

  final AppDatabase _database;
  late McpServersDao _mcpServersDao;
  late ToolsGroupsDao _toolsGroupsDao;
  late WorkspaceToolsDao _workspaceToolsDao;

  @override
  Future<McpServerEntity> addMcpServerWithTools({
    required String workspaceId,
    required McpServerToCreate serverToCreate,
    required List<McpToolInfo> tools,
  }) async {
    try {
      // Use a transaction to ensure atomicity
      return await _database.transaction(() async {
        // 1. Insert the MCP server
        final mcpServer = await _mcpServersDao.insertMcpServer(
          McpServersCompanion.insert(
            workspaceId: workspaceId,
            name: serverToCreate.name,
            url: serverToCreate.url,
            transport: serverToCreate.transport,
            authenticationType: serverToCreate.authenticationType,
            description: Value(serverToCreate.description),
          ),
        );

        // 2. Create a ToolsGroup with the MCP server name
        final toolsGroup = await _toolsGroupsDao.insertToolsGroup(
          ToolsGroupsCompanion.insert(
            workspaceId: workspaceId,
            mcpServerId: Value(mcpServer.id),
            name: serverToCreate.name,
            permissions: PermissionAccess.ask,
          ),
        );

        // 3. Insert all tools with the group ID
        if (tools.isNotEmpty) {
          final toolCompanions = tools.map((tool) {
            return ToolsCompanion.insert(
              workspaceId: workspaceId,
              workspaceToolsGroupId: Value(toolsGroup.id),
              toolId: tool.toolName,
              description: Value(tool.description),
              inputSchema: Value(jsonEncode(tool.inputSchema)),
              isEnabled: const Value(true),
              permissions: const Value(PermissionAccess.ask),
            );
          }).toList();

          await _workspaceToolsDao.insertToolsBatch(toolCompanions);
        }

        return _tableToEntity(mcpServer);
      });
    } on Exception catch (e) {
      throw McpServersException(
        'Failed to add MCP server with tools: $e',
        e,
      );
    }
  }

  @override
  Future<bool> deleteMcpServer(String serverId) async {
    try {
      // The cascade delete will handle ToolsGroup and Tools
      return await _mcpServersDao.deleteMcpServer(serverId);
    } on Exception catch (e) {
      throw McpServersException(
        'Failed to delete MCP server: $e',
        e,
      );
    }
  }

  @override
  Future<void> syncMcpTools({
    required String mcpServerId,
    required List<McpToolInfo> currentTools,
  }) async {
    try {
      // 1. Get the tools group for this MCP
      final group = await _toolsGroupsDao.getToolsGroupByMcpServerId(
        mcpServerId,
      );
      if (group == null) {
        throw McpServerNotFoundException(mcpServerId);
      }

      // 2. Get existing tools for this group
      final existingTools = await _workspaceToolsDao.getToolsByGroupId(
        group.id,
      );
      final existingToolIds = existingTools.map((t) => t.toolId).toSet();
      final currentToolIds = currentTools.map((t) => t.toolName).toSet();

      // 3. Find tools to add (in current but not in existing)
      final toolsToAdd = currentTools
          .where((t) => !existingToolIds.contains(t.toolName))
          .toList();

      // 4. Find tools to remove (in existing but not in current)
      final toolsToRemove = existingTools
          .where((t) => !currentToolIds.contains(t.toolId))
          .toList();

      // 5. Add new tools (enabled by default, permission = ask)
      if (toolsToAdd.isNotEmpty) {
        final toolCompanions = toolsToAdd.map((tool) {
          return ToolsCompanion.insert(
            workspaceId: group.workspaceId,
            workspaceToolsGroupId: Value(group.id),
            toolId: tool.toolName,
            description: Value(tool.description),
            inputSchema: Value(jsonEncode(tool.inputSchema)),
            isEnabled: const Value(true),
            permissions: const Value(PermissionAccess.ask),
          );
        }).toList();

        await _workspaceToolsDao.insertToolsBatch(toolCompanions);
      }

      // 6. Remove old tools
      for (final tool in toolsToRemove) {
        await _workspaceToolsDao.deleteWorkspaceToolById(tool.id);
      }

      // Note: Existing tools are NOT modified - user customizations preserved
    } on McpServerNotFoundException {
      rethrow;
    } on Exception catch (e) {
      throw McpServersException(
        'Failed to sync MCP tools: $e',
        e,
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
      return results.map(_tableToEntity).toList();
    } on Exception catch (e) {
      throw McpServersException(
        'Failed to get MCP servers for workspace: $e',
        e,
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
      return results.map(_tableToEntity).toList();
    } on Exception catch (e) {
      throw McpServersException(
        'Failed to get enabled MCP servers for workspace: $e',
        e,
      );
    }
  }

  @override
  Future<McpServerEntity?> getMcpServerById(String serverId) async {
    try {
      final result = await _mcpServersDao.getMcpServerById(serverId);
      if (result == null) return null;
      return _tableToEntity(result);
    } on Exception catch (e) {
      throw McpServersException(
        'Failed to get MCP server by ID: $e',
        e,
      );
    }
  }

  /// Convert a database table row to an entity.
  McpServerEntity _tableToEntity(McpServersTable table) {
    return McpServerEntity(
      id: table.id,
      workspaceId: table.workspaceId,
      name: table.name,
      url: table.url,
      transport: table.transport,
      authenticationType: table.authenticationType,
      createdAt: table.createdAt,
      updatedAt: table.updatedAt,
      description: table.description,
      isEnabled: table.isEnabled,
    );
  }
}
