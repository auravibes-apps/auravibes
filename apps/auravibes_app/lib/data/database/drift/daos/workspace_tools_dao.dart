import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_table.dart';
import 'package:drift/drift.dart';

part 'workspace_tools_dao.g.dart';

@DriftAccessor(tables: [Tools])
class WorkspaceToolsDao extends DatabaseAccessor<AppDatabase>
    with _$WorkspaceToolsDaoMixin {
  WorkspaceToolsDao(super.attachedDatabase);

  // Core operations
  Future<ToolsTable?> getWorkspaceTool(
    String workspaceId,
    String id,
  ) =>
      (select(tools)..where(
            (tbl) => tbl.workspaceId.equals(workspaceId) & tbl.id.equals(id),
          ))
          .getSingleOrNull();

  Future<ToolsTable> setWorkspaceToolEnabled(
    String workspaceId,
    String toolId, {
    required bool isEnabled,
  }) async {
    // Check if tool already exists
    final existing = await getWorkspaceTool(workspaceId, toolId);

    if (existing != null) {
      // Update existing tool
      await (update(tools)..where(
            (tbl) =>
                tbl.workspaceId.equals(workspaceId) & tbl.toolId.equals(toolId),
          ))
          .write(
            ToolsCompanion(
              isEnabled: Value(isEnabled),
              updatedAt: Value(DateTime.now()),
            ),
          );
      // Return updated tool
      return (await getWorkspaceTool(workspaceId, toolId))!;
    } else {
      // Insert new tool
      return into(tools).insertReturning(
        ToolsCompanion(
          workspaceId: Value(workspaceId),
          toolId: Value(toolId),
          isEnabled: Value(isEnabled),
        ),
      );
    }
  }

  /// Sets the enabled status of a workspace tool by its unique table ID.
  ///
  /// [id] The unique ID of the tool record in the database.
  /// [isEnabled] Whether the tool should be enabled.
  /// Returns the updated tool record.
  Future<ToolsTable> setWorkspaceToolEnabledById(
    String id, {
    required bool isEnabled,
  }) async {
    await (update(tools)..where((tbl) => tbl.id.equals(id))).write(
      ToolsCompanion(
        isEnabled: Value(isEnabled),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return (select(tools)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<List<ToolsTable>> updateWorkspaceToolConfig(
    String workspaceId,
    String toolId,
    String? config,
  ) {
    return update(tools).writeReturning(
      ToolsCompanion(
        workspaceId: Value(workspaceId),
        toolId: Value(toolId),
        config: Value(config),
      ),
    );
  }

  Future<bool> deleteWorkspaceTool(String workspaceId, String id) =>
      (delete(tools)..where(
            (tbl) => tbl.workspaceId.equals(workspaceId) & tbl.id.equals(id),
          ))
          .go()
          .then((count) => count > 0);

  /// Delete a workspace tool by its unique table ID
  Future<bool> deleteWorkspaceToolById(String id) => (delete(
    tools,
  )..where((tbl) => tbl.id.equals(id))).go().then((count) => count > 0);

  // Query operations
  Future<List<ToolsTable>> getWorkspaceTools(String workspaceId) =>
      (select(tools)
            ..where((tbl) => tbl.workspaceId.equals(workspaceId))
            ..orderBy([
              (tbl) => OrderingTerm(expression: tbl.toolId),
            ]))
          .get();

  Future<List<ToolsTable>> getEnabledWorkspaceTools(
    String workspaceId,
  ) =>
      (select(tools)
            ..where(
              (tbl) =>
                  tbl.workspaceId.equals(workspaceId) &
                  tbl.isEnabled.equals(true),
            )
            ..orderBy([
              (tbl) => OrderingTerm(expression: tbl.toolId),
            ]))
          .get();

  Future<ToolsTable?> getEnabledToolByToolName({
    required String toolGroupId,
    required String toolName,
  }) =>
      (select(tools)
            ..where(
              (tbl) =>
                  tbl.workspaceToolsGroupId.equals(toolGroupId) &
                  tbl.toolId.equals(toolName) &
                  tbl.isEnabled.equals(true),
            )
            ..orderBy([
              (tbl) => OrderingTerm(expression: tbl.toolId),
            ]))
          .getSingleOrNull();

  Future<bool> isWorkspaceToolEnabled(String workspaceId, String id) =>
      (selectOnly(tools)
            ..addColumns([tools.id.count()])
            ..where(
              tools.workspaceId.equals(workspaceId) &
                  tools.id.equals(id) &
                  tools.isEnabled.equals(true),
            ))
          .map((row) => row.read(tools.id.count()) ?? 0)
          .getSingle()
          .then((result) => result > 0);

  Future<String?> getWorkspaceToolConfig(String workspaceId, String id) =>
      (selectOnly(tools)
            ..addColumns([tools.config])
            ..where(
              tools.workspaceId.equals(workspaceId) & tools.id.equals(id),
            ))
          .map((row) => row.read(tools.config))
          .getSingleOrNull();

  Future<int> getWorkspaceToolsCount(String workspaceId) =>
      (selectOnly(tools)
            ..addColumns([tools.id.count()])
            ..where(tools.workspaceId.equals(workspaceId)))
          .map((row) => row.read(tools.id.count()) ?? 0)
          .getSingle();

  Future<int> getEnabledWorkspaceToolsCount(String workspaceId) =>
      (selectOnly(tools)
            ..addColumns([tools.id.count()])
            ..where(
              tools.workspaceId.equals(workspaceId) &
                  tools.isEnabled.equals(true),
            ))
          .map((row) => row.read(tools.id.count()) ?? 0)
          .getSingle();

  Future<ToolsTable> setWorkspaceToolPermission(
    String id, {
    required PermissionAccess permission,
  }) async {
    await (update(tools)..where((tbl) => tbl.id.equals(id))).write(
      ToolsCompanion(
        permissions: Value(permission),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return (select(
      tools,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  // ============================================================
  // Batch Operations (for MCP tools)
  // ============================================================

  /// Insert multiple tools at once (batch insert).
  ///
  /// Used when adding tools from an MCP server.
  Future<void> insertToolsBatch(List<ToolsCompanion> companions) =>
      batch((b) => b.insertAll(tools, companions));

  /// Delete all tools belonging to a specific group.
  ///
  /// Returns the number of deleted rows.
  Future<int> deleteToolsByGroupId(String groupId) => (delete(
    tools,
  )..where((tbl) => tbl.workspaceToolsGroupId.equals(groupId))).go();

  /// Get all tools for a specific group.
  ///
  /// Used to compare existing tools with new tools from MCP.
  Future<List<ToolsTable>> getToolsByGroupId(String groupId) =>
      (select(tools)
            ..where((tbl) => tbl.workspaceToolsGroupId.equals(groupId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.toolId)]))
          .get();
}
