import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const OrganizeWorkspaceTablesUsecase(
  final WorkspaceTableRepository _repository,
) {
  Future<List<WorkspaceTableMember>> members(String tableId) =>
      _repository.members(tableId);
  Future<void> setMemberAccess({
    required WorkspaceTable table,
    required String userId,
    required String? access,
  }) {
    if (!table.canManage ||
        !table.supportsSharing ||
        (access != null && access != 'read' && access != 'edit')) {
      throw const WorkspaceTableException();
    }

    return _repository.setMemberAccess(
      table: table,
      userId: userId,
      access: access,
    );
  }

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
  }) {
    if (!table.canManage) {
      throw const WorkspaceTableException(denied: true);
    }

    return _repository.renameLabel(table: table, name: _name(name));
  }

  Future<WorkspaceRecord> createRecord({
    required WorkspaceTable table,
    required Map<String, String> values,
  }) {
    if (!table.canEditRecords) {
      throw const WorkspaceTableException(denied: true);
    }
    _validateValues(table, values);

    return _repository.createRecord(table: table, values: values);
  }

  Future<WorkspaceRecord> updateRecord({
    required WorkspaceTable table,
    required WorkspaceRecord record,
    required Map<String, String> values,
  }) {
    if (!table.canEditRecords) {
      throw const WorkspaceTableException(denied: true);
    }
    _validateValues(table, values);
    if (record.tableId != table.id) {
      throw const WorkspaceTableException();
    }

    return _repository.updateRecord(
      table: table,
      record: record,
      values: values,
    );
  }

  String _name(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > 200) {
      throw const WorkspaceTableException();
    }

    return trimmed;
  }

  void _validateValues(WorkspaceTable table, Map<String, String> values) {
    final ids = table.columns.map((column) => column.id).toSet();
    if (values.keys.any((id) => !ids.contains(id)) ||
        values.values.any((value) => value.length > 16384)) {
      throw const WorkspaceTableException();
    }
  }
}
