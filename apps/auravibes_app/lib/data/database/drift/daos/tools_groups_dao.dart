import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups_table.dart';
import 'package:drift/drift.dart';

part 'tools_groups_dao.g.dart';

/// Data Access Object for tool groups.
///
/// Provides CRUD operations for tool groups data in the database.
@DriftAccessor(tables: [ToolsGroups])
class ToolsGroupsDao extends DatabaseAccessor<AppDatabase>
    with _$ToolsGroupsDaoMixin {
  /// Creates a new [ToolsGroupsDao] instance.
  ToolsGroupsDao(super.attachedDatabase);

  /// Insert a new tools group.
  ///
  /// Returns the inserted row.
  Future<ToolsGroupsTable> insertToolsGroup(
    ToolsGroupsCompanion companion,
  ) => into(toolsGroups).insertReturning(companion);

  /// Delete a tools group by ID.
  ///
  /// Tools belonging to this group will be cascade deleted via FK.
  /// Returns true if a row was deleted.
  Future<bool> deleteToolsGroupById(String id) => (delete(
    toolsGroups,
  )..where((t) => t.id.equals(id))).go().then((count) => count > 0);

  /// Get a tools group by its linked MCP server ID.
  ///
  /// Returns the tools group linked to the specified MCP server,
  /// or null if not found.
  Future<ToolsGroupsTable?> getToolsGroupByMcpServerId(String mcpServerId) =>
      (select(
        toolsGroups,
      )..where((t) => t.mcpServerId.equals(mcpServerId))).getSingleOrNull();

  /// Get all tools groups for a workspace.
  ///
  /// Returns all tools groups belonging to the specified workspace,
  /// ordered by creation date (newest first).
  Future<List<ToolsGroupsTable>> getToolsGroupsForWorkspace(
    String workspaceId,
  ) =>
      (select(toolsGroups)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Get a tools group by ID.
  Future<ToolsGroupsTable?> getToolsGroupById(String id) =>
      (select(toolsGroups)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Update the enabled status of a tools group.
  ///
  /// Returns true if a row was updated.
  Future<bool> updateToolsGroupEnabled(String id, {required bool isEnabled}) =>
      (update(toolsGroups)..where((t) => t.id.equals(id)))
          .write(
            ToolsGroupsCompanion(
              isEnabled: Value(isEnabled),
              updatedAt: Value(DateTime.now()),
            ),
          )
          .then((count) => count > 0);
}
