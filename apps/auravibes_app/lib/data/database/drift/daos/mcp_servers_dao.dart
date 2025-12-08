import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/mcp_servers_table.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups_table.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_table.dart';
import 'package:drift/drift.dart';

part 'mcp_servers_dao.g.dart';

/// Data Access Object for MCP server configurations.
///
/// Provides CRUD operations for MCP server data in the database.
@DriftAccessor(tables: [McpServers, Tools, ToolsGroups])
class McpServersDao extends DatabaseAccessor<AppDatabase>
    with _$McpServersDaoMixin {
  /// Creates a new [McpServersDao] instance.
  McpServersDao(super.attachedDatabase);

  /// Get all MCP servers for a workspace.
  ///
  /// Returns all MCP servers belonging to the specified workspace,
  /// ordered by creation date (newest first).
  Future<List<McpServersTable>> getMcpServersForWorkspace(
    String workspaceId,
  ) =>
      (select(mcpServers)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Get a single MCP server by ID.
  Future<McpServersTable?> getMcpServerById(String id) =>
      (select(mcpServers)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Get all enabled MCP servers for a workspace.
  Future<List<McpServersTable>> getEnabledMcpServersForWorkspace(
    String workspaceId,
  ) =>
      (select(mcpServers)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.isEnabled.equals(true),
          ))
          .get();

  /// Insert a new MCP server.
  ///
  /// Returns the inserted row.
  Future<McpServersTable> insertMcpServer(McpServersCompanion companion) =>
      into(mcpServers).insertReturning(companion);

  /// Update an existing MCP server.
  ///
  /// Returns true if a row was updated.
  Future<bool> updateMcpServer(
    String id,
    McpServersCompanion companion,
  ) async {
    final rowsUpdated = await (update(
      mcpServers,
    )..where((t) => t.id.equals(id))).write(companion);
    return rowsUpdated > 0;
  }

  /// Delete an MCP server by ID.
  ///
  /// Returns true if a row was deleted.
  Future<bool> deleteMcpServer(String id) async {
    return transaction(() async {
      final toolGroup = await (select(
        toolsGroups,
      )..where((tg) => tg.mcpServerId.equals(id))).getSingleOrNull();
      if (toolGroup == null) return false;
      final toolsToDelete = await (select(
        tools,
      )..where((t) => t.workspaceToolsGroupId.equals(toolGroup.id))).get();

      // delete tools
      for (final tool in toolsToDelete) {
        await (delete(tools)..where((t) => t.id.equals(tool.id))).go();
      }
      // delete tool groups
      await (delete(
        toolsGroups,
      )..where((tg) => tg.id.equals(toolGroup.id))).go();
      // delete server

      final rowsDeleted = await (delete(
        mcpServers,
      )..where((t) => t.id.equals(id))).go();
      return rowsDeleted > 0;
    });
  }

  /// Toggle the enabled state of an MCP server.
  ///
  /// Returns the updated row.
  Future<McpServersTable?> toggleMcpServerEnabled(
    String id, {
    required bool isEnabled,
  }) async {
    await (update(mcpServers)..where((t) => t.id.equals(id))).write(
      McpServersCompanion(isEnabled: Value(isEnabled)),
    );
    return getMcpServerById(id);
  }
}
