import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';

class const LocalWorkspacePurgeGuard(
  final AppDatabase database,
  final String workspaceId,
) {
  Future<void> view(String id) async {
    final query = database.select(database.workspaceRevisions)
      ..where(_PurgeKey(workspaceId, id).matches);
    if (await query.getSingleOrNull() != null) {
      throw const WorkspaceTableException(conflict: true);
    }
  }
}

class const _PurgeKey(final String workspaceId, final String id) {
  Expression<bool> matches($WorkspaceRevisionsTable row) =>
      row.workspaceId.equals(workspaceId) &
      row.kind.equals('view') &
      row.resourceId.equals(id) &
      row.revision.equals(0);
}
