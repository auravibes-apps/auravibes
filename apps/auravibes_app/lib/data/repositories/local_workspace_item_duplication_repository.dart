import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_batch_receipt.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_view_mapper.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_item_duplication.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_view_validation.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceItemDuplicationRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceItemDuplicationRepository {
  LocalWorkspaceViewRepository get _views => .new(database, workspaceId);
  @override
  Future<void> copy(WorkspaceItemDuplication request) {
    request.validate();

    return database.transaction(
      () => switch (request.kind) {
        .table => _table(request),
        .view => _view(request),
        .workflow => _workflow(request),
      },
    );
  }

  Future<void> _workflow(WorkspaceItemDuplication request) async {
    if (await _replayed(request)) return;
    final source =
        await (database.select(database.workspaceWorkflows)..where(
              (row) =>
                  row.workspaceId.equals(workspaceId) &
                  row.id.equals(request.sourceId) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (source == null) throw const WorkspaceTableException(denied: true);
    if (source.revision != request.expectedRevision) {
      throw const WorkspaceTableException(conflict: true);
    }
    final graph = WorkflowDefinition.decode(source.definitionJson);
    await database.workspaceWorkflowsDao.save(
      WorkspaceWorkflowsCompanion.insert(
        id: .new(request.targetId),
        workspaceId: workspaceId,
        parentId: .new(request.parentId),
        name: request.name.trim(),
        description: .new(source.description),
        revision: const .new(1),
        definitionJson: graph.encode(),
        createdAt: .new(DateTime.now().toUtc()),
        updatedAt: .new(DateTime.now().toUtc()),
      ),
    );
    await LocalWorkspaceRecordBatchReceipt(
      database,
      workspaceId,
    ).save(request.requestId, _digest(request));
  }

  Future<void> _table(WorkspaceItemDuplication request) async {
    final repository = LocalWorkspaceTableRepository(database, workspaceId);
    final _ = await repository.duplicate(request);
  }

  Future<void> _view(WorkspaceItemDuplication request) async {
    final source = await _viewSource(request);
    if (await _replayed(request)) {
      final _ = await _views.read(request.targetId);

      return;
    }
    final copy = _copiedView(source.view, request);
    WorkspaceViewValidation.check(copy, source.table);
    await _save(_views, copy, request);
  }

  Future<({WorkspaceView view, WorkspaceTable table})> _viewSource(
    WorkspaceItemDuplication request,
  ) async {
    final view = await _views.read(request.sourceId);
    final table = view.isConnectedOnly
        ? WorkspaceTable(
            id: '',
            name: view.name,
            labelColumnId: '',
            columns: const [],
            revision: view.revision,
            schemaRevision: 0,
          )
        : await LocalWorkspaceTableRepository(
            database,
            workspaceId,
          ).table(view.tableId);

    return (view: view, table: table);
  }

  Future<bool> _replayed(WorkspaceItemDuplication request) =>
      LocalWorkspaceRecordBatchReceipt(
        database,
        workspaceId,
      ).replayed(request.requestId, _digest(request));

  Future<void> _save(
    LocalWorkspaceViewRepository repository,
    WorkspaceView copy,
    WorkspaceItemDuplication request,
  ) async {
    final _ = await repository.save(copy, requestId: request.requestId);
    await LocalWorkspaceRecordBatchReceipt(
      database,
      workspaceId,
    ).save(request.requestId, _digest(request));
  }
}

WorkspaceView _copiedView(
  WorkspaceView source,
  WorkspaceItemDuplication request,
) {
  if (source.revision != request.expectedRevision) {
    throw const WorkspaceTableException(conflict: true);
  }

  return WorkspaceViewMapper.fromJson({
    ...WorkspaceViewMapper.toJson(source),
    'id': request.targetId,
    'name': request.name.trim(),
    'parentId': request.parentId,
    'revision': 0,
  });
}

String _digest(WorkspaceItemDuplication request) =>
    sha256.convert(utf8.encode(jsonEncode(request.toJson()))).toString();
