import 'dart:convert';

import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

typedef ReadCloudAgents = Future<List<WorkspaceResource>> Function();
typedef PatchCloudAgents =
    Future<PatchWorkspaceStateResponse> Function({
      required String requestId,
      required List<WorkspacePatchOperation> operations,
    });

class CloudAgentRepository implements AgentRepository {
  CloudAgentRepository({
    required this.workspaceId,
    required this.read,
    required this.patch,
  });

  final String workspaceId;
  final ReadCloudAgents read;
  final PatchCloudAgents patch;
  final Map<String, int> _revisions = {};

  @override
  Stream<List<AgentEntity>> watchAgentsByWorkspace(String workspaceId) async* {
    yield await getAgentsByWorkspace(workspaceId);
  }

  @override
  Future<List<AgentEntity>> getAgentsByWorkspace(String workspaceId) async {
    final resources = await read();
    for (final resource in resources) {
      _revisions[resource.resourceId] = resource.revision;
    }

    return [
      for (final resource in resources)
        if (resource.resourceKind == WorkspaceResourceKind.agent &&
            resource.deletedAt == null)
          _decode(resource, resources),
    ];
  }

  @override
  Future<AgentEntity?> getAgentById(String agentId) async {
    final resources = await read();
    final resource = resources
        .where(
          (item) =>
              item.resourceKind == WorkspaceResourceKind.agent &&
              item.resourceId == agentId &&
              item.deletedAt == null,
        )
        .firstOrNull;
    if (resource == null) return null;
    _revisions[agentId] = resource.revision;

    return _decode(resource, resources);
  }

  @override
  Future<AgentEntity> createAgent(
    String workspaceId,
    AgentToCreate agent,
  ) async {
    final id = const UuidV7().generate();
    final response = await patch(
      requestId: const UuidV7().generate(),
      operations: [
        _operation(WorkspacePatchOperationKind.create, id, agent),
        ..._associations(id, agent.skills, WorkspacePatchOperationKind.create),
      ],
    );

    return _decode(
      response.resources.singleWhere(
        (resource) => resource.resourceKind == WorkspaceResourceKind.agent,
      ),
      response.resources,
    );
  }

  @override
  Future<AgentEntity> updateAgent(
    String agentId,
    AgentToUpdate agent,
  ) async {
    final resources = await read();
    final associations = _agentSkillAssociations(resources, agentId);
    for (final resource in resources) {
      _revisions[resource.resourceId] = resource.revision;
    }
    final response = await patch(
      requestId: const UuidV7().generate(),
      operations: [
        _operation(
          WorkspacePatchOperationKind.update,
          agentId,
          agent,
          expectedRevision: _revisions[agentId],
        ),
        ..._deleteAssociations(associations),
        ..._associations(
          agentId,
          agent.skills,
          WorkspacePatchOperationKind.create,
        ),
      ],
    );
    final resource = response.resources.singleWhere(
      (item) => item.resourceKind == WorkspaceResourceKind.agent,
    );
    _revisions[agentId] = resource.revision;

    return _decode(
      resource,
      response.resources,
    );
  }

  @override
  Future<bool> deleteAgent(String agentId) async {
    final resources = await read();
    final associations = _agentAssociations(resources, agentId);
    for (final resource in resources) {
      _revisions[resource.resourceId] = resource.revision;
    }
    final _ = await patch(
      requestId: const UuidV7().generate(),
      operations: [
        ..._deleteAssociations(associations),
        WorkspacePatchOperation(
          operation: WorkspacePatchOperationKind.delete,
          resourceKind: WorkspaceResourceKind.agent,
          resourceId: agentId,
          fieldMask: const [],
          expectedRevision: _revisions[agentId],
        ),
      ],
    );

    return true;
  }

  WorkspacePatchOperation _operation(
    WorkspacePatchOperationKind kind,
    String id,
    Object agent, {
    int? expectedRevision,
  }) {
    final data = switch (agent) {
      AgentToCreate(
        :final name,
        :final description,
        :final content,
        :final isEnabled,
        :final visibility,
      ) =>
        _agentData(name, description, content, isEnabled, visibility),
      AgentToUpdate(
        :final name,
        :final description,
        :final content,
        :final isEnabled,
        :final visibility,
      ) =>
        _agentData(name, description, content, isEnabled, visibility),
      _ => throw ArgumentError.value(agent),
    };

    return WorkspacePatchOperation(
      operation: kind,
      resourceKind: WorkspaceResourceKind.agent,
      resourceId: id,
      data: jsonEncode({'id': id, ...data}),
      fieldMask: const [],
      expectedRevision: expectedRevision,
    );
  }

  Map<String, Object> _agentData(
    String name,
    String description,
    String content,
    bool isEnabled,
    AgentVisibility visibility,
  ) => {
    'name': name.trim(),
    'description': description.trim(),
    'content': content.trim(),
    'isEnabled': isEnabled,
    'visibility': visibility.name,
  };

  Iterable<WorkspacePatchOperation> _associations(
    String agentId,
    List<AgentSkillRef> skills,
    WorkspacePatchOperationKind operation,
  ) sync* {
    for (final skill in skills) {
      final data = switch (skill) {
        UserAgentSkillRef(:final skillId) => {'skillId': skillId},
        AppAgentSkillRef(:final identifier) => {
          'skillId': identifier,
          'appSkillIdentifier': identifier,
        },
      };
      yield WorkspacePatchOperation(
        operation: operation,
        resourceKind: WorkspaceResourceKind.agentAssociation,
        resourceId: const UuidV7().generate(),
        data: jsonEncode({'agentId': agentId, ...data}),
        fieldMask: const [],
      );
    }
  }

  Iterable<WorkspacePatchOperation> _deleteAssociations(
    Iterable<WorkspaceResource> associations,
  ) => associations.map(
    (resource) => WorkspacePatchOperation(
      operation: WorkspacePatchOperationKind.delete,
      resourceKind: WorkspaceResourceKind.agentAssociation,
      resourceId: resource.resourceId,
      fieldMask: const [],
      expectedRevision: resource.revision,
    ),
  );

  List<WorkspaceResource> _agentAssociations(
    Iterable<WorkspaceResource> resources,
    String agentId,
  ) => resources
      .where(
        (resource) =>
            resource.resourceKind == WorkspaceResourceKind.agentAssociation &&
            resource.deletedAt == null &&
            CloudResourceMapper.decode(resource)['agentId'] == agentId,
      )
      .toList();

  List<WorkspaceResource> _agentSkillAssociations(
    Iterable<WorkspaceResource> resources,
    String agentId,
  ) => _agentAssociations(resources, agentId)
      .where(
        (resource) => CloudResourceMapper.decode(resource)['skillId'] is String,
      )
      .toList();

  AgentEntity _decode(
    WorkspaceResource resource,
    Iterable<WorkspaceResource> resources,
  ) {
    final data = CloudResourceMapper.decode(resource);
    final skills = _agentSkillAssociations(resources, resource.resourceId).map((
      item,
    ) {
      final association = CloudResourceMapper.decode(item);
      final appSkillIdentifier = association['appSkillIdentifier'] as String?;

      return appSkillIdentifier == null
          ? AgentSkillRef.user(association['skillId'] as String)
          : AgentSkillRef.app(appSkillIdentifier);
    }).toList();

    return AgentEntity(
      id: resource.resourceId,
      workspaceId: workspaceId,
      name: data['name'] as String,
      content: data['content'] as String,
      skills: skills,
      createdAt: resource.createdAt,
      updatedAt: resource.updatedAt,
      description: data['description'] as String? ?? '',
      isEnabled: data['isEnabled'] as bool? ?? true,
      visibility: CloudResourceMapper.visibility(data['visibility']),
    );
  }
}
