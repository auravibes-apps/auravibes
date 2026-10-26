import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_release.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_values.dart';
import 'package:auravibes_app/data/repositories/local_workspace_history_retention.dart';
import 'package:auravibes_app/data/repositories/local_workspace_permanent_delete.dart';
import 'package:auravibes_app/data/repositories/local_workspace_schema_recovery.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_content_report.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_content_report_action.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_revision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:drift/drift.dart';
import 'package:uuid/v7.dart';

class const LocalWorkspaceHistoryRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceHistoryRepository {
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
    final store = _HistoryStore(database, workspaceId);
    await store.authorize(target);
    await LocalWorkspaceHistoryRetention(database, workspaceId).prune();
    final rows = await store.rows(target);

    return await Future.wait(rows.map((row) => _visible(row, target)));
  }

  @override
  Future<String> submitReport(WorkspaceTrashTarget target) =>
      _LocalWorkspaceContentReports(
        database,
        workspaceId,
      ).submit(target, history);

  @override
  Future<List<WorkspaceContentReport>> reports() =>
      _LocalWorkspaceContentReports(database, workspaceId).list();

  @override
  Future<WorkspaceContentReport> resolveReport(
    String reportId,
    WorkspaceContentReportAction action,
  ) => _LocalWorkspaceContentReports(
    database,
    workspaceId,
  ).resolve(reportId, action);

  @override
  Future<void> restore(WorkspaceTrashTarget target, int revision) =>
      database.transaction(
        () => _HistoryStore(database, workspaceId).restore(target, revision),
      );

  @override
  Future<void> permanentlyDelete(WorkspaceTrashTarget target) async {
    await _HistoryStore(database, workspaceId).requireLocal();
    await LocalWorkspaceAssetRelease(database, workspaceId).mutate(
      () => LocalWorkspacePermanentDelete(database, workspaceId)(target),
    );
  }

  Future<WorkspaceRevision> _visible(
    WorkspaceRevisionRow row,
    WorkspaceTrashTarget target,
  ) async {
    final data = await _revisionData(database, workspaceId, row);

    return _revision(row, target, data);
  }
}

class const _LocalWorkspaceContentReports(
  final AppDatabase database,
  final String workspaceId,
) {
  Future<String> submit(
    WorkspaceTrashTarget target,
    Future<List<WorkspaceRevision>> Function(WorkspaceTrashTarget) history,
  ) async {
    final revision = _reportedRevision(await history(target), target.revision);
    if (revision == null) throw const WorkspaceTableException(denied: true);
    final reportId = const UuidV7().generate();
    final _ = await database
        .into(database.workspaceContentReports)
        .insert(_newReport(workspaceId, target, reportId, revision));

    return reportId;
  }

  Future<List<WorkspaceContentReport>> list() async {
    await _requireLocal();
    await LocalWorkspaceHistoryRetention(database, workspaceId).prune();
    final rows = await _reports();

    return rows.map(_contentReport).toList();
  }

  Future<WorkspaceContentReport> resolve(
    String reportId,
    WorkspaceContentReportAction action,
  ) async {
    await _requireLocal();
    final row = await _report(reportId);
    if (row == null) throw const WorkspaceTableException(denied: true);

    return await _resolveRow(row, reportId, action);
  }

  Future<WorkspaceContentReport> _resolveRow(
    WorkspaceContentReportRow row,
    String reportId,
    WorkspaceContentReportAction action,
  ) async {
    final status = _resolvedStatus(action);
    if (row.status != 'submitted') return _existingResolution(row, status);
    if (action == .remove) await _removeReportedContent(row);
    await _updateStatus(reportId, status);

    final updated = await _report(reportId);
    if (updated == null) throw const WorkspaceTableException(conflict: true);

    return _contentReport(updated);
  }

  WorkspaceContentReport _existingResolution(
    WorkspaceContentReportRow row,
    String status,
  ) {
    if (row.status == status) return _contentReport(row);
    throw const WorkspaceTableException(conflict: true);
  }

  Future<void> _removeReportedContent(WorkspaceContentReportRow row) async {
    final trash = LocalWorkspaceTrashRepository(database, workspaceId);
    final target = _reportTarget(row);
    final plan = await trash.preview(target);
    final _ = await trash.trash(target, planToken: plan.planToken);
  }

  Future<void> _updateStatus(String reportId, String status) async {
    final count =
        await (database.update(database.workspaceContentReports)..where(
              (report) => _reportIdentity(report, workspaceId, reportId),
            ))
            .write(_reviewMetadata(status));
    if (count != 1) throw const WorkspaceTableException(conflict: true);
  }

  Future<void> _requireLocal() async {
    final query = database.select(database.workspaces)
      ..where((row) => row.id.equals(workspaceId));
    final workspace = await query.getSingleOrNull();
    if (workspace == null || workspace.type != .local) {
      throw const WorkspaceTableException();
    }
  }

  Future<List<WorkspaceContentReportRow>> _reports() async {
    final query = database.select(database.workspaceContentReports)
      ..where((row) => row.workspaceId.equals(workspaceId))
      ..orderBy([(row) => OrderingTerm.desc(row.submittedAt)]);

    return await query.get();
  }

  Future<WorkspaceContentReportRow?> _report(String reportId) {
    final query = database.select(database.workspaceContentReports)
      ..where((report) => _reportIdentity(report, workspaceId, reportId));

    return query.getSingleOrNull();
  }
}

WorkspaceContentReportsCompanion _reviewMetadata(String status) =>
    WorkspaceContentReportsCompanion(
      status: .new(status),
      reviewerId: const Value('local_user'),
      reviewedAt: .new(DateTime.now().toUtc()),
    );

Expression<bool> _reportIdentity(
  $WorkspaceContentReportsTable report,
  String workspaceId,
  String reportId,
) => report.workspaceId.equals(workspaceId) & report.reportId.equals(reportId);

WorkspaceContentReport _contentReport(WorkspaceContentReportRow row) => .new(
  reportId: row.reportId,
  target: _reportTarget(row),
  status: row.status,
  submittedAt: row.submittedAt,
  conversationId: row.conversationId,
  reviewerUserId: row.reviewerId,
  reviewedAt: row.reviewedAt,
);

WorkspaceTrashTarget _reportTarget(WorkspaceContentReportRow row) => .new(
  kind: row.kind == 'record' ? .record : .table,
  id: row.resourceId,
  revision: row.revision,
  tableId: row.tableId,
);

String _resolvedStatus(WorkspaceContentReportAction action) => switch (action) {
  .dismiss => 'dismissed',
  .remove => 'removed',
};

WorkspaceRevision? _reportedRevision(
  List<WorkspaceRevision> revisions,
  int revision,
) => revisions
    .where((row) => row.target.revision == revision && row.aiInvolved == true)
    .firstOrNull;

WorkspaceContentReportsCompanion _newReport(
  String workspaceId,
  WorkspaceTrashTarget target,
  String reportId,
  WorkspaceRevision revision,
) => WorkspaceContentReportsCompanion.insert(
  workspaceId: workspaceId,
  reportId: reportId,
  kind: target.kind.name,
  resourceId: target.id,
  tableId: .new(target.tableId),
  revision: target.revision,
  conversationId: .new(revision.conversationId),
);

Future<Map<String, dynamic>> _revisionData(
  AppDatabase database,
  String workspaceId,
  WorkspaceRevisionRow row,
) => LocalWorkspaceAssetValues(
  database,
  workspaceId,
).history(jsonDecode(row.data) as Map<String, dynamic>);

WorkspaceRevision _revision(
  WorkspaceRevisionRow row,
  WorkspaceTrashTarget target,
  Map<String, dynamic> data,
) => WorkspaceRevision(
  target: _revisionTarget(target, row.revision),
  data: data,
  actorUserId: row.actorUserId,
  aiInvolved: row.aiInvolved,
  operation: row.operation,
  conversationId: row.conversationId,
  capturedAt: row.capturedAt,
);

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

  Future<void> restore(WorkspaceTrashTarget target, int revision) async {
    await authorize(target);
    await LocalWorkspaceHistoryRetention(database, workspaceId).prune();
    final selected = await snapshot(target, revision);
    await _restoreSnapshot(target, selected);
  }

  Future<void> _restoreSnapshot(
    WorkspaceTrashTarget target,
    Map<String, dynamic> selected,
  ) async {
    if (target.kind == .table) {
      await LocalWorkspaceSchemaRecovery(
        database,
        workspaceId,
      ).restore(target, selected);

      return;
    }
    await restoreRecord(target, selected);
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
