// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

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
        .map((rows) => rows.firstOrNull);
  }

  Future<WorkspaceCompactionSettingsTable> upsert(
    String workspaceId,
    WorkspaceCompactionSettingsCompanion companion,
  ) async {
    final existing = await getByWorkspaceId(workspaceId);
    if (existing != null) {
      final _ = await (update(
        workspaceCompactionSettings,
      )..where((t) => t.id.equals(existing.id))).write(companion);
      final updated = await getByWorkspaceId(workspaceId);
      if (updated == null) {
        throw StateError('Updated compaction settings were not found');
      }
      return updated;
    }
    return into(workspaceCompactionSettings).insertReturning(
      companion.copyWith(workspaceId: Value(workspaceId)),
    );
  }

  Future<void> deleteByWorkspaceId(String workspaceId) async {
    final _ = await (delete(
      workspaceCompactionSettings,
    )..where((t) => t.workspaceId.equals(workspaceId))).go();
  }
}
