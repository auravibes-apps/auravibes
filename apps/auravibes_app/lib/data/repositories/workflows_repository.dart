import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workflows/adapters/workflow_repository.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';

class WorkflowsRepository implements WorkflowRepository {
  const new(this._database);

  final AppDatabase _database;

  @override
  Stream<List<WorkflowDefinition>> watchWorkflows(String workspaceId) =>
      _database.workflowsDao
          .watchByWorkspace(workspaceId)
          .map((rows) => rows.map(_mapRow).toList());

  @override
  Future<List<WorkflowDefinition>> getWorkflows(String workspaceId) async =>
      (await _database.workflowsDao.getByWorkspace(workspaceId))
          .map(_mapRow)
          .toList();

  @override
  Future<WorkflowDefinition?> getWorkflow(String id) async {
    final row = await _database.workflowsDao.getById(id);

    return row == null ? null : _mapRow(row);
  }

  @override
  Future<void> saveWorkflow(WorkflowDefinition workflow) =>
      _database.workflowsDao.save(
        .insert(
          id: .new(workflow.id),
          workspaceId: workflow.workspaceId,
          name: workflow.name,
          definitionJson: workflow.encode(),
          createdAt: .new(workflow.createdAt.toUtc()),
          updatedAt: .new(workflow.updatedAt.toUtc()),
        ),
      );
}

WorkflowDefinition _mapRow(WorkflowsTable row) {
  final workflow = WorkflowDefinition.decode(row.definitionJson);

  return workflow.copyWith(
    id: row.id,
    workspaceId: row.workspaceId,
    name: row.name,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
