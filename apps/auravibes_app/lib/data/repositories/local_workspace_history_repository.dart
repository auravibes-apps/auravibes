import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_permanent_delete.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_validation.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_column_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_revision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table_constraints.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceHistoryRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceHistoryRepository {
  LocalWorkspaceTableRepository get _tables => .new(database, workspaceId);

  @override
  Future<List<WorkspaceRevision>> history(WorkspaceTrashTarget target) async {
    await _authorize(target);
    final query = database.select(database.workspaceRevisions)
      ..where(
        (row) =>
            row.workspaceId.equals(workspaceId) &
            row.kind.equals(target.kind.name) &
            row.resourceId.equals(target.id),
      )
      ..orderBy([(row) => OrderingTerm.desc(row.revision)]);
    final rows = await query.get();
    return rows
        .map(
          (row) => WorkspaceRevision(
            target: .new(
              kind: target.kind,
              id: target.id,
              tableId: target.tableId,
              revision: row.revision,
            ),
            data: jsonDecode(row.data) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<void> restore(WorkspaceTrashTarget target, int revision) =>
      database.transaction(() async {
        final revisions = await history(target);
        final selected = revisions
            .where((item) => item.target.revision == revision)
            .firstOrNull;
        if (selected == null) throw const WorkspaceTableException();
        if (target.kind == .record) {
          final table = await _tables.table(target.tableId!);
          final record = await _tables.record(table.id, target.id);
          _revision(record.revision, target.revision);
          final _ = await _tables.updateRecord(
            table: table,
            record: record,
            values: (selected.data['values'] as Map<String, dynamic>)
                .cast<String, Object?>(),
          );
        } else {
          await _restoreSchema(target, selected.data);
        }
      });

  Future<void> _authorize(WorkspaceTrashTarget target) async {
    validateWorkspaceTrashTarget(target);
    final workspace = await (database.select(
      database.workspaces,
    )..where((row) => row.id.equals(workspaceId))).getSingleOrNull();
    if (workspace == null || workspace.type != .local) {
      throw const WorkspaceTableException();
    }
    if (target.kind == .record) {
      final _ = await _tables.record(target.tableId!, target.id);
    } else if (target.kind == .table) {
      final _ = await _tables.table(target.id);
    } else {
      throw const WorkspaceTableException();
    }
  }

  Future<void> _restoreSchema(
    WorkspaceTrashTarget target,
    Map<String, dynamic> data,
  ) async {
    final table = await _tables.table(target.id);
    _revision(table.revision, target.revision);
    final columns = (data['columns'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(WorkspaceColumn.fromJson)
        .toList();
    WorkspaceColumnValidation.columns(columns, table.labelColumnId);
    final records = await _tables.records(table.id);
    WorkspaceTableConstraints.records(columns, records);
    final references = LocalWorkspaceReferenceValidation(database, workspaceId);
    await references.columns(columns);
    for (final record in records) {
      await references.values(columns, record.values);
    }
    final update = database.update(database.workspaceTables)
      ..where(
        (row) => row.workspaceId.equals(workspaceId) & row.id.equals(target.id),
      );
    final _ = await update.write(
      WorkspaceTablesCompanion(
        columnsJson: .new(
          jsonEncode(columns.map((column) => column.toJson()).toList()),
        ),
        revision: .new(table.revision + 1),
        schemaRevision: .new(table.schemaRevision + 1),
      ),
    );
    await references.allDependencies();
  }

  @override
  Future<void> permanentlyDelete(WorkspaceTrashTarget target) async {
    final workspace = await (database.select(
      database.workspaces,
    )..where((row) => row.id.equals(workspaceId))).getSingleOrNull();
    if (workspace == null || workspace.type != .local) {
      throw const WorkspaceTableException();
    }
    await LocalWorkspacePermanentDelete(database, workspaceId)(target);
  }
}

void _revision(int actual, int expected) {
  if (actual != expected) throw const WorkspaceTableException(conflict: true);
}
