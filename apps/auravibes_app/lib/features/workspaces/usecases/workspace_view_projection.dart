import 'package:auravibes_app/features/workspaces/models/workspace_reference_value.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/usecases/browse_workspace_references_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';

/// Resolves displayed links through current grants; never renders stable IDs.
class const WorkspaceViewProjection(
  final OrganizeWorkspaceTablesUsecase tables,
  final BrowseWorkspaceReferencesUsecase references,
) {
  Future<List<WorkspaceRecord>> records(
    WorkspaceView view,
    List<WorkspaceRecord> rows,
  ) async {
    final table = await tables.table(view.tableId);
    final columns = _columns(view, table);
    final result = <WorkspaceRecord>[];
    for (final row in rows) {
      result.add(await _record(columns, row));
    }

    return result;
  }

  List<WorkspaceColumn> _columns(WorkspaceView view, WorkspaceTable table) =>
      table.columns
          .where(
            (column) =>
                column.type == .reference &&
                view.bindings.containsValue(column.id),
          )
          .toList();
  Future<WorkspaceRecord> _record(
    List<WorkspaceColumn> columns,
    WorkspaceRecord row,
  ) async {
    final values = {...row.values};
    for (final column in columns) {
      values[column.id] = await _reference(row, column);
    }

    return _withValues(row, values);
  }

  WorkspaceRecord _withValues(
    WorkspaceRecord row,
    Map<String, Object?> values,
  ) => WorkspaceRecord(
    id: row.id,
    tableId: row.tableId,
    values: values,
    revision: row.revision,
    restrictedReferenceColumns: row.restrictedReferenceColumns,
  );
  Future<String?> _reference(
    WorkspaceRecord row,
    WorkspaceColumn column,
  ) async {
    if (row.restrictedReferenceColumns.contains(column.id)) return null;
    try {
      return await _labels(column, row.values[column.id]);
    } on Object {
      return null;
    }
  }

  Future<String> _labels(WorkspaceColumn column, Object? value) async {
    final tableId = column.targetTableId;
    if (tableId == null) throw const WorkspaceTableException();
    final target = await tables.table(tableId);
    final labels = <String>[];
    for (final id in WorkspaceReferenceValue.ids(value)) {
      labels.add(await _label(target, id));
    }

    return labels.join(', ');
  }

  Future<String> _label(WorkspaceTable target, String id) async {
    final row = await references.record(target.id, id);

    return row.values[target.labelColumnId]?.toString() ?? '';
  }
}
