// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_compaction_settings.dart';
import 'package:drift/drift.dart';

part 'workspace_compaction_settings_dao.g.dart';

@DriftAccessor(tables: [WorkspaceCompactionSettings])
class WorkspaceCompactionSettingsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with
        _$WorkspaceCompactionSettingsDaoMixin,
        _WorkspaceCompactionSettingsDaoApi;

mixin _WorkspaceCompactionSettingsDaoApi {
  Future<WorkspaceCompactionSettingsTable?> getByWorkspaceId(
    String workspaceId,
  ) => WorkspaceCompactionSettingsDaoMethods(
    this as WorkspaceCompactionSettingsDao,
  ).getByWorkspaceId(workspaceId);

  Stream<WorkspaceCompactionSettingsTable?> watchByWorkspaceId(
    String workspaceId,
  ) => WorkspaceCompactionSettingsDaoMethods(
    this as WorkspaceCompactionSettingsDao,
  ).watchByWorkspaceId(workspaceId);

  Future<WorkspaceCompactionSettingsTable> upsert(
    String workspaceId,
    WorkspaceCompactionSettingsCompanion companion,
  ) => WorkspaceCompactionSettingsDaoMethods(
    this as WorkspaceCompactionSettingsDao,
  ).upsert(workspaceId, companion);

  Future<void> deleteByWorkspaceId(String workspaceId) =>
      WorkspaceCompactionSettingsDaoMethods(
        this as WorkspaceCompactionSettingsDao,
      ).deleteByWorkspaceId(workspaceId);
}

extension WorkspaceCompactionSettingsDaoMethods
    on WorkspaceCompactionSettingsDao {
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
    if (existing == null) {
      return await _insertNew(workspaceId, companion);
    }

    return await _updateAndRead(existing.id, workspaceId, companion);
  }

  Future<int> _updateExisting(
    String id,
    WorkspaceCompactionSettingsCompanion companion,
  ) => (update(
    workspaceCompactionSettings,
  )..where((t) => t.id.equals(id))).write(companion);

  Future<WorkspaceCompactionSettingsTable> _insertNew(
    String workspaceId,
    WorkspaceCompactionSettingsCompanion companion,
  ) =>
      into(workspaceCompactionSettings)
          .insertReturning(companion.copyWith(workspaceId: .new(workspaceId)));

  Future<WorkspaceCompactionSettingsTable> _updateAndRead(
    String id,
    String workspaceId,
    WorkspaceCompactionSettingsCompanion companion,
  ) async {
    final _ = await _updateExisting(id, companion);
    final updated = await getByWorkspaceId(workspaceId);
    if (updated == null) {
      throw StateError('Updated compaction settings were not found');
    }

    return updated;
  }

  Future<void> deleteByWorkspaceId(String workspaceId) async {
    final _ = await (delete(
      workspaceCompactionSettings,
    )..where((t) => t.workspaceId.equals(workspaceId))).go();
  }
}
