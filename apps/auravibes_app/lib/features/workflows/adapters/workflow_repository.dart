import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';

abstract interface class WorkflowRepository {
  Stream<List<WorkflowDefinition>> watchWorkflows(String workspaceId);

  Future<List<WorkflowDefinition>> getWorkflows(String workspaceId);

  Future<WorkflowDefinition?> getWorkflow(String id);

  Future<void> saveWorkflow(WorkflowDefinition workflow);
}
