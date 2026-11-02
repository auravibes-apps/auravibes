import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_item_duplication.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart' as cloud;
import 'package:collection/collection.dart';

class const CloudWorkspaceItemDuplicationRepository(
  final cloud.Client client,
  final int workspaceId, {
  final CloudWorkspaceResourceStore? store,
}) implements WorkspaceItemDuplicationRepository {
  CloudWorkspaceResourceStore? get _store => store;

  @override
  Future<void> copy(WorkspaceItemDuplication request) async {
    request.validate();
    try {
      await _copy(request);
    } on CloudAppException catch (error, stackTrace) {
      if (error.code != 'validationFailed') rethrow;
      Error.throwWithStackTrace(
        const WorkspaceTableException(unsupportedCopy: true),
        stackTrace,
      );
    }
  }

  Future<void> _copy(WorkspaceItemDuplication request) =>
      CloudAppErrors.guardCall(.state, () => _execute(request));

  Future<void> _execute(WorkspaceItemDuplication request) async {
    final input = _input(request, workspaceId);
    if (request.kind == .workflow) {
      await _workflow(request);
    } else if (request.kind == .table) {
      final _ = await client.workspaceState.duplicateTable(input);
    } else {
      final _ = await client.workspaceView.duplicate(input);
    }
  }

  Future<void> _workflow(WorkspaceItemDuplication request) async {
    final store = _store ?? (throw const WorkspaceTableException());
    final resources = await store.watch(.workflow).first;
    final source = resources
        .where(
          (item) =>
              item.resourceId == request.sourceId && item.deletedAt == null,
        )
        .firstOrNull;
    if (source == null) throw const WorkspaceTableException(denied: true);
    if (source.revision != request.expectedRevision) {
      throw const WorkspaceTableException(conflict: true);
    }
    final data = CloudResourceMapper.decode(source);
    if (data['canManageWorkflow'] != true) {
      throw const WorkspaceTableException(denied: true);
    }
    final workflow = WorkspaceWorkflow.fromResource((
      id: source.resourceId,
      workspaceId: '$workspaceId',
      revision: source.revision,
      deletedAt: source.deletedAt,
      canManage: data['canManageWorkflow'] == true,
      data: data,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    ));
    final now = DateTime.now().toUtc();
    final copy = workflow.copyWith(
      id: request.targetId,
      parentId: request.parentId,
      clearParentId: request.parentId == null,
      name: request.name.trim(),
      revision: 1,
      createdAt: now,
      updatedAt: now,
      clearDeletedAt: true,
    );
    await store.create(
      kind: .workflow,
      id: copy.id,
      data: copy.toResourceData(),
    );
  }
}

cloud.DuplicateWorkspaceItemRequest _input(
  WorkspaceItemDuplication request,
  int workspaceId,
) => .new(
  workspaceId: workspaceId,
  requestId: request.requestId,
  sourceId: request.sourceId,
  expectedRevision: request.expectedRevision,
  targetId: request.targetId,
  name: request.name,
  parentId: request.parentId,
  copyRecords: request.copyRecords,
);
