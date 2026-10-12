import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workflows.dart';
import 'package:drift/drift.dart';

part 'workflows_dao.g.dart';

@DriftAccessor(tables: [Workflows])
class WorkflowsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$WorkflowsDaoMixin;

extension WorkflowsDaoReadOperations on WorkflowsDao {
  Stream<List<WorkflowsTable>> watchByWorkspace(String workspaceId) =>
      (select(workflows)
            ..where((table) => table.workspaceId.equals(workspaceId))
            ..orderBy([
              (table) => OrderingTerm(expression: table.updatedAt, mode: .desc),
            ]))
          .watch();

  Future<List<WorkflowsTable>> getByWorkspace(String workspaceId) =>
      (select(workflows)
            ..where((table) => table.workspaceId.equals(workspaceId))
            ..orderBy([
              (table) => OrderingTerm(expression: table.updatedAt, mode: .desc),
            ]))
          .get();

  Future<WorkflowsTable?> getById(String id) => (select(
    workflows,
  )..where((table) => table.id.equals(id))).getSingleOrNull();
}

extension WorkflowsDaoWriteOperations on WorkflowsDao {
  Future<void> save(WorkflowsCompanion workflow) =>
      into(workflows).insertOnConflictUpdate(workflow);
}
