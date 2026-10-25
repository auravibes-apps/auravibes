import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_release.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_values.dart';
import 'package:auravibes_app/data/repositories/local_workspace_history_retention.dart';
import 'package:auravibes_app/data/repositories/local_workspace_permanent_delete.dart';
import 'package:auravibes_app/data/repositories/local_workspace_schema_recovery.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_revision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceHistoryRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceHistoryRepository {
  _HistoryStore get _store => .new(database, workspaceId);

  @override
  Future<WorkspaceHistoryPolicy> policy() =>
      LocalWorkspaceHistoryRetention(database, workspaceId).policy();
  @override
  Future<void> configure(WorkspaceHistoryPolicy current, int? days) =>
      LocalWorkspaceHistoryRetention(
        database,
        workspaceId,
      ).configure(current, days);

  @override
  Future<List<WorkspaceRevision>> history(WorkspaceTrashTarget target) async {
    await _store.authorize(target);
    await LocalWorkspaceHistoryRetention(database, workspaceId).prune();
    final rows = await _store.rows(target);

    return await Future.wait(rows.map((row) => _visible(row, target)));
  }

  @override
  Future<void> restore(WorkspaceTrashTarget target, int revision) =>
      database.transaction(() => _restore(target, revision));

  @override
  Future<void> permanentlyDelete(WorkspaceTrashTarget target) async {
    await _store.requireLocal();
    await LocalWorkspaceAssetRelease(database, workspaceId).mutate(
      () => LocalWorkspacePermanentDelete(database, workspaceId)(target),
    );
  }

  Future<WorkspaceRevision> _visible(
    WorkspaceRevisionRow row,
    WorkspaceTrashTarget target,
  ) async {
    final data = await LocalWorkspaceAssetValues(
      database,
      workspaceId,
    ).history(jsonDecode(row.data) as Map<String, dynamic>);

    return WorkspaceRevision(
      target: _revisionTarget(target, row.revision),
      data: data,
    );
  }

  Future<void> _restore(WorkspaceTrashTarget target, int revision) async {
    await _store.authorize(target);
    await LocalWorkspaceHistoryRetention(database, workspaceId).prune();
    final selected = await _store.snapshot(target, revision);
    if (target.kind == .table) {
      await LocalWorkspaceSchemaRecovery(
        database,
        workspaceId,
      ).restore(target, selected);

      return;
    }
    await _store.restoreRecord(target, selected);
  }
}

class const _HistoryStore(
  final AppDatabase database,
  final String workspaceId,
) {
  LocalWorkspaceTableRepository get tables => .new(database, workspaceId);

  Future<void> requireLocal() async {
    final query = database.select(database.workspaces)
      ..where((row) => row.id.equals(workspaceId));
    final workspace = await query.getSingleOrNull();
    if (workspace == null || workspace.type != .local) {
      throw const WorkspaceTableException();
    }
  }

  Future<void> authorize(WorkspaceTrashTarget target) async {
    validateWorkspaceTrashTarget(target);
    await requireLocal();
    if (target.kind == .record) {
      final _ = await tables.record(_tableId(target), target.id);

      return;
    }
    if (target.kind != .table) throw const WorkspaceTableException();
    final _ = await tables.table(target.id);
  }

  Future<List<WorkspaceRevisionRow>> rows(WorkspaceTrashTarget target) {
    final query = database.select(database.workspaceRevisions)
      ..where((row) => _RevisionKey(workspaceId, target).matches(row))
      ..orderBy([(row) => OrderingTerm.desc(row.revision)]);

    return query.get();
  }

  Future<void> restoreRecord(
    WorkspaceTrashTarget target,
    Map<String, dynamic> data,
  ) async {
    final table = await tables.table(_tableId(target));
    final record = await tables.record(table.id, target.id);
    WorkspaceRecoveryValidation.revision(record.revision, target.revision);
    final values = _values(data);
    final _ = await tables.updateRecord(
      table: table,
      record: record,
      values: values,
    );
  }

  Future<Map<String, dynamic>> snapshot(
    WorkspaceTrashTarget target,
    int revision,
  ) async {
    final snapshots = await rows(target);

    return _snapshotData(snapshots, revision);
  }
}

class const _RevisionKey(
  final String workspaceId,
  final WorkspaceTrashTarget target,
) {
  Expression<bool> matches($WorkspaceRevisionsTable row) =>
      row.workspaceId.equals(workspaceId) &
      row.kind.equals(target.kind.name) &
      row.resourceId.equals(target.id);
}

WorkspaceTrashTarget _revisionTarget(
  WorkspaceTrashTarget target,
  int revision,
) => .new(
  kind: target.kind,
  id: target.id,
  tableId: target.tableId,
  revision: revision,
);
String _tableId(WorkspaceTrashTarget target) =>
    target.tableId ?? (throw const WorkspaceTableException());

Map<String, Object?> _values(Map<String, dynamic> data) =>
    (data['values'] as Map<String, dynamic>).cast<String, Object?>();

Map<String, dynamic> _snapshotData(
  List<WorkspaceRevisionRow> rows,
  int revision,
) {
  final selected = rows
      .where((row) => row.revision == revision && row.revision > 0)
      .firstOrNull;
  if (selected == null) throw const WorkspaceTableException();

  return jsonDecode(selected.data) as Map<String, dynamic>;
}
