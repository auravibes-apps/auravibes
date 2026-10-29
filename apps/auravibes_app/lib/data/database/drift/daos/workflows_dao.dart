import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workflows.dart';
import 'package:drift/drift.dart';

part 'workflows_dao.g.dart';

@DriftAccessor(tables: [WorkspaceWorkflows])
class WorkspaceWorkflowsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$WorkspaceWorkflowsDaoMixin;

extension WorkspaceWorkflowsDaoReadOperations on WorkspaceWorkflowsDao {
  Stream<List<WorkspaceWorkflowRow>> watchByDirectory(
    String workspaceId,
    String? parentId,
  ) =>
      (select(workspaceWorkflows)
            ..where(
              (table) =>
                  table.workspaceId.equals(workspaceId) &
                  table.parentId.equalsNullable(parentId) &
                  table.deletedAt.isNull(),
            )
            ..orderBy([
              (table) => OrderingTerm(expression: table.updatedAt, mode: .desc),
            ]))
          .watch();

  Stream<List<WorkspaceWorkflowRow>> watchWorkspace(String workspaceId) =>
      (select(workspaceWorkflows)
            ..where(
              (table) =>
                  table.workspaceId.equals(workspaceId) &
                  table.deletedAt.isNull(),
            )
            ..orderBy([
              (table) => OrderingTerm(expression: table.updatedAt, mode: .desc),
            ]))
          .watch();

  Future<List<WorkspaceWorkflowRow>> getWorkspace(String workspaceId) =>
      (select(workspaceWorkflows)
            ..where(
              (table) =>
                  table.workspaceId.equals(workspaceId) &
                  table.deletedAt.isNull(),
            )
            ..orderBy([
              (table) => OrderingTerm(expression: table.updatedAt, mode: .desc),
            ]))
          .get();

  Future<WorkspaceWorkflowRow?> getById(String id) =>
      (select(workspaceWorkflows)
            ..where((table) => table.id.equals(id) & table.deletedAt.isNull()))
          .getSingleOrNull();

  Future<WorkspaceWorkflowRow?> getByIdIncludingDeleted(String id) => (select(
    workspaceWorkflows,
  )..where((table) => table.id.equals(id))).getSingleOrNull();
}

extension WorkspaceWorkflowsDaoWriteOperations on WorkspaceWorkflowsDao {
  Future<void> save(WorkspaceWorkflowsCompanion workflow) =>
      into(workspaceWorkflows).insertOnConflictUpdate(workflow);
}
