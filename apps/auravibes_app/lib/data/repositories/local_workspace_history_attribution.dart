import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceHistoryAttribution(final AppDatabase database) {
  Future<void> aiRevision({
    required String workspaceId,
    required String kind,
    required String resourceId,
    required int revision,
    required String conversationId,
  }) async {
    if (conversationId.isEmpty || conversationId.length > 200) {
      throw const FormatException('Invalid conversation context.');
    }
    final updated =
        await (database.update(database.workspaceRevisions)..where(
              (row) =>
                  row.workspaceId.equals(workspaceId) &
                  row.kind.equals(kind) &
                  row.resourceId.equals(resourceId) &
                  row.revision.equals(revision),
            ))
            .write(
              WorkspaceRevisionsCompanion(
                aiInvolved: const Value(true),
                conversationId: .new(conversationId),
              ),
            );
    if (updated != 1) throw const WorkspaceTableException(conflict: true);
  }
}
