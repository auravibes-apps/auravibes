import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_agent_hook_settings.dart';
import 'package:drift/drift.dart';

part 'workspace_agent_hook_settings_dao.g.dart';

@DriftAccessor(tables: [WorkspaceAgentHookSettings])
class WorkspaceAgentHookSettingsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$WorkspaceAgentHookSettingsDaoMixin {
  Future<WorkspaceAgentHookSettingsTable?> getByWorkspaceId(
    String workspaceId,
  ) => (select(
    workspaceAgentHookSettings,
  )..where((row) => row.workspaceId.equals(workspaceId))).getSingleOrNull();

  Stream<WorkspaceAgentHookSettingsTable?> watchByWorkspaceId(
    String workspaceId,
  ) =>
      (select(workspaceAgentHookSettings)
            ..where((row) => row.workspaceId.equals(workspaceId)))
          .watch()
          .map((rows) => rows.firstOrNull);

  Future<WorkspaceAgentHookSettingsTable> save(
    String workspaceId,
    WorkspaceAgentHookSettingsCompanion companion,
  ) async {
    final existing = await getByWorkspaceId(workspaceId);
    if (existing == null) {
      return await _insert(workspaceId, companion);
    }

    return await _update(workspaceId, companion);
  }

  Future<WorkspaceAgentHookSettingsTable> _insert(
    String workspaceId,
    WorkspaceAgentHookSettingsCompanion companion,
  ) =>
      into(workspaceAgentHookSettings)
          .insertReturning(companion.copyWith(workspaceId: .new(workspaceId)));

  Future<WorkspaceAgentHookSettingsTable> _update(
    String workspaceId,
    WorkspaceAgentHookSettingsCompanion companion,
  ) async {
    final _ =
        await (update(workspaceAgentHookSettings)
              ..where((row) => row.workspaceId.equals(workspaceId)))
            .write(companion.copyWith(workspaceId: const .absent()));
    final updated = await getByWorkspaceId(workspaceId);
    if (updated == null) {
      throw StateError('Updated lifecycle hook settings were not found');
    }

    return updated;
  }
}
