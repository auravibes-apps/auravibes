import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const LocalWorkspaceCsvRepository(
  final AppDatabase _database,
  final String _workspaceId,
) implements WorkspaceCsvRepository {
  LocalWorkspaceTableRepository get _tables =>
      LocalWorkspaceTableRepository(_database, _workspaceId);

  @override
  Future<WorkspaceTable> table(String id) => _tables.table(id);

  @override
  Future<WorkspaceRecordPage> query(
    String tableId,
    WorkspaceRecordQuery query,
  ) => LocalWorkspaceRecordQueryRepository(
    _database,
    _workspaceId,
  ).query(tableId, query);

  @override
  Future<void> write(
    WorkspaceCsvPreview preview, {
    required bool previewOnly,
  }) async {
    preview.validate();
    try {
      await _database.transaction(() => _insert(preview, previewOnly));
    } on _PreviewComplete {
      return;
    }
  }

  Future<void> _insert(WorkspaceCsvPreview preview, bool previewOnly) async {
    for (final values in preview.values) {
      final _ = await _tables.createRecord(
        table: preview.table,
        values: values,
      );
    }
    if (previewOnly) throw const _PreviewComplete();
  }
}

class const _PreviewComplete() implements Exception;
