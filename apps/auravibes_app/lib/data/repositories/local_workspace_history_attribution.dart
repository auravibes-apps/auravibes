import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';

typedef WorkspaceRevisionIdentity = ({
  String workspaceId,
  String kind,
  String resourceId,
  int revision,
});

class const LocalWorkspaceHistoryAttribution(final AppDatabase database) {
  Future<void> aiRevision({
    required WorkspaceRevisionIdentity identity,
    required String conversationId,
  }) async {
    if (conversationId.isEmpty || conversationId.length > 200) {
      throw const FormatException('Invalid conversation context.');
    }
    if (await _setAiAttribution(identity, conversationId) != 1) {
      throw const WorkspaceTableException(conflict: true);
    }
  }

  Future<int> _setAiAttribution(
    WorkspaceRevisionIdentity identity,
    String conversationId,
  ) =>
      (database.update(
        database.workspaceRevisions,
      )..where((row) => _matches(row, identity))).write(
        WorkspaceRevisionsCompanion(
          aiInvolved: const Value(true),
          conversationId: .new(conversationId),
        ),
      );
}

Expression<bool> _matches(
  $WorkspaceRevisionsTable row,
  WorkspaceRevisionIdentity identity,
) =>
    row.workspaceId.equals(identity.workspaceId) &
    row.kind.equals(identity.kind) &
    row.resourceId.equals(identity.resourceId) &
    row.revision.equals(identity.revision);
