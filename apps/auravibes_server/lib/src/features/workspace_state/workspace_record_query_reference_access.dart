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
  static void requireSchema(WorkspaceResource table) {
    final data = jsonDecode(table.data) as Map<String, dynamic>;
    for (final column
        in (data['columns'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()) {
      if (_invalidTarget(column)) _denied();
    }
  }

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
      where: (row) => _scope(row, kind) & _identity(row, id),
      transaction: transaction,
    );
    if (resource == null) _denied();

    return resource;
  }

  Expression _scope(
    WorkspaceResourceTable row,
    WorkspaceResourceKind kind,
  ) => row.workspaceId.equals(workspaceId) & row.resourceKind.equals(kind);
  Expression _identity(WorkspaceResourceTable row, String id) =>
      row.resourceId.equals(id) & row.deletedAt.equals(null);

  Future<void> _visible(WorkspaceResource resource) async {
    final visible = await WorkspaceTableAccess(transaction: transaction)
        .visible(session, member, resource);
    if (visible == null) _denied();
  }
}

Never _denied() => throw CloudWorkspaceException(code: .permissionDenied);

bool _invalidTarget(Map<String, dynamic> column) {
  if (column['type'] != 'reference') return false;
  final target = column['targetTableId'];

  return target is! String || target.isEmpty;
}
