import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../objects/object_record_attachments.dart';
import 'domain/workspace_table_constraints.dart';
import 'domain/workspace_table_schema_identity.dart';
import 'repositories/workspace_state_repository.dart';
import 'workspace_reference_validation.dart';

class WorkspaceTableMutationValidation(
  final WorkspaceStateRepository _repository,
  final Session _session,
  final int _workspaceId,
  final Transaction _transaction,
  final String _userId, {
  final bool deferRecordState = false,
  final bool applyDefaults = true,
}) {
  static const _pageSize = 100;

  Future<void> validate(
    WorkspacePatchOperation operation,
    Map<String, Object?> data,
    WorkspaceResource? existing,
  ) async {
    if (operation.resourceKind == WorkspaceResourceKind.table) {
      await _SchemaValidation(
        this,
        operation.resourceId,
        data,
        existing,
      ).call();
    }
    if (operation.resourceKind == WorkspaceResourceKind.tableRecord) {
      await _record(operation, data, existing);
    }
  }

  Future<void> _record(
    WorkspacePatchOperation operation,
    Map<String, Object?> data,
    WorkspaceResource? existing,
  ) async {
    final id = data['tableId'] as String;
    final schema = await _recordSchema(id, data);
    final values = _values(
      operation,
      schema,
      data,
      applyDefaults: applyDefaults,
    );
    _recordTable(existing, id);
    await _checkReferences(operation, schema, data, existing);
    await _checkValues(id, operation.resourceId, schema, values);
  }

  Future<Map<String, Object?>> _recordSchema(
    String id,
    Map<String, Object?> data,
  ) async {
    final schema = await _schema(id);
    if (data['schemaRevision'] != schema['schemaRevision']) _stale();

    return schema;
  }

  Future<void> _checkReferences(
    WorkspacePatchOperation operation,
    Map<String, Object?> schema,
    Map<String, Object?> data,
    WorkspaceResource? existing,
  ) async {
    final references = await _references();
    await references.values(
      _recordAttachments(operation, schema, data, existing),
      preserveOnly: deferRecordState,
    );
    data.remove('assetSharingApproved');
    if (!deferRecordState) {
      await references.dependents.record(operation.resourceId, data, existing);
    }
  }

  Future<void> _checkValues(
    String id,
    String recordId,
    Map<String, Object?> schema,
    Map<String, Object?> values,
  ) async {
    if (deferRecordState) return;
    final records = await _records(id);
    records[recordId] = values;
    WorkspaceTableConstraints.records(schema, records.values);
  }

  Future<WorkspaceReferenceValidation> _references() async {
    final member = await _repository.findMember(
      _session,
      workspaceId: _workspaceId,
      userId: _userId,
      transaction: _transaction,
    );
    if (member == null) throw CloudWorkspaceException(code: .permissionDenied);

    return WorkspaceReferenceValidation(
      _repository,
      _session,
      member,
      _transaction,
    );
  }

  Future<Map<String, Object?>> _schema(String id) async {
    final table = await _repository.findResource(
      _session,
      workspaceId: _workspaceId,
      kind: WorkspaceResourceKind.table,
      resourceId: id,
      transaction: _transaction,
    );
    if (table == null || table.deletedAt != null) throw const FormatException();

    return _decode(table);
  }

  Future<Map<String, Map<String, Object?>>> _records(String id) async {
    final result = <String, Map<String, Object?>>{};
    String? cursor;
    while (true) {
      final page = await _page(cursor);
      _addPage(result, page, id);
      if (page.length < _pageSize) return result;
      cursor = page.last.resourceId;
    }
  }

  Future<List<WorkspaceResource>> _page(String? cursor) => _repository.readPage(
    _session,
    workspaceId: _workspaceId,
    kind: WorkspaceResourceKind.tableRecord,
    limit: _pageSize,
    afterResourceId: cursor,
    transaction: _transaction,
  );
}

class const _SchemaValidation(
  final WorkspaceTableMutationValidation owner,
  final String id,
  final Map<String, Object?> data,
  final WorkspaceResource? existing,
) {
  Future<void> call() async {
    if (_schemaRevision(data, existing)) return;
    final references = await _references();
    await _records(references);
  }

  Future<WorkspaceReferenceValidation> _references() async {
    final references = await owner._references();
    final row = existing;
    await references.columns(
      data,
      tableId: id,
      previous: row == null ? const {} : _decode(row),
    );
    await references.dependents.schema(id, data);

    return references;
  }

  Future<void> _records(WorkspaceReferenceValidation references) async {
    final records = await owner._records(id);
    WorkspaceTableConstraints.records(data, records.values);
    final previous = _previousAttachments();
    for (final entry in records.entries) {
      await references.values(_input(entry, previous));
    }
  }

  Set<String> _previousAttachments() {
    final row = existing;
    if (row == null) return {};

    return (_decode(row)['columns'] as List)
        .whereType<Map>()
        .where((column) => column['type'] == 'attachment')
        .map((column) => column['id'] as String)
        .toSet();
  }

  ObjectAttachmentValues _input(
    MapEntry<String, Map<String, Object?>> entry,
    Set<String> previous,
  ) => .new(
    schema: data,
    values: entry.value,
    previous: {
      for (final id in previous)
        if (entry.value.containsKey(id)) id: entry.value[id],
    },
    recordId: entry.key,
    tableId: id,
  );
}

ObjectAttachmentValues _recordAttachments(
  WorkspacePatchOperation operation,
  Map<String, Object?> schema,
  Map<String, Object?> data,
  WorkspaceResource? existing,
) => .new(
  schema: schema,
  values: (data['values'] as Map).cast<String, Object?>(),
  previous: _previousValues(existing),
  recordId: operation.resourceId,
  tableId: data['tableId'] as String,
  sharingApproved: _sharingApproved(operation),
);

bool _sharingApproved(WorkspacePatchOperation operation) =>
    (jsonDecode(operation.data!) as Map)['assetSharingApproved'] == true;

Map<String, Object?> _decode(WorkspaceResource row) =>
    (jsonDecode(row.data) as Map).cast<String, Object?>();
Never _stale() =>
    throw CloudWorkspaceException(code: CloudWorkspaceErrorCode.staleRevision);

void _recordTable(WorkspaceResource? existing, String id) {
  if (existing != null && _decode(existing)['tableId'] != id) {
    throw const FormatException();
  }
}

bool _schemaRevision(Map<String, Object?> data, WorkspaceResource? existing) {
  if (existing == null) {
    if (data['schemaRevision'] != 1) throw const FormatException();

    return false;
  }
  final previous = _decode(existing);
  final revision = previous['schemaRevision'] as int;
  final changed = !WorkspaceTableSchemaIdentity.matches(data, previous);
  if (data['labelColumnId'] != previous['labelColumnId'] ||
      data['schemaRevision'] != revision + (changed ? 1 : 0)) {
    _stale();
  }

  return !changed;
}

Map<String, Object?> _values(
  WorkspacePatchOperation operation,
  Map<String, Object?> schema,
  Map<String, Object?> data, {
  required bool applyDefaults,
}) {
  var values = (data['values'] as Map).cast<String, Object?>();
  if (applyDefaults &&
      operation.operation == WorkspacePatchOperationKind.create) {
    values = WorkspaceTableConstraints.defaults(schema, values);
    data['values'] = values;
  }

  return values;
}

void _addPage(
  Map<String, Map<String, Object?>> result,
  List<WorkspaceResource> page,
  String tableId,
) {
  for (final record in page) {
    final current = _decode(record);
    if (current['tableId'] == tableId && record.deletedAt == null) {
      result[record.resourceId] = (current['values'] as Map)
          .cast<String, Object?>();
    }
  }
}

Map<String, Object?> _previousValues(WorkspaceResource? existing) =>
    existing == null
    ? const {}
    : (_decode(existing)['values'] as Map).cast<String, Object?>();
