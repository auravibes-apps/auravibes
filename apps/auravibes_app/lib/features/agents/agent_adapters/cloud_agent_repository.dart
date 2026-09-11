import 'dart:convert';

import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

typedef ReadCloudAgents = Future<List<WorkspaceResource>> Function();
typedef PatchCloudAgents = Future<PatchWorkspaceStateResponse> Function({
  required String requestId,
  required List<WorkspacePatchOperation> operations,
});

typedef _AgentData = ({
  String name,
  String description,
  String content,
  bool isEnabled,
  AgentVisibility visibility,
});

typedef _AgentOperationData = ({
  WorkspacePatchOperationKind kind,
  String id,
  Object agent,
  int? expectedRevision,
});

typedef _AgentUpdateData = ({
  Iterable<WorkspaceResource> resources,
  String agentId,
  AgentToUpdate agent,
  Map<String, int> revisions,
});

typedef _AgentEntityInput = ({
  WorkspaceResource resource,
  String workspaceId,
  Map<String, dynamic> data,
  List<AgentSkillRef> skills,
});

typedef _AgentUpdateResponse = ({
  String agentId,
  String workspaceId,
  PatchWorkspaceStateResponse response,
  Map<String, int> revisions,
});

class CloudAgentRepository({
  @override required final String workspaceId,
  @override required final ReadCloudAgents read,
  @override required final PatchCloudAgents patch,
}) with _CloudAgentRepositoryRead, _CloudAgentRepositoryWrite
    implements AgentRepository {
  new fromStore({
    required String workspaceId,
    required CloudWorkspaceResourceStore store,
  }) : this(
         patch: store.patch,
         workspaceId: workspaceId,
         read: () => _readCloudAgentResources(store),
       );

  @override
  final Map<String, int> _revisions = {};

  @override
  Stream<List<AgentEntity>> watchAgentsByWorkspace(String workspaceId) =>
      _watchAgentsByWorkspace(workspaceId);
}

List<WorkspaceResource> _agentAssociations(
  Iterable<WorkspaceResource> resources,
  String agentId,
) => resources
    .where((resource) => _isAgentAssociation(resource, agentId))
    .toList();

bool _isAgentAssociation(WorkspaceResource resource, String agentId) {
  if (resource.resourceKind != WorkspaceResourceKind.agentAssociation ||
      resource.deletedAt != null) {
    return false;
  }

  return CloudResourceMapper.decode(resource)['agentId'] == agentId;
}

List<WorkspaceResource> _agentSkillAssociations(
  Iterable<WorkspaceResource> resources,
  String agentId,
) => _agentAssociations(resources, agentId)
    .where(
      (resource) => CloudResourceMapper.decode(resource)['skillId'] is String,
    )
    .toList();

AgentEntity _decodeAgent(
  WorkspaceResource resource,
  Iterable<WorkspaceResource> resources,
  String workspaceId,
) {
  final data = CloudResourceMapper.decode(resource);

  return _agentEntity((
    resource: resource,
    workspaceId: workspaceId,
    data: data,
    skills: _decodeAgentSkills(resources, resource.resourceId),
  ));
}

AgentEntity _agentEntity(_AgentEntityInput input) {
  return _baseAgentEntity(input).copyWith(
    description: input._description,
    isEnabled: input._isEnabled,
    visibility: input._visibility,
  );
}

AgentEntity _baseAgentEntity(_AgentEntityInput input) {
  final resource = input.resource;

  return AgentEntity(
    id: resource.resourceId,
    workspaceId: input.workspaceId,
    name: input._name,
    content: input._content,
    skills: input.skills,
    createdAt: resource.createdAt,
    updatedAt: resource.updatedAt,
  );
}

extension on _AgentEntityInput {
  String get _name => data['name'] as String;

  String get _content => data['content'] as String;

  String get _description => data['description'] as String? ?? '';

  bool get _isEnabled => data['isEnabled'] as bool? ?? true;

  AgentVisibility get _visibility =>
      CloudResourceMapper.visibility(data['visibility']);
}

AgentSkillRef _decodeSkill(WorkspaceResource resource) {
  final data = CloudResourceMapper.decode(resource);
  final appSkillIdentifier = data['appSkillIdentifier'] as String?;

  return appSkillIdentifier == null
      ? AgentSkillRef.user(data['skillId'] as String)
      : AgentSkillRef.app(appSkillIdentifier);
}

WorkspaceResource? _agentResource(
  Iterable<WorkspaceResource> resources,
  String agentId,
) => resources
    .where(
      (item) =>
          item.resourceKind == WorkspaceResourceKind.agent &&
          item.resourceId == agentId &&
          item.deletedAt == null,
    )
    .firstOrNull;

List<AgentSkillRef> _decodeAgentSkills(
  Iterable<WorkspaceResource> resources,
  String agentId,
) => _agentSkillAssociations(resources, agentId).map(_decodeSkill).toList();

mixin _CloudAgentRepositoryRead {
  String get workspaceId;
  ReadCloudAgents get read;
  Map<String, int> get _revisions;

  Stream<List<AgentEntity>> _watchAgentsByWorkspace(String workspaceId) async* {
    yield await getAgentsByWorkspace(workspaceId);
  }

  Future<List<AgentEntity>> getAgentsByWorkspace(String workspaceId) async {
    final resources = await read();
    for (final resource in resources) {
      _revisions[resource.resourceId] = resource.revision;
    }

    return [
      for (final resource in resources)
        if (resource.resourceKind == WorkspaceResourceKind.agent &&
            resource.deletedAt == null)
          _decodeAgent(resource, resources, workspaceId),
    ];
  }

  Future<AgentEntity?> getAgentById(String agentId) async {
    final resources = await read();
    final resource = _agentResource(resources, agentId);
    if (resource == null) return null;
    _revisions[agentId] = resource.revision;

    return _decodeAgent(resource, resources, workspaceId);
  }
}

mixin _CloudAgentRepositoryWrite {
  String get workspaceId;
  ReadCloudAgents get read;
  PatchCloudAgents get patch;
  Map<String, int> get _revisions;

  Future<AgentEntity> createAgent(
    String workspaceId,
    AgentToCreate agent,
  ) async {
    final id = const UuidV7().generate();
    final response = await _patchAgentState(
      patch,
      _createAgentOperations(id, agent),
    );

    return _decodeAgent(
      _agentResourceFromResponse(response),
      response.resources,
      workspaceId,
    );
  }

  Future<AgentEntity> updateAgent(String agentId, AgentToUpdate agent) =>
      _updateAgentResponse(agentId, agent).then(_decodeUpdatedAgent);

  Future<bool> deleteAgent(String agentId) async {
    final resources = await read();
    final _ = await _patchAgentState(
      patch,
      _deleteAgentOperations(resources, agentId, _revisions),
    );

    return true;
  }
}

extension on _CloudAgentRepositoryWrite {
  Future<_AgentUpdateResponse> _updateAgentResponse(
    String agentId,
    AgentToUpdate agent,
  ) async {
    final request = await _updateAgentRequest(agentId, agent);
    final response = await _patchAgentState(
      patch,
      _updateAgentOperations(request),
    );

    return _updatedAgentData(agentId, response);
  }

  Future<_AgentUpdateData> _updateAgentRequest(
    String agentId,
    AgentToUpdate agent,
  ) async => (
    resources: await read(),
    agentId: agentId,
    agent: agent,
    revisions: _revisions,
  );

  _AgentUpdateResponse _updatedAgentData(
    String agentId,
    PatchWorkspaceStateResponse response,
  ) => (
    agentId: agentId,
    workspaceId: workspaceId,
    response: response,
    revisions: _revisions,
  );
}

AgentEntity _decodeUpdatedAgent(_AgentUpdateResponse data) {
  final resource = _agentResourceFromResponse(data.response);
  data.revisions[data.agentId] = resource.revision;

  return _decodeAgent(resource, data.response.resources, data.workspaceId);
}

void _recordAgentRevisions(
  Map<String, int> revisions,
  Iterable<WorkspaceResource> resources,
) {
  for (final resource in resources) {
    revisions[resource.resourceId] = resource.revision;
  }
}

WorkspacePatchOperation _agentOperation(_AgentOperationData data) =>
    WorkspacePatchOperation(
      operation: data.kind,
      resourceKind: .agent,
      resourceId: data.id,
      data: jsonEncode({'id': data.id, ..._agentDataFor(data.agent)}),
      fieldMask: const [],
      expectedRevision: data.expectedRevision,
    );

Map<String, Object> _agentDataFor(Object agent) => switch (agent) {
  final AgentToCreate value => _agentData(value._data),
  final AgentToUpdate value => _agentData(value._data),
  _ => throw ArgumentError.value(agent),
};

extension on AgentToCreate {
  _AgentData get _data => (
    name: name,
    description: description,
    content: content,
    isEnabled: isEnabled,
    visibility: visibility,
  );
}

extension on AgentToUpdate {
  _AgentData get _data => (
    name: name,
    description: description,
    content: content,
    isEnabled: isEnabled,
    visibility: visibility,
  );
}

Map<String, Object> _agentData(_AgentData data) => {
  'name': data.name.trim(),
  'description': data.description.trim(),
  'content': data.content.trim(),
  'isEnabled': data.isEnabled,
  'visibility': data.visibility.name,
};

Iterable<WorkspacePatchOperation> _agentSkillPatchOperations(
  String agentId,
  List<AgentSkillRef> skills,
  WorkspacePatchOperationKind operation,
) sync* {
  for (final skill in skills) {
    yield WorkspacePatchOperation(
      operation: operation,
      resourceKind: .agentAssociation,
      resourceId: const UuidV7().generate(),
      data: jsonEncode({'agentId': agentId, ..._skillAssociationData(skill)}),
      fieldMask: const [],
    );
  }
}

Map<String, String> _skillAssociationData(AgentSkillRef skill) =>
    switch (skill) {
      UserAgentSkillRef(:final skillId) => {'skillId': skillId},
      AppAgentSkillRef(:final identifier) => {
        'skillId': identifier,
        'appSkillIdentifier': identifier,
      },
    };

Iterable<WorkspacePatchOperation> _deleteAgentAssociations(
  Iterable<WorkspaceResource> associations,
) => associations.map(
  (resource) => WorkspacePatchOperation(
    operation: .delete,
    resourceKind: .agentAssociation,
    resourceId: resource.resourceId,
    fieldMask: const [],
    expectedRevision: resource.revision,
  ),
);

Future<PatchWorkspaceStateResponse> _patchAgentState(
  PatchCloudAgents patch,
  List<WorkspacePatchOperation> operations,
) => patch(requestId: const UuidV7().generate(), operations: operations);

List<WorkspacePatchOperation> _createAgentOperations(
  String id,
  AgentToCreate agent,
) => [
  _agentOperation((
    kind: .create,
    id: id,
    agent: agent,
    expectedRevision: null,
  )),
  ..._agentSkillPatchOperations(id, agent.skills, .create),
];

WorkspaceResource _agentResourceFromResponse(
  PatchWorkspaceStateResponse response,
) => response.resources.singleWhere(
  (resource) => resource.resourceKind == WorkspaceResourceKind.agent,
);

List<WorkspacePatchOperation> _updateAgentOperations(_AgentUpdateData data) {
  final agentId = data.agentId;
  final associations = _agentSkillAssociations(data.resources, data.agentId);
  _recordAgentRevisions(data.revisions, data.resources);

  return _updatedAgentOperations(data, associations, agentId);
}

List<WorkspacePatchOperation> _updatedAgentOperations(
  _AgentUpdateData data,
  List<WorkspaceResource> associations,
  String agentId,
) => [
  _agentOperation((
    kind: .update,
    id: agentId,
    agent: data.agent,
    expectedRevision: data.revisions[agentId],
  )),
  ..._deleteAgentAssociations(associations),
  ..._agentSkillPatchOperations(agentId, data.agent.skills, .create),
];

List<WorkspacePatchOperation> _deleteAgentOperations(
  Iterable<WorkspaceResource> resources,
  String agentId,
  Map<String, int> revisions,
) {
  final associations = _agentAssociations(resources, agentId);
  _recordAgentRevisions(revisions, resources);

  return [
    ..._deleteAgentAssociations(associations),
    WorkspacePatchOperation(
      operation: .delete,
      resourceKind: .agent,
      resourceId: agentId,
      fieldMask: const [],
      expectedRevision: revisions[agentId],
    ),
  ];
}

Future<List<WorkspaceResource>> _readCloudAgentResources(
  CloudWorkspaceResourceStore store,
) async {
  final response = await store.read(
    pages: [
      WorkspaceResourcePageRequest(resourceKind: .agent, limit: 100),
      WorkspaceResourcePageRequest(resourceKind: .agentAssociation, limit: 100),
    ],
  );

  return response.pages.expand((page) => page.resources).toList();
}
