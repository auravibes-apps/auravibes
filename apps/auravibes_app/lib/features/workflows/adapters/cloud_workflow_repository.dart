import 'package:auravibes_app/features/workflows/adapters/workflow_repository.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:collection/collection.dart';

class CloudWorkflowRepository implements WorkflowRepository {
  new({required this.workspaceId, required this.store});

  final String workspaceId;
  final CloudWorkspaceResourceStore store;

  @override
  Stream<List<WorkspaceWorkflow>> watchWorkflows(String _) => store
      .watch(.workflow)
      .map((resources) => _activeWorkflows(resources, workspaceId));

  @override
  Stream<List<WorkspaceWorkflow>> watchDirectory(String _, String? parentId) =>
      store
          .watch(.workflow)
          .map(
            (resources) => [
              for (final workflow in _activeWorkflows(resources, workspaceId))
                if (workflow.parentId == parentId) workflow,
            ],
          );

  @override
  Future<List<WorkspaceWorkflow>> getWorkflows(String _) async =>
      _activeWorkflows(await store.watch(.workflow).first, workspaceId);

  @override
  Future<WorkspaceWorkflow?> getWorkflow(String id) async => _findResource(
    await store.watch(.workflow).first,
    id,
  )?._workflow(workspaceId);

  @override
  Future<WorkspaceWorkflow> saveWorkflow(WorkspaceWorkflow workflow) =>
      CloudWorkflowWriter.save(store, workflow);
}

abstract final class CloudWorkflowWriter {
  static Future<WorkspaceWorkflow> save(
    CloudWorkspaceResourceStore store,
    WorkspaceWorkflow workflow,
  ) async {
    if (!workflow.canManage) throw const WorkspaceTableException(denied: true);
    final resources = await store.watch(.workflow).first;
    final current = _findResource(resources, workflow.id, includeDeleted: true);
    if (current?.deletedAt != null) {
      throw const WorkspaceTableException(denied: true);
    }
    final data = workflow.toResourceData();
    await _write(store, workflow, current, data);

    return workflow.copyWith(revision: (current?.revision ?? 0) + 1);
  }

  static Future<void> _write(
    CloudWorkspaceResourceStore store,
    WorkspaceWorkflow workflow,
    WorkspaceResource? current,
    Map<String, Object?> data,
  ) async {
    if (current == null) {
      await store.create(kind: .workflow, id: workflow.id, data: data);

      return;
    }
    await store.update(
      kind: .workflow,
      id: workflow.id,
      revision: workflow.revision,
      data: data,
    );
  }
}

List<WorkspaceWorkflow> _activeWorkflows(
  List<WorkspaceResource> resources,
  String workspaceId,
) => [
  for (final resource in resources)
    if (resource.deletedAt == null) resource._workflow(workspaceId),
]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

WorkspaceResource? _findResource(
  List<WorkspaceResource> resources,
  String id, {
  bool includeDeleted = false,
}) => resources
    .where(
      (resource) =>
          resource.resourceId == id &&
          (includeDeleted || resource.deletedAt == null),
    )
    .firstOrNull;

extension on WorkspaceResource {
  WorkspaceWorkflow _workflow(String workspaceId) {
    final data = CloudResourceMapper.decode(this);

    return WorkspaceWorkflow.fromResource((
      id: resourceId,
      workspaceId: workspaceId,
      revision: revision,
      deletedAt: deletedAt,
      canManage: data['canManageWorkflow'] == true,
      data: data,
      createdAt: createdAt,
      updatedAt: updatedAt,
    ));
  }
}
