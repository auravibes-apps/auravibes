import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workflows/adapters/workflow_repository.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';

class WorkflowsRepository implements WorkflowRepository {
  const new(this._database);

  final AppDatabase _database;

  @override
  Stream<List<WorkspaceWorkflow>> watchWorkflows(String workspaceId) =>
      _database.workspaceWorkflowsDao
          .watchWorkspace(workspaceId)
          .map((rows) => rows.map(_mapRow).toList());

  @override
  Stream<List<WorkspaceWorkflow>> watchDirectory(
    String workspaceId,
    String? parentId,
  ) => _database.workspaceWorkflowsDao
      .watchByDirectory(workspaceId, parentId)
      .map((rows) => rows.map(_mapRow).toList());

  @override
  Future<List<WorkspaceWorkflow>> getWorkflows(String workspaceId) async =>
      (await _database.workspaceWorkflowsDao.getWorkspace(workspaceId))
          .map(_mapRow)
          .toList();

  @override
  Future<WorkspaceWorkflow?> getWorkflow(String id) async {
    final row = await _database.workspaceWorkflowsDao.getById(id);

    return row == null ? null : _mapRow(row);
  }

  @override
  Future<WorkspaceWorkflow> saveWorkflow(WorkspaceWorkflow workflow) async {
    final current = await _database.workspaceWorkflowsDao
        .getByIdIncludingDeleted(workflow.id);
    if (current != null &&
        (current.deletedAt != null ||
            current.workspaceId != workflow.workspaceId)) {
      throw const WorkspaceTableException(denied: true);
    }
    if (current != null && current.revision != workflow.revision) {
      throw const WorkspaceTableException(conflict: true);
    }
    await _requireParent(workflow);
    await _database.workspaceWorkflowsDao.save(
      WorkspaceWorkflowsCompanion.insert(
        id: .new(workflow.id),
        workspaceId: workflow.workspaceId,
        parentId: .new(workflow.parentId),
        name: workflow.name,
        description: .new(workflow.description),
        revision: .new((current?.revision ?? 0) + 1),
        definitionJson: workflow.definition.encode(),
        createdAt: .new(current?.createdAt ?? workflow.createdAt.toUtc()),
        updatedAt: .new(workflow.updatedAt.toUtc()),
      ),
    );

    return workflow.copyWith(
      revision: (current?.revision ?? 0) + 1,
      createdAt: current?.createdAt ?? workflow.createdAt,
    );
  }

  Future<void> _requireParent(WorkspaceWorkflow workflow) async {
    final parentId = workflow.parentId;
    if (parentId == null) return;
    final folder =
        await (_database.select(_database.workspaceFolders)..where(
              (row) =>
                  row.id.equals(parentId) &
                  row.workspaceId.equals(workflow.workspaceId) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (folder == null) throw const WorkspaceTableException(denied: true);
  }
}

WorkspaceWorkflow _mapRow(WorkspaceWorkflowRow row) => WorkspaceWorkflow(
  id: row.id,
  workspaceId: row.workspaceId,
  parentId: row.parentId,
  name: row.name,
  description: row.description,
  revision: row.revision,
  createdAt: row.createdAt.toUtc(),
  updatedAt: row.updatedAt.toUtc(),
  deletedAt: row.deletedAt?.toUtc(),
  definition: WorkflowDefinition.decode(row.definitionJson),
);
