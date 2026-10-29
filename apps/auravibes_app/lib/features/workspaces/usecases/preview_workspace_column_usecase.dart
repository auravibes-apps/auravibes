import 'package:auravibes_app/features/workspaces/models/workspace_column_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table_constraints.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/preview_workspace_reference_usecase.dart';

class const PreviewWorkspaceColumnUsecase(
  final OrganizeWorkspaceTablesUsecase _tables,
) {
  Future<List<WorkspaceRecord>> call({
    required WorkspaceTable table,
    required WorkspaceColumn column,
  }) async {
    if (!table.canManage) throw const WorkspaceTableException(denied: true);
    final columns = _previewColumns(table, column);
    final records = await _tables.records(table.id);
    _requireVisible(records);

    final input = (table: table, column: column, columns: columns);

    return await _violations(input, records);
  }

  Future<List<WorkspaceRecord>> _violations(
    _PreviewColumn input,
    List<WorkspaceRecord> records,
  ) async {
    final invalid = WorkspaceTableConstraints.violations(
      input.columns,
      records,
    );
    final dependent = await PreviewWorkspaceReferenceUsecase(_tables)
        .call(input.table, input.column, records);

    return _merge(invalid, dependent);
  }
}

void _requireVisible(List<WorkspaceRecord> records) {
  if (records.any((record) => record.restrictedReferenceColumns.isNotEmpty)) {
    throw const WorkspaceTableException(denied: true);
  }
}

typedef _PreviewColumn = ({
  WorkspaceTable table,
  WorkspaceColumn column,
  List<WorkspaceColumn> columns,
});
List<WorkspaceColumn> _previewColumns(
  WorkspaceTable table,
  WorkspaceColumn column,
) {
  final columns = table.withColumn(
    WorkspaceColumnValidation.normalized(column),
  );
  WorkspaceColumnValidation.columns(columns, table.labelColumnId);

  return columns;
}

List<WorkspaceRecord> _merge(
  List<WorkspaceRecord> left,
  List<WorkspaceRecord> right,
) => {
  for (final record in [...left, ...right]) record.id: record,
}.values.toList();
