import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/tools.dart';
import 'package:drift/drift.dart';

part 'workspace_tools_dao.g.dart';

@DriftAccessor(tables: [Tools])
class WorkspaceToolsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$WorkspaceToolsDaoMixin {}

extension WorkspaceToolsDaoMethods on WorkspaceToolsDao {
  // Core operations.
  Future<ToolsTable?> getWorkspaceTool(String workspaceId, String id) =>
      (select(tools)..where(
            (tbl) => tbl.workspaceId.equals(workspaceId) & tbl.id.equals(id),
          ))
          .getSingleOrNull();

  Future<ToolsTable?> getWorkspaceToolByToolId(
    String workspaceId,
    String toolId,
  ) =>
      (select(tools)..where(
            (tbl) =>
                tbl.workspaceId.equals(workspaceId) &
                tbl.toolId.equals(toolId) &
                tbl.workspaceToolsGroupId.isNull(),
          ))
          .getSingleOrNull();

  Future<ToolsTable> setWorkspaceToolEnabled(
    String workspaceId,
    String toolId, {
    required bool isEnabled,
  }) async {
    // Check if tool already exists.
    final existing = await getWorkspaceToolByToolId(workspaceId, toolId);

    if (existing == null) {
      return _insertWorkspaceTool(workspaceId, toolId, isEnabled);
    }

    await _updateWorkspaceToolEnabled(workspaceId, toolId, isEnabled);
    final updated = await getWorkspaceToolByToolId(workspaceId, toolId);
    if (updated == null) {
      throw StateError('Updated workspace tool was not found');
    }

    return updated;
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
    await _updateWorkspaceToolById(id, isEnabled);

    return await (select(tools)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<List<ToolsTable>> patchWorkspaceToolConfig(
    String workspaceId,
    String toolId,
    String? config,
  ) => _patchWorkspaceToolConfig(workspaceId, toolId, config);

  Future<bool> deleteWorkspaceToolByToolId(
    String workspaceId,
    String toolId,
  ) async {
    final count =
        await (delete(tools)..where(
              (tbl) =>
                  tbl.workspaceId.equals(workspaceId) &
                  tbl.toolId.equals(toolId) &
                  tbl.workspaceToolsGroupId.isNull(),
            ))
            .go();

    return count > 0;
  }

  Future<bool> deleteWorkspaceTool(String workspaceId, String id) async {
    final count =
        await (delete(tools)..where(
              (tbl) => tbl.workspaceId.equals(workspaceId) & tbl.id.equals(id),
            ))
            .go();

    return count > 0;
  }

  /// Delete a workspace tool by its unique table ID.
  Future<bool> deleteWorkspaceToolById(String id) async {
    final count = await (delete(tools)..where((tbl) => tbl.id.equals(id))).go();

    return count > 0;
  }

  // Query operations.
  Future<List<ToolsTable>> getWorkspaceTools(String workspaceId) =>
      (select(tools)
            ..where((tbl) => tbl.workspaceId.equals(workspaceId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.toolId)]))
          .get();

  Future<List<ToolsTable>> getEnabledWorkspaceTools(String workspaceId) =>
      (select(tools)
            ..where(
              (tbl) =>
                  tbl.workspaceId.equals(workspaceId) &
                  tbl.isEnabled.equals(true),
            )
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.toolId)]))
          .get();

  Future<ToolsTable?> getEnabledToolByToolName({
    required String toolGroupId,
    required String toolName,
  }) => _findEnabledToolByToolName(toolGroupId, toolName);

  Future<void> updateToolMetadata({
    required String id,
    required String description,
    required String inputSchema,
  }) async {
    final updatedCount =
        await (update(tools)..where((tbl) => tbl.id.equals(id))).write(
          ToolsCompanion(
            updatedAt: .new(DateTime.now()),
            description: .new(description),
            inputSchema: .new(inputSchema),
          ),
        );
    if (updatedCount != 1) {
      throw StateError(
        'Expected to update exactly one tool row for id=$id, got $updatedCount',
      );
    }
  }

  Future<bool> isWorkspaceToolEnabled(String workspaceId, String id) async {
    final result = await _enabledWorkspaceToolCount(workspaceId, id);

    return result > 0;
  }

  Future<String?> getWorkspaceToolConfig(String workspaceId, String id) =>
      (selectOnly(tools)
            ..addColumns([tools.config])
            ..where(
              tools.workspaceId.equals(workspaceId) & tools.id.equals(id),
            ))
          .map((row) => row.read(tools.config))
          .getSingleOrNull();

  Future<String?> getWorkspaceToolConfigByToolId(
    String workspaceId,
    String toolId,
  ) =>
      (selectOnly(tools)
            ..addColumns([tools.config])
            ..where(
              tools.workspaceId.equals(workspaceId) &
                  tools.toolId.equals(toolId) &
                  tools.workspaceToolsGroupId.isNull(),
            ))
          .map((row) => row.read(tools.config))
          .getSingleOrNull();

  Future<bool> isWorkspaceToolEnabledByToolId(
    String workspaceId,
    String toolId,
  ) async {
    final result = await _enabledWorkspaceToolCountByToolId(
      workspaceId,
      toolId,
    );

    return result > 0;
  }

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
    await _updateWorkspaceToolPermission(id, permission);

    return await (select(tools)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  // ============================================================.
  // Batch Operations (for MCP tools.)
  // ============================================================.

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

  Future<ToolsTable> _insertWorkspaceTool(
    String workspaceId,
    String toolId,
    bool isEnabled,
  ) => into(tools).insertReturning(
    ToolsCompanion(
      workspaceId: .new(workspaceId),
      toolId: .new(toolId),
      isEnabled: .new(isEnabled),
    ),
  );

  Future<int> _updateWorkspaceToolEnabled(
    String workspaceId,
    String toolId,
    bool isEnabled,
  ) {
    final statement = update(tools)
      ..where((tbl) => _nativeWorkspaceToolFilter(tbl, workspaceId, toolId));

    return statement.write(
      ToolsCompanion(
        updatedAt: .new(DateTime.now()),
        isEnabled: .new(isEnabled),
      ),
    );
  }

  Future<int> _updateWorkspaceToolById(String id, bool isEnabled) =>
      (update(tools)..where((tbl) => tbl.id.equals(id))).write(
        ToolsCompanion(
          updatedAt: .new(DateTime.now()),
          isEnabled: .new(isEnabled),
        ),
      );

  Future<List<ToolsTable>> _patchWorkspaceToolConfig(
    String workspaceId,
    String toolId,
    String? config,
  ) {
    final statement = update(tools)
      ..where((tbl) => _nativeWorkspaceToolFilter(tbl, workspaceId, toolId));

    return statement.writeReturning(
      ToolsCompanion(updatedAt: .new(DateTime.now()), config: .new(config)),
    );
  }

  Future<ToolsTable?> _findEnabledToolByToolName(
    String toolGroupId,
    String toolName,
  ) {
    final statement = select(
      tools,
    )..where((tbl) => _enabledToolByToolNameFilter(tbl, toolGroupId, toolName));

    return statement.getSingleOrNull();
  }

  Future<int> _enabledWorkspaceToolCount(String workspaceId, String id) =>
      _countSelectedTools(
        (tbl) => _enabledWorkspaceToolFilter(tbl, workspaceId, id),
      );

  Future<int> _enabledWorkspaceToolCountByToolId(
    String workspaceId,
    String toolId,
  ) => _countSelectedTools(
    (tbl) => _enabledWorkspaceToolByToolIdFilter(tbl, workspaceId, toolId),
  );

  Future<int> _updateWorkspaceToolPermission(
    String id,
    PermissionAccess permission,
  ) => (update(tools)..where((tbl) => tbl.id.equals(id))).write(
    ToolsCompanion(
      updatedAt: .new(DateTime.now()),
      permissions: .new(permission),
    ),
  );

  Future<int> _countSelectedTools(
    Expression<bool> Function($ToolsTable) filter,
  ) {
    final statement = selectOnly(tools)
      ..addColumns([tools.id.count()])
      ..where(filter(tools));

    return statement.map((row) => row.read(tools.id.count()) ?? 0).getSingle();
  }

  Expression<bool> _nativeWorkspaceToolFilter(
    $ToolsTable tbl,
    String workspaceId,
    String toolId,
  ) =>
      tbl.workspaceId.equals(workspaceId) &
      tbl.toolId.equals(toolId) &
      tbl.workspaceToolsGroupId.isNull();

  Expression<bool> _enabledToolByToolNameFilter(
    $ToolsTable tbl,
    String toolGroupId,
    String toolName,
  ) =>
      tbl.workspaceToolsGroupId.equals(toolGroupId) &
      tbl.toolId.equals(toolName) &
      tbl.isEnabled.equals(true);

  Expression<bool> _enabledWorkspaceToolFilter(
    $ToolsTable tbl,
    String workspaceId,
    String id,
  ) =>
      tbl.workspaceId.equals(workspaceId) &
      tbl.id.equals(id) &
      tbl.isEnabled.equals(true);

  Expression<bool> _enabledWorkspaceToolByToolIdFilter(
    $ToolsTable tbl,
    String workspaceId,
    String toolId,
  ) =>
      _nativeWorkspaceToolFilter(tbl, workspaceId, toolId) &
      tbl.isEnabled.equals(true);
}
