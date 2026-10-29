import 'package:auravibes_app/features/workspaces/models/workspace_reference_value.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';

class const PreviewWorkspaceReferenceUsecase(
  final OrganizeWorkspaceTablesUsecase tables,
) {
  Future<List<WorkspaceRecord>> call(
    WorkspaceTable source,
    WorkspaceColumn column,
    List<WorkspaceRecord> records,
  ) async {
    if (column.dependsOnColumnId == null) return const [];
    final targets = await _targets(source, column);

    return records
        .where((record) => !_matches(column, record.values, targets))
        .toList();
  }

  Future<Map<String, WorkspaceRecord>> _targets(
    WorkspaceTable source,
    WorkspaceColumn column,
  ) async {
    final table = await _target(source, column);
    final records = await tables.records(table.id);
    _visible(records, column.targetMatchColumnId);

    return {for (final record in records) record.id: record};
  }

  Future<WorkspaceTable> _target(
    WorkspaceTable source,
    WorkspaceColumn column,
  ) async {
    final target = await tables.table(column.targetTableId ?? '');
    final parent = _parent(source, target, column);
    final _ = await tables.table(parent.targetTableId ?? '');

    return target;
  }
}

WorkspaceColumn? _column(List<WorkspaceColumn> columns, String? id) =>
    columns.where((column) => column.id == id).firstOrNull;
void _configuration(WorkspaceColumn? parent, WorkspaceColumn? match) {
  if (parent == null ||
      match == null ||
      !_single(match) ||
      parent.targetTableId != match.targetTableId) {
    throw const WorkspaceTableException();
  }
}

bool _single(WorkspaceColumn column) =>
    column.type == .reference &&
    !column.referenceMultiple &&
    column.dependsOnColumnId == null;
void _visible(List<WorkspaceRecord> records, String? id) {
  if (records.any((record) => record.restrictedReferenceColumns.contains(id))) {
    throw const WorkspaceTableException(denied: true);
  }
}

bool _matches(
  WorkspaceColumn column,
  Map<String, Object?> values,
  Map<String, WorkspaceRecord> targets,
) {
  if (values[column.id] == null) return true;
  if (!WorkspaceReferenceValue.valid(column, values[column.id])) return false;

  return _parentMatches(column, values, targets);
}

bool _parentMatches(
  WorkspaceColumn column,
  Map<String, Object?> values,
  Map<String, WorkspaceRecord> targets,
) {
  final ids = WorkspaceReferenceValue.ids(values[column.id]);
  if (ids.isEmpty) return true;
  final parent = values[column.dependsOnColumnId];

  return parent is String &&
      ids.every(
        (id) => targets[id]?.values[column.targetMatchColumnId] == parent,
      );
}

WorkspaceColumn _parent(
  WorkspaceTable source,
  WorkspaceTable target,
  WorkspaceColumn column,
) {
  final parent = _column(source.columns, column.dependsOnColumnId);
  final match = _column(target.columns, column.targetMatchColumnId);
  _configuration(parent, match);

  return parent ?? (throw const WorkspaceTableException());
}
