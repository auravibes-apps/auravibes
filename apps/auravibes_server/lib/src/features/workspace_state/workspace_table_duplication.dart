import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/workspace_state_repository.dart';
import 'workspace_revision_capture.dart';

const _pageSize = 100;
const _maximumRecords = 49;
const _maximumId = 100;
const _maximumName = 200;

/// Copy relationships keep their existing target tables and record identities.
class const WorkspaceTableDuplication(
  final WorkspaceStateRepository repository,
  final Session session,
  final DuplicateWorkspaceItemRequest request,
  final Transaction transaction,
) {
  static void validate(DuplicateWorkspaceItemRequest request) {
    if (!_validIds(request) || !_validOptions(request)) {
      throw CloudWorkspaceException(code: .validationFailed);
    }
  }

  Future<WorkspaceResource> source() async {
    final row = await repository.findResource(
      session,
      workspaceId: request.workspaceId,
      kind: .table,
      resourceId: request.sourceId,
      transaction: transaction,
    );
    if (row == null || row.deletedAt != null) {
      throw CloudWorkspaceException(code: .permissionDenied);
    }

    return row;
  }

  Future<void> requireTarget() => requireOperations([
    _create(.table, request.targetId, const {}),
  ]);

  Future<void> requireOperations(List<WorkspacePatchOperation> operations) =>
      WorkspaceRevisionCapture(session, transaction).requirePatch(
        .new(
          workspaceId: request.workspaceId,
          requestId: request.requestId,
          operations: operations,
        ),
      );

  Future<void> requireLiveTargets(List<WorkspaceResource> resources) async {
    for (final resource in resources) {
      await _requireLiveTarget(resource);
    }
  }

  Future<List<WorkspacePatchOperation>> operations(
    WorkspaceResource source,
  ) async {
    if (source.revision != request.expectedRevision) {
      throw CloudWorkspaceException(code: .conflict);
    }
    final schema = _data(source);
    final ids = _columnIds(schema, request.targetId);

    return [
      _create(.table, request.targetId, _schema(schema, ids, request)),
      if (request.copyRecords) ...await _recordOperations(ids),
    ];
  }

  Future<void> _requireLiveTarget(WorkspaceResource resource) async {
    final current = await repository.findResource(
      session,
      workspaceId: request.workspaceId,
      kind: resource.resourceKind,
      resourceId: resource.resourceId,
      transaction: transaction,
    );
    if (current == null || current.deletedAt != null) {
      throw CloudWorkspaceException(code: .permissionDenied);
    }
  }

  Future<List<WorkspacePatchOperation>> _recordOperations(
    Map<Object?, String> ids,
  ) async {
    final records = await _records();

    return [
      for (var i = 0; i < records.length; i++)
        _record(records[i], '${request.targetId}-r$i', ids),
    ];
  }

  Future<List<WorkspaceResource>> _records() async {
    final records = <WorkspaceResource>[];
    String? cursor;
    while (true) {
      final page = await _page(cursor);
      records.addAll(page.where(_matches));
      _checkCount(records.length);
      if (page.length < _pageSize) return records;
      cursor = page.last.resourceId;
    }
  }

  Future<List<WorkspaceResource>> _page(String? cursor) => repository.readPage(
    session,
    workspaceId: request.workspaceId,
    kind: .tableRecord,
    limit: _pageSize,
    afterResourceId: cursor,
    transaction: transaction,
  );
  bool _matches(WorkspaceResource row) =>
      _data(row)['tableId'] == request.sourceId;

  WorkspacePatchOperation _record(
    WorkspaceResource row,
    String id,
    Map<Object?, String> ids,
  ) => _create(.tableRecord, id, {
    'tableId': request.targetId,
    'schemaRevision': 1,
    'values': _values(_data(row), ids),
  });
}

bool _validIds(DuplicateWorkspaceItemRequest request) =>
    request.requestId.isNotEmpty &&
    request.requestId.length <= _maximumId &&
    request.sourceId.isNotEmpty &&
    request.sourceId.length <= _maximumSourceId &&
    request.targetId.isNotEmpty &&
    request.targetId != request.sourceId &&
    request.targetId.length <= _maximumId;
bool _validOptions(DuplicateWorkspaceItemRequest request) =>
    request.expectedRevision > 0 &&
    request.name.trim().isNotEmpty &&
    request.name.trim().length <= _maximumName &&
    _validParent(request.parentId);
Map<String, Object?> _data(WorkspaceResource row) =>
    (jsonDecode(row.data) as Map).cast<String, Object?>();
List<Map> _columns(Map<String, Object?> data) =>
    (data['columns'] as List).cast<Map>();
Map<Object?, String> _columnIds(Map<String, Object?> schema, String targetId) {
  final columns = _columns(schema);

  return {
    for (var i = 0; i < columns.length; i++) columns[i]['id']: '$targetId-c$i',
  };
}

Map<String, Object?> _schema(
  Map<String, Object?> schema,
  Map<Object?, String> ids,
  DuplicateWorkspaceItemRequest request,
) => {
  'name': request.name.trim(),
  'parentId': request.parentId,
  'labelColumnId': ids[schema['labelColumnId']],
  'schemaRevision': 1,
  'columns': _columns(schema).map((column) => _column(column, ids)).toList(),
};
Map<Object?, Object?> _column(Map column, Map<Object?, String> ids) => {
  ...column,
  'id': ids[column['id']],
  if (column['dependsOnColumnId'] != null)
    'dependsOnColumnId': ids[column['dependsOnColumnId']],
};
Map<String, Object?> _values(
  Map<String, Object?> data,
  Map<Object?, String> ids,
) => {
  for (final entry in (data['values'] as Map).entries)
    ids[entry.key]!: entry.value,
};
void _checkCount(int count) {
  if (count > _maximumRecords) {
    throw CloudWorkspaceException(code: .validationFailed);
  }
}

WorkspacePatchOperation _create(
  WorkspaceResourceKind kind,
  String id,
  Map<Object?, Object?> data,
) => .new(
  operation: .create,
  resourceKind: kind,
  resourceId: id,
  data: jsonEncode(data),
  fieldMask: const [],
);

const _maximumSourceId = 200;
bool _validParent(String? id) =>
    id == null || (id.isNotEmpty && id.length <= _maximumSourceId);
