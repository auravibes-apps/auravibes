import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_compaction_settings.dart';
import 'package:drift/drift.dart';

part 'workspace_compaction_settings_dao.g.dart';

@DriftAccessor(tables: [WorkspaceCompactionSettings])
class WorkspaceCompactionSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$WorkspaceCompactionSettingsDaoMixin {
  WorkspaceCompactionSettingsDao(super.attachedDatabase);

  Future<WorkspaceCompactionSettingsTable?> getByWorkspaceId(
    String workspaceId,
  ) {
    return (select(workspaceCompactionSettings)
          ..where((t) => t.workspaceId.equals(workspaceId))
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<WorkspaceCompactionSettingsTable?> watchByWorkspaceId(
    String workspaceId,
  ) {
    return (select(workspaceCompactionSettings)
          ..where((t) => t.workspaceId.equals(workspaceId))
          ..limit(1))
        .watch()
        .map((rows) => rows.isNotEmpty ? rows.first : null);
  }

  Future<WorkspaceCompactionSettingsTable> upsert(
    String workspaceId,
    WorkspaceCompactionSettingsCompanion companion,
  ) async {
    final existing = await getByWorkspaceId(workspaceId);
    if (existing != null) {
      await (update(
        workspaceCompactionSettings,
      )..where((t) => t.id.equals(existing.id))).write(companion);
      return (await getByWorkspaceId(workspaceId))!;
    }
    return into(workspaceCompactionSettings).insertReturning(
      companion.copyWith(workspaceId: Value(workspaceId)),
    );
  }

  Future<void> deleteByWorkspaceId(String workspaceId) async {
    await (delete(
      workspaceCompactionSettings,
    )..where((t) => t.workspaceId.equals(workspaceId))).go();
  }
}
