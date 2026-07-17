import 'dart:convert';

import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/domain/entities/agent_tool_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

typedef ReadCloudAgentTools = Future<List<WorkspaceResource>> Function();
typedef PatchCloudAgentTools =
    Future<PatchWorkspaceStateResponse> Function({
      required String requestId,
      required List<WorkspacePatchOperation> operations,
    });

class CloudAgentToolsRepository implements AgentToolsRepositoryContract {
  const CloudAgentToolsRepository({required this.read, required this.patch});

  final ReadCloudAgentTools read;
  final PatchCloudAgentTools patch;

  Map<String, dynamic> _data(WorkspaceResource resource) =>
      CloudResourceMapper.decode(resource);

  @override
  Future<List<AgentToolOverrideEntity>> getAgentTools(String agentId) async =>
      (await read())
          .where((resource) {
            if (resource.deletedAt != null) return false;
            final data = _data(resource);

            return data['agentId'] == agentId && data['toolId'] is String;
          })
          .map((resource) {
            final data = _data(resource);

            return AgentToolOverrideEntity(
              agentId: agentId,
              toolId: data['toolId'] as String,
              permissionMode: CloudResourceMapper.permission(
                data['permissionMode'],
              ),
            );
          })
          .toList();

  @override
  Future<AgentToolOverrideEntity> setAgentToolPermission(
    String agentId,
    String toolId, {
    required ToolPermissionMode permissionMode,
  }) async {
    final existing = (await read()).where((resource) {
      if (resource.deletedAt != null) return false;
      final data = _data(resource);

      return data['agentId'] == agentId && data['toolId'] == toolId;
    }).firstOrNull;
    final operation = existing == null
        ? WorkspacePatchOperationKind.create
        : WorkspacePatchOperationKind.update;
    final id = existing?.resourceId ?? const UuidV7().generate();
    final response = await patch(
      requestId: const UuidV7().generate(),
      operations: [
        WorkspacePatchOperation(
          operation: operation,
          resourceKind: .agentAssociation,
          resourceId: id,
          data: jsonEncode({
            'agentId': agentId,
            'toolId': toolId,
            'permissionMode': permissionMode.name,
          }),
          fieldMask: const [],
          expectedRevision: existing?.revision,
        ),
      ],
    );
    final data = _data(response.resources.single);

    return AgentToolOverrideEntity(
      agentId: data['agentId'] as String,
      toolId: data['toolId'] as String,
      permissionMode: CloudResourceMapper.permission(data['permissionMode']),
    );
  }

  @override
  Future<bool> clearAgentToolPermission(String agentId, String toolId) async {
    final existing = (await read()).where((resource) {
      if (resource.deletedAt != null) return false;
      final data = _data(resource);

      return data['agentId'] == agentId && data['toolId'] == toolId;
    }).firstOrNull;
    if (existing == null) return false;
    final _ = await patch(
      requestId: const UuidV7().generate(),
      operations: [
        WorkspacePatchOperation(
          operation: .delete,
          resourceKind: .agentAssociation,
          resourceId: existing.resourceId,
          fieldMask: const [],
          expectedRevision: existing.revision,
        ),
      ],
    );

    return true;
  }
}
