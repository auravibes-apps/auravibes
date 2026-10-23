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
  Future<WorkspaceTable> renameLabel({
    required WorkspaceTable table,
    required String name,
  }) => _repository.renameLabel(table: table, name: _name(name));
  Future<WorkspaceRecord> createRecord({
    required WorkspaceTable table,
    required Map<String, Object?> values,
  }) {
    WorkspaceColumnValidation.values(table.columns, values);

    return _repository.createRecord(table: table, values: values);
  }

  Future<WorkspaceRecord> updateRecord({
    required WorkspaceTable table,
    required WorkspaceRecord record,
    required Map<String, Object?> values,
  }) {
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
    required String name,
    required WorkspaceColumnType type,
    String? columnId,
    List<String> options = const [],
  }) {
    final column = WorkspaceColumn(
      id: columnId ?? const UuidV7().generate(),
      name: _name(name),
      type: type,
      options: options.map(_name).toList(),
    );
    if (columnId != null &&
        !table.columns.any((value) => value.id == columnId)) {
      throw const WorkspaceTableException();
    }
    final columns = [
      for (final existing in table.columns)
        if (existing.id != column.id) existing,
      column,
    ];
    WorkspaceColumnValidation.columns(columns, table.labelColumnId);

    return _repository.saveColumn(table: table, column: column);
  }

  String _name(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > 200) {
      throw const WorkspaceTableException();
    }

    return trimmed;
  }
}
