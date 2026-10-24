import 'workspace_reference_validation.dart';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'domain/workspace_table_constraints.dart';
import 'domain/workspace_table_schema_identity.dart';
import 'repositories/workspace_state_repository.dart';

class WorkspaceTableMutationValidation(
  final WorkspaceStateRepository _repository,
  final Session _session,
  final int _workspaceId,
  final Transaction _transaction,
  final String _userId,
) {
  static const _pageSize = 100;

  Future<void> validate(
    WorkspacePatchOperation operation,
    Map<String, Object?> data,
    WorkspaceResource? existing,
  ) async {
    if (operation.resourceKind == WorkspaceResourceKind.table) {
      await _table(operation.resourceId, data, existing);
    }
    if (operation.resourceKind == WorkspaceResourceKind.tableRecord) {
      await _record(operation, data, existing);
    }
  }

  Future<void> _table(
    String id,
    Map<String, Object?> data,
    WorkspaceResource? existing,
  ) async {
    if (_schemaRevision(data, existing)) return;
    final references = await _references();
    await references.columns(data);
    final records = await _records(id);
    WorkspaceTableConstraints.records(data, records.values);
    for (final values in records.values) { await references.values(data, values, const {}); }
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

  Future<void> _record(
    WorkspacePatchOperation operation,
    Map<String, Object?> data,
    WorkspaceResource? existing,
  ) async {
    final id = data['tableId'] as String;
    final schema = await _schema(id);
    if (data['schemaRevision'] != schema['schemaRevision']) _stale();
    final values = _values(operation, schema, data);
    final references = await _references();
    await references.values(schema, values, existing == null ? const {} : (_decode(existing)['values'] as Map).cast<String, Object?>());
    await _checkValues(id, operation.resourceId, schema, values);
    _recordTable(existing, id);
  }

  Future<void> _checkValues(
    String id,
    String recordId,
    Map<String, Object?> schema,
    Map<String, Object?> values,
  ) async {
    final records = await _records(id);
    records[recordId] = values;
    WorkspaceTableConstraints.records(schema, records.values);
  }

  Map<String, Object?> _values(
    WorkspacePatchOperation operation,
    Map<String, Object?> schema,
    Map<String, Object?> data,
  ) {
    var values = (data['values'] as Map).cast<String, Object?>();
    if (operation.operation == WorkspacePatchOperationKind.create) {
      values = WorkspaceTableConstraints.defaults(schema, values);
      data['values'] = values;
    }

    return values;
  }

  Future<WorkspaceReferenceValidation> _references() async {
    final member = await _repository.findMember(_session, workspaceId: _workspaceId, userId: _userId, transaction: _transaction);
    if (member == null) throw CloudWorkspaceException(code: .permissionDenied);
    return WorkspaceReferenceValidation(_repository, _session, member, _transaction);
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

  Future<List<WorkspaceResource>> _page(String? cursor) => _repository.readPage(
    _session,
    workspaceId: _workspaceId,
    kind: WorkspaceResourceKind.tableRecord,
    limit: _pageSize,
    afterResourceId: cursor,
    transaction: _transaction,
  );
}

Map<String, Object?> _decode(WorkspaceResource row) =>
    (jsonDecode(row.data) as Map).cast<String, Object?>();
Never _stale() =>
    throw CloudWorkspaceException(code: CloudWorkspaceErrorCode.staleRevision);

void _recordTable(WorkspaceResource? existing, String id) {
  if (existing != null && _decode(existing)['tableId'] != id) {
    throw const FormatException();
  }
}
