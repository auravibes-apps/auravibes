// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/mcp_servers.dart';
import 'package:drift/drift.dart';

part 'mcp_servers_dao.g.dart';

/// Data Access Object for MCP server configurations.
///
/// Provides CRUD operations for MCP server data in the database.
@DriftAccessor(tables: [McpServers])
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

  /// Delete an MCP server by ID.
  ///
  /// Returns true if a row was deleted.
  Future<bool> deleteMcpServer(String id) async {
    final rowsDeleted = await (delete(
      mcpServers,
    )..where((t) => t.id.equals(id))).go();

    return rowsDeleted > 0;
  }

  /// Toggle the enabled state of an MCP server.
  ///
  /// Returns the updated row.
  Future<McpServersTable?> toggleMcpServerEnabled(
    String id, {
    required bool isEnabled,
  }) async {
    final _ = await (update(mcpServers)..where((t) => t.id.equals(id))).write(
      McpServersCompanion(isEnabled: Value(isEnabled)),
    );

    return getMcpServerById(id);
  }
}
