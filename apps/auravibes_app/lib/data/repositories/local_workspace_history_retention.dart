import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_release.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceHistoryRetention(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceHistoryPolicyRepository {
  @override
  Future<WorkspaceHistoryPolicy> policy() async {
    await _authorize();
    final row = await _row();

    return WorkspaceHistoryPolicy(
      days: row?.days,
      revision: row?.revision ?? 0,
    );
  }

  @override
  Future<void> configure(WorkspaceHistoryPolicy current, int? days) =>
      database.transaction(() async {
        WorkspaceHistoryPolicy.validate(days);
        final actual = await policy();
        _requireRevision(actual, current);
        await _write(actual, days);
        await prune();
      });

  Future<void> prune() async {
    final days = (await _row())?.days;
    if (days == null || !await _expired(days)) return;
    await LocalWorkspaceAssetRelease(database, workspaceId).mutate(_prune);
  }

  Future<bool> _expired(int days) async {
    final rows = await database
        .customSelect(
          '''
SELECT 1 FROM workspace_revisions WHERE workspace_id = ? AND revision > 0
AND (CAST(strftime('%s', 'now') AS INTEGER) - captured_at) / 86400 >= ?
LIMIT 1
''',
          variables: [Variable(workspaceId), Variable(days)],
        )
        .get();

    return rows.isNotEmpty;
  }

  Future<void> _prune() async {
    await database.customStatement(
      '''
DELETE FROM workspace_revisions WHERE workspace_id = ? AND revision > 0
AND (CAST(strftime('%s', 'now') AS INTEGER) - captured_at) / 86400 >=
(SELECT days FROM workspace_history_policies WHERE workspace_id = ?)
''',
      [workspaceId, workspaceId],
    );
    await database.customStatement(
      '''
DELETE FROM workspace_content_reports WHERE workspace_id = ?
AND NOT EXISTS (
SELECT 1 FROM workspace_revisions AS retained
WHERE retained.workspace_id = workspace_content_reports.workspace_id
AND retained.kind = workspace_content_reports.kind
AND retained.resource_id = workspace_content_reports.resource_id
AND retained.revision = workspace_content_reports.revision
)
''',
      [workspaceId],
    );
  }

  Future<WorkspaceHistoryPolicyRow?> _row() => (database.select(
    database.workspaceHistoryPolicies,
  )..where((row) => row.workspaceId.equals(workspaceId))).getSingleOrNull();

  Future<void> _authorize() async {
    final query = database.select(database.workspaces)
      ..where((row) => row.id.equals(workspaceId));
    final workspace = await query.getSingleOrNull();
    if (workspace == null || workspace.type != .local) {
      throw const WorkspaceTableException();
    }
  }

  Future<void> _write(WorkspaceHistoryPolicy current, int? days) async {
    final value = WorkspaceHistoryPoliciesCompanion.insert(
      workspaceId: workspaceId,
      days: .new(days),
      revision: .new(current.revision + 1),
    );
    final _ = await database
        .into(database.workspaceHistoryPolicies)
        .insertOnConflictUpdate(value);
  }
}

void _requireRevision(
  WorkspaceHistoryPolicy actual,
  WorkspaceHistoryPolicy expected,
) {
  if (actual.revision != expected.revision) {
    throw const WorkspaceTableException(conflict: true);
  }
}
