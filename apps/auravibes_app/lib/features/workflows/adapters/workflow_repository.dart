import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';

abstract interface class WorkflowRepository {
  Stream<List<WorkspaceWorkflow>> watchWorkflows(String workspaceId);

  Stream<List<WorkspaceWorkflow>> watchDirectory(
    String workspaceId,
    String? parentId,
  );

  Future<List<WorkspaceWorkflow>> getWorkflows(String workspaceId);

  Future<WorkspaceWorkflow?> getWorkflow(String id);

  Future<WorkspaceWorkflow> saveWorkflow(WorkspaceWorkflow workflow);
}
