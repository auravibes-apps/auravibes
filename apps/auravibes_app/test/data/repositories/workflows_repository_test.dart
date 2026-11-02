import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workflows_repository.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  tearDownAll(database.close);

  test('saves and reads workspace workflow definitions', () async {
    final workspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Workflow workspace', type: .local),
    );
    final repository = WorkflowsRepository(database);
    final now = DateTime.utc(2026, 10, 12);
    final workflow = WorkspaceWorkflow.create(
      id: 'workflow-1',
      workspaceId: workspace.id,
      name: 'Summarize',
      description: 'Compose a response',
      inputs: const [WorkflowPort(id: 'query', name: 'Query', type: .string)],
      createdAt: now,
      updatedAt: now,
    );

    await repository.saveWorkflow(workflow);
    final loaded = await repository.getWorkflow(workflow.id);

    expect(loaded?.workspaceId, workspace.id);
    expect(loaded?.name, workflow.name);
    expect(loaded?.inputs.single.type, WorkflowValueType.string);
    expect(
      (await repository.getWorkflows(workspace.id)).single.id,
      workflow.id,
    );
  });
}
