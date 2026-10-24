import 'package:auravibes_app/features/workspaces/models/workspace_column_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table_constraints.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';

class const PreviewWorkspaceColumnUsecase(final OrganizeWorkspaceTablesUsecase _tables) {
  Future<List<WorkspaceRecord>> call({required WorkspaceTable table,
    required WorkspaceColumn column}) async {
    if (!table.canManage) throw const WorkspaceTableException(denied: true);
    final columns = table.withColumn(normalizeWorkspaceColumn(column));
    WorkspaceColumnValidation.columns(columns, table.labelColumnId);
    final records = await _tables.records(table.id);
    return WorkspaceTableConstraints.violations(columns, records);
  }
}
