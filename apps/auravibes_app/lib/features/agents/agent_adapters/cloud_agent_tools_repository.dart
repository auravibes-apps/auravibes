import 'dart:convert';

import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/domain/entities/agent_tool_override_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

typedef ReadCloudAgentTools = Future<List<WorkspaceResource>> Function();
typedef PatchCloudAgentTools = Future<PatchWorkspaceStateResponse> Function({
  required String requestId,
  required List<WorkspacePatchOperation> operations,
});

typedef _AgentToolPermissionRequest = ({
  String agentId,
  String toolId,
  ToolPermissionMode permissionMode,
});

typedef _AgentToolPermissionOperation = ({
  String agentId,
  String toolId,
  ToolPermissionMode permissionMode,
  WorkspaceResource? existing,
});

class const CloudAgentToolsRepository({
  required final ReadCloudAgentTools read,
  required final PatchCloudAgentTools patch,
}) implements AgentToolsRepositoryContract {
  new fromStore({required CloudWorkspaceResourceStore store})
    : this(patch: store.patch, read: () => _readCloudAgentTools(store));

  @override
  Future<List<AgentToolOverrideEntity>> getAgentTools(String agentId) async {
    final resources = await read();

    return resources
        .where((resource) => _matchesAgentTool(resource, agentId))
        .map(_toAgentToolOverride)
        .toList();
  }

  @override
  Future<AgentToolOverrideEntity> setAgentToolPermission(
    String agentId,
    String toolId, {
    required ToolPermissionMode permissionMode,
  }) => _setAgentToolPermission(
    read: read,
    patch: patch,
    request: (agentId: agentId, toolId: toolId, permissionMode: permissionMode),
  );

  @override
  Future<bool> clearAgentToolPermission(String agentId, String toolId) async {
    final existing = (await read()).where((resource) {
      return _matchesAgentTool(resource, agentId, toolId);
    }).firstOrNull;
    if (existing == null) return false;
    final _ = await patch(
      requestId: const UuidV7().generate(),
      operations: [_deleteAgentToolOperation(existing)],
    );

    return true;
  }
}

Future<AgentToolOverrideEntity> _setAgentToolPermission({
  required ReadCloudAgentTools read,
  required PatchCloudAgentTools patch,
  required _AgentToolPermissionRequest request,
}) async {
  final existing = await _findAgentTool(read, request);
  final response = await _patchAgentToolPermission(patch, request, existing);

  return _toAgentToolOverride(response.resources.single);
}

Future<WorkspaceResource?> _findAgentTool(
  ReadCloudAgentTools read,
  _AgentToolPermissionRequest request,
) async => (await read())
    .where(
      (resource) =>
          _matchesAgentTool(resource, request.agentId, request.toolId),
    )
    .firstOrNull;

Future<PatchWorkspaceStateResponse> _patchAgentToolPermission(
  PatchCloudAgentTools patch,
  _AgentToolPermissionRequest request,
  WorkspaceResource? existing,
) => patch(
  requestId: const UuidV7().generate(),
  operations: [
    _agentToolPermissionOperation((
      agentId: request.agentId,
      toolId: request.toolId,
      permissionMode: request.permissionMode,
      existing: existing,
    )),
  ],
);

bool _matchesAgentTool(
  WorkspaceResource resource,
  String agentId, [
  String? toolId,
]) {
  if (resource.deletedAt != null) return false;
  final data = CloudResourceMapper.decode(resource);

  return data['agentId'] == agentId &&
      (toolId == null ? data['toolId'] is String : data['toolId'] == toolId);
}

AgentToolOverrideEntity _toAgentToolOverride(WorkspaceResource resource) {
  final data = CloudResourceMapper.decode(resource);

  return AgentToolOverrideEntity(
    agentId: data['agentId'] as String,
    toolId: data['toolId'] as String,
    permissionMode: CloudResourceMapper.permission(data['permissionMode']),
  );
}

WorkspacePatchOperation _agentToolPermissionOperation(
  _AgentToolPermissionOperation request,
) => WorkspacePatchOperation(
  operation: _agentToolOperationKind(request.existing),
  resourceKind: .agentAssociation,
  resourceId: _agentToolResourceId(request.existing),
  data: jsonEncode(_agentToolPermissionData(request)),
  fieldMask: const [],
  expectedRevision: request.existing?.revision,
);

WorkspacePatchOperationKind _agentToolOperationKind(
  WorkspaceResource? existing,
) => existing == null
    ? WorkspacePatchOperationKind.create
    : WorkspacePatchOperationKind.update;

String _agentToolResourceId(WorkspaceResource? existing) =>
    existing?.resourceId ?? const UuidV7().generate();

Map<String, String> _agentToolPermissionData(
  _AgentToolPermissionOperation request,
) => {
  'agentId': request.agentId,
  'toolId': request.toolId,
  'permissionMode': request.permissionMode.name,
};

WorkspacePatchOperation _deleteAgentToolOperation(WorkspaceResource resource) =>
    WorkspacePatchOperation(
      operation: .delete,
      resourceKind: .agentAssociation,
      resourceId: resource.resourceId,
      fieldMask: const [],
      expectedRevision: resource.revision,
    );

Future<List<WorkspaceResource>> _readCloudAgentTools(
  CloudWorkspaceResourceStore store,
) async {
  final response = await store.read(
    pages: [
      WorkspaceResourcePageRequest(resourceKind: .agentAssociation, limit: 100),
    ],
  );
  if (response.pages.isEmpty) return [];

  return response.pages.single.resources;
}
