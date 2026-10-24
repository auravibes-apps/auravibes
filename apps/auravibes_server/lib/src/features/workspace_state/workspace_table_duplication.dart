import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/workspace_state_repository.dart';

/// Copy relationships keep their existing target tables and record identities.
class const WorkspaceTableDuplication(
  final WorkspaceStateRepository repository,
  final Session session,
  final DuplicateWorkspaceItemRequest request,
  final Transaction transaction,
) {
  static void validate(DuplicateWorkspaceItemRequest request) {
    if (request.requestId.isEmpty || request.requestId.length > 100 ||
        request.sourceId.isEmpty || request.targetId.isEmpty ||
        request.targetId == request.sourceId || request.targetId.length > 100 ||
        request.expectedRevision < 1 || request.name.trim().isEmpty ||
        request.name.trim().length > 200) {
      throw CloudWorkspaceException(code: .validationFailed);
    }
  }

  Future<WorkspaceResource> source() async {
    final row = await repository.findResource(session, workspaceId: request.workspaceId,
      kind: .table, resourceId: request.sourceId, transaction: transaction);
    if (row == null || row.deletedAt != null) throw CloudWorkspaceException(code: .permissionDenied);
    return row;
  }

  Future<List<WorkspacePatchOperation>> operations(WorkspaceResource source) async {
    if (source.revision != request.expectedRevision) throw CloudWorkspaceException(code: .conflict);
    final data = (jsonDecode(source.data) as Map).cast<String, Object?>();
    final columns = (data['columns'] as List).cast<Map>();
    final ids = {for (var i = 0; i < columns.length; i++) columns[i]['id']: '${request.targetId}-c$i'};
    return [
      _create(.table, request.targetId, {
        'name': request.name.trim(), 'parentId': request.parentId,
        'labelColumnId': ids[data['labelColumnId']], 'schemaRevision': 1,
        'columns': columns.map((column) => {...column, 'id': ids[column['id']],
          if (column['dependsOnColumnId'] != null) 'dependsOnColumnId': ids[column['dependsOnColumnId']]}).toList(),
      }),
      if (request.copyRecords) ...await _records(ids),
    ];
  }

  Future<List<WorkspacePatchOperation>> _records(Map<Object?, String> ids) async {
    final rows = await WorkspaceResource.db.find(session,
      where: (row) => row.workspaceId.equals(request.workspaceId) & row.resourceKind.equals(.tableRecord) & row.deletedAt.equals(null),
      orderBy: (row) => row.resourceId, transaction: transaction);
    final records = rows.where((row) => (jsonDecode(row.data) as Map)['tableId'] == request.sourceId).toList();
    if (records.length >= 50) throw CloudWorkspaceException(code: .validationFailed);
    return [for (var i = 0; i < records.length; i++) _record(records[i], '${request.targetId}-r$i', ids)];
  }

  WorkspacePatchOperation _record(WorkspaceResource row, String id, Map<Object?, String> ids) {
    final values = (jsonDecode(row.data) as Map)['values'] as Map;
    return _create(.tableRecord, id, {'tableId': request.targetId, 'schemaRevision': 1,
      'values': {for (final entry in values.entries) ids[entry.key]!: entry.value}});
  }
}

WorkspacePatchOperation _create(WorkspaceResourceKind kind, String id, Map<Object?, Object?> data) => .new(
  operation: .create, resourceKind: kind, resourceId: id, data: jsonEncode(data), fieldMask: const []);
