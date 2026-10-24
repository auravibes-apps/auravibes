import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

Future<void> captureWorkspaceRevision(
  Session session,
  WorkspaceResource resource,
  Transaction transaction,
) async {
  if (resource.resourceKind != .table &&
      resource.resourceKind != .tableRecord) {
    return;
  }
  final existing = await WorkspaceRevision.db.findFirstRow(
    session,
    where: (row) =>
        row.workspaceId.equals(resource.workspaceId) &
        row.resourceKind.equals(resource.resourceKind) &
        row.resourceId.equals(resource.resourceId) &
        row.revision.equals(resource.revision),
    transaction: transaction,
  );
  if (existing != null) return;
  final _ = await WorkspaceRevision.db.insertRow(
    session,
    WorkspaceRevision(
      workspaceId: resource.workspaceId,
      resourceKind: resource.resourceKind,
      resourceId: resource.resourceId,
      revision: resource.revision,
      data: await _revisionData(session, resource, transaction),
      capturedAt: resource.updatedAt,
    ),
    transaction: transaction,
  );
}

Future<void> requireUnpurgedWorkspaceResource(
  Session session,
  int workspaceId,
  WorkspaceResourceKind kind,
  String resourceId,
  Transaction transaction,
) async {
  final marker = await WorkspaceRevision.db.findFirstRow(
    session,
    where: (row) =>
        row.workspaceId.equals(workspaceId) &
        row.resourceKind.equals(kind) &
        row.resourceId.equals(resourceId) &
        row.revision.equals(0),
    transaction: transaction,
  );
  if (marker != null) throw CloudWorkspaceException(code: .conflict);
}

Future<String> _revisionData(
  Session session,
  WorkspaceResource resource,
  Transaction transaction,
) async {
  if (resource.resourceKind != .tableRecord) return resource.data;
  final data = jsonDecode(resource.data) as Map<String, dynamic>;
  final table = await WorkspaceResource.db.findFirstRow(
    session,
    where: (row) =>
        row.workspaceId.equals(resource.workspaceId) &
        row.resourceKind.equals(.table) &
        row.resourceId.equals(data['tableId'] as String),
    transaction: transaction,
  );
  if (table == null) throw CloudWorkspaceException(code: .validationFailed);
  final schema = jsonDecode(table.data) as Map<String, dynamic>;
  data['historyReferenceTargets'] = {
    for (final column
        in (schema['columns'] as List).cast<Map<String, dynamic>>())
      if (column['type'] == 'reference')
        column['id'] as String: column['targetTableId'],
  };
  return jsonEncode(data);
}
