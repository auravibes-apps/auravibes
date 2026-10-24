import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'workspace_table_access.dart';

/// Authorizes the selected target before any membership filter or sentinel read.
class const WorkspaceRecordQueryReferenceAccess(
  final Session session,
  final WorkspaceMember member,
  final int workspaceId,
  final Transaction transaction,
) {
  Future<void> require(String tableId, String recordId) async {
    final table = await _resource(.table, tableId);
    await _visible(table);
    final record = await _resource(.tableRecord, recordId);
    if ((jsonDecode(record.data) as Map<String, dynamic>)['tableId'] !=
        tableId) {
      _denied();
    }
    await _visible(record);
  }

  Future<WorkspaceResource> _resource(
    WorkspaceResourceKind kind,
    String id,
  ) async {
    final resource = await WorkspaceResource.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(workspaceId) &
          row.resourceKind.equals(kind) &
          row.resourceId.equals(id) &
          row.deletedAt.equals(null),
      transaction: transaction,
    );
    if (resource == null) _denied();
    return resource;
  }

  Future<void> _visible(WorkspaceResource resource) async {
    final visible = await WorkspaceTableAccess(transaction: transaction)
        .visible(session, member, resource);
    if (visible == null) _denied();
  }
}

Never _denied() => throw CloudWorkspaceException(code: .permissionDenied);
