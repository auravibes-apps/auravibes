import 'dart:convert';

import '../../generated/protocol.dart';
import 'workspace_history_retained_reader.dart';
import 'workspace_trash_access.dart';
import 'workspace_trash_context.dart';

class const WorkspaceHistoryBlockers(final WorkspaceTrashContext context) {
  Future<Never> deny(
    Iterable<HistoryRetainedData> blockers,
    List<WorkspaceResource> rows,
  ) async {
    for (final blocker in blockers) {
      final source = _source(blocker, rows);
      if (source != null && await context.readable(source)) {
        throw CloudWorkspaceException(
          code: .validationFailed,
          blockingResourcesJson: _details(source),
        );
      }
    }
    trashInvalid();
  }
}

String _details(WorkspaceResource resource) => jsonEncode([
  {
    'id': resource.resourceId,
    'kind': resource.resourceKind.name,
    'name': trashData(resource)['name'],
  },
]);

WorkspaceResource? _source(
  HistoryRetainedData blocker,
  List<WorkspaceResource> rows,
) => rows
    .where(
      (row) => row.resourceKind == blocker.kind && row.resourceId == blocker.id,
    )
    .firstOrNull;
