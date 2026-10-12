import 'package:auravibes_app/features/workflows/adapters/workflow_repository.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:collection/collection.dart';

class CloudWorkflowRepository implements WorkflowRepository {
  new({required this.workspaceId, required this.store});

  final String workspaceId;
  final CloudWorkspaceResourceStore store;

  @override
  Stream<List<WorkflowDefinition>> watchWorkflows(String _) => store
      .watch(.workflow)
      .map((resources) => _activeWorkflows(resources, workspaceId));

  @override
  Future<List<WorkflowDefinition>> getWorkflows(String _) async =>
      _activeWorkflows(await store.watch(.workflow).first, workspaceId);

  @override
  Future<WorkflowDefinition?> getWorkflow(String id) async => _findResource(
    await store.watch(.workflow).first,
    id,
  )?._workflow(workspaceId);

  @override
  Future<void> saveWorkflow(WorkflowDefinition workflow) async {
    final current = _findResource(
      await store.watch(.workflow).first,
      workflow.id,
    );
    final data = workflow.toResourceData();
    if (current == null) {
      await store.create(kind: .workflow, id: workflow.id, data: data);

      return;
    }
    await store.update(
      kind: .workflow,
      id: workflow.id,
      revision: current.revision,
      data: data,
    );
  }
}

List<WorkflowDefinition> _activeWorkflows(
  List<WorkspaceResource> resources,
  String workspaceId,
) => [
  for (final resource in resources)
    if (resource.deletedAt == null) resource._workflow(workspaceId),
]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

WorkspaceResource? _findResource(
  List<WorkspaceResource> resources,
  String id,
) => resources
    .where(
      (resource) => resource.resourceId == id && resource.deletedAt == null,
    )
    .firstOrNull;

extension on WorkspaceResource {
  WorkflowDefinition _workflow(String workspaceId) =>
      WorkflowDefinition.fromResource(
        id: resourceId,
        workspaceId: workspaceId,
        data: CloudResourceMapper.decode(this),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
