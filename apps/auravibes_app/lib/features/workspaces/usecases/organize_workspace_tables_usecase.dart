import 'package:auravibes_app/features/workspaces/models/workspace_column_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:uuid/v7.dart';

class const OrganizeWorkspaceTablesUsecase(
  final WorkspaceTableRepository _repository,
) {
  Future<List<WorkspaceTable>> list({String? parentId}) =>
      _repository.list(parentId: parentId);
  Future<WorkspaceTable> table(String id) => _repository.table(id);
  Future<List<WorkspaceRecord>> records(String tableId) =>
      _repository.records(tableId);
  Future<WorkspaceRecord> record(String tableId, String id) =>
      _repository.record(tableId, id);
  Future<WorkspaceTable> create({
    required String name,
    required String labelName,
    String? parentId,
  }) => _repository.create(
    name: _name(name),
    labelName: _name(labelName),
    parentId: parentId,
  );
  Future<WorkspaceTable> updateMetadata({
    required WorkspaceTable table,
    required String name,
    required String? parentId,
  }) {
    _requireManage(table);

    return _repository.updateMetadata(
      table: table,
      name: _name(name),
      parentId: parentId,
    );
  }

  Future<WorkspaceTable> renameLabel({
    required WorkspaceTable table,
    required String name,
  }) {
    _requireManage(table);

    return _repository.renameLabel(table: table, name: _name(name));
  }

  Future<WorkspaceRecord> createRecord({
    required WorkspaceTable table,
    required Map<String, Object?> values,
  }) {
    _requireEdit(table);
    WorkspaceColumnValidation.values(table.columns, values);

    return _repository.createRecord(table: table, values: values);
  }

  Future<WorkspaceRecord> updateRecord({
    required WorkspaceTable table,
    required WorkspaceRecord record,
    required Map<String, Object?> values,
  }) {
    _requireEdit(table);
    WorkspaceColumnValidation.values(table.columns, values);
    if (record.tableId != table.id) {
      throw const WorkspaceTableException();
    }

    return _repository.updateRecord(
      table: table,
      record: record,
      values: values,
    );
  }

  Future<WorkspaceTable> saveColumn({
    required WorkspaceTable table,
    required WorkspaceColumn column,
  }) {
    _requireManage(table);
    final normalized = _normalizeColumn(column);
    _checkColumnId(table, column.id);
    WorkspaceColumnValidation.columns(
      table.withColumn(normalized),
      table.labelColumnId,
    );

    return _repository.saveColumn(table: table, column: normalized);
  }
}

void _checkColumnId(WorkspaceTable table, String id) {
  if (id.isNotEmpty && !table.columns.any((column) => column.id == id)) {
    throw const WorkspaceTableException();
  }
}

WorkspaceColumn _normalizeColumn(WorkspaceColumn column) => WorkspaceColumn(
  id: column.id.isEmpty ? const UuidV7().generate() : column.id,
  name: _name(column.name),
  type: column.type,
  options: column.options.map(_name).toList(),
);

String _name(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.length > 200) {
    throw const WorkspaceTableException();
  }

  return trimmed;
}

void _requireManage(WorkspaceTable table) {
  if (!table.canManage) throw const WorkspaceTableException(denied: true);
}

void _requireEdit(WorkspaceTable table) {
  if (!table.canEditRecords) throw const WorkspaceTableException(denied: true);
}
