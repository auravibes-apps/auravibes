import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

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

  Future<void> prune() => database.customStatement(
    '''
DELETE FROM workspace_revisions WHERE workspace_id = ? AND revision > 0
AND (CAST(strftime('%s', 'now') AS INTEGER) - captured_at) / 86400 >=
(SELECT days FROM workspace_history_policies WHERE workspace_id = ?)
''',
    [workspaceId, workspaceId],
  );

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
