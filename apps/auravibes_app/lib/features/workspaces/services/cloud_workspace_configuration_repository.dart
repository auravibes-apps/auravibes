import 'package:auravibes_app/features/workspaces/models/workspace_configuration_archive.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

const _resourceBatchSize = 50;

typedef CloudWorkspaceConfigurationCalls = ({
  Future<List<ModelConnectionView>> Function() listConnections,
  Future<List<WorkspaceModelSelectionView>> Function() listModelSelections,
  Future<List<SkillResourceView>> Function(String skillId) listSkillResources,
  Future<void> Function(WorkspaceConfigurationEntry entry) createConnection,
  Future<void> Function(WorkspaceConfigurationEntry entry) createSkillResource,
  Future<void> Function(WorkspaceConfigurationEntry entry, int expectedRevision)
  updateSkillResource,
  Future<void> Function(String selectionId, String policy)
  updateToolSamplingPolicy,
});

typedef _CloudExportRows = ({
  List<WorkspaceResource> skills,
  List<WorkspaceResource> nativeTools,
  Set<String> nativeToolIds,
  Map<String, WorkspaceResource> permissions,
});

typedef _CloudImportPlan = ({
  List<WorkspaceConfigurationEntry> entries,
  List<WorkspaceResource> active,
  Map<String, String> appSkillIds,
  Set<String> existingConnectionIds,
  Map<String, SkillResourceView> skillResourcesById,
});

typedef _CloudResourceCreate = ({
  WorkspaceResourceKind kind,
  String id,
  Map<String, Object?> data,
});

typedef _CloudExportRequest = ({
  CloudWorkspaceResourceStore store,
  String workspaceName,
  CloudWorkspaceConfigurationCalls calls,
  List<WorkspaceResourceKind> resourceKinds,
  Set<WorkspaceConfigurationKind> selectedKinds,
});

typedef _CloudResourceUpsertRequest = ({
  CloudWorkspaceResourceStore store,
  WorkspaceResourceKind kind,
  String id,
  WorkspaceResource? existing,
  Map<String, Object?> data,
});

typedef _CloudSkillSettingRequest = ({
  CloudWorkspaceResourceStore store,
  WorkspaceConfigurationEntry entry,
  List<WorkspaceResource> active,
  Map<String, String> appSkillIds,
});

typedef _CloudImportRequest = ({
  CloudWorkspaceResourceStore store,
  List<WorkspaceResourceKind> resourceKinds,
  CloudWorkspaceConfigurationCalls calls,
  WorkspaceConfigurationArchive archive,
});

typedef _CloudModelViews = ({
  List<ModelConnectionView> connections,
  List<WorkspaceModelSelectionView> selections,
});

typedef _CloudRelationshipRequest = ({
  WorkspaceConfigurationArchive archive,
  List<WorkspaceResource> active,
  List<WorkspaceModelSelectionView> selections,
  Map<String, String> appSkillIds,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
});

typedef _CloudExternalImportState = ({
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
  Map<String, String> appSkillIds,
  List<SkillResourceView> skillResources,
});

typedef _CloudImportFinalization = ({
  WorkspaceConfigurationArchive archive,
  List<WorkspaceResource> active,
  _CloudModelViews modelViews,
  _CloudExternalImportState externalState,
});

typedef _CloudSkillIdentity = ({String source, String slug});
typedef _CloudConnectionIdentity = ({
  String providerId,
  String name,
  String? url,
});

class CloudWorkspaceConfigurationRepository {
  static const List<WorkspaceResourceKind> _kinds = [
    .agent,
    .agentAssociation,
    .skill,
    .skillSetting,
    .tool,
    .toolPermission,
    .compactionSetting,
  ];

  new({
    required CloudWorkspaceResourceStore store,
    required this.workspaceName,
    CloudWorkspaceConfigurationCalls? calls,
  }) : _store = store,
       _calls = calls ?? _productionCalls(store);

  final String workspaceName;
  final CloudWorkspaceResourceStore _store;
  final CloudWorkspaceConfigurationCalls _calls;

  Future<WorkspaceConfigurationArchive> export({
    Set<WorkspaceConfigurationKind> selectedKinds =
        WorkspaceConfigurationKind.all,
  }) => _exportWorkspaceConfigurationArchive((
    store: _store,
    workspaceName: workspaceName,
    calls: _calls,
    resourceKinds: _kinds,
    selectedKinds: selectedKinds,
  ));

  Future<void> importJson(String json) async {
    final archive = _cloudArchive(json);
    final plan = await _importPlan((
      store: _store,
      resourceKinds: _kinds,
      calls: _calls,
      archive: archive,
    ));
    await _applyArchive(plan);
  }

  Future<void> _applyArchive(_CloudImportPlan plan) async {
    final entries = plan.entries;
    final active = plan.active;
    final appSkillIds = plan.appSkillIds;
    await _upsertBaseResources(entries, active);
    await _upsertAgentAssociations(entries, active, appSkillIds);
    await _upsertSkillSettings(entries, active, appSkillIds);
    await _applyToolPermissions(entries, active);
    await _applyCompaction(entries, active);
    await _applyExternalEntries(_calls, plan);
  }

  Future<void> _upsertBaseResources(
    List<WorkspaceConfigurationEntry> entries,
    List<WorkspaceResource> active,
  ) async {
    final resources = await _upsertBaseWorkspaceResources(
      _store,
      entries,
      active,
    );
    await _createBatches(resources);
  }

  Future<void> _createBatches(List<_CloudResourceCreate> resources) async {
    for (
      var offset = 0;
      offset < resources.length;
      offset += _resourceBatchSize
    ) {
      final end = (offset + _resourceBatchSize).clamp(0, resources.length);
      await _store.createAll(resources.sublist(offset, end));
    }
  }

  Future<void> _applyToolPermissions(
    List<WorkspaceConfigurationEntry> entries,
    List<WorkspaceResource> active,
  ) async {
    for (final entry in entries.where((entry) => entry.kind == .tool)) {
      await _upsertToolPermission(_store, entry, active, entry.id);
    }
  }

  Future<void> _upsertAgentAssociations(
    List<WorkspaceConfigurationEntry> entries,
    List<WorkspaceResource> active,
    Map<String, String> appSkillIds,
  ) => _upsertAgentAssociationResources(_store, entries, active, appSkillIds);

  Future<void> _upsertSkillSettings(
    List<WorkspaceConfigurationEntry> entries,
    List<WorkspaceResource> active,
    Map<String, String> appSkillIds,
  ) => _upsertSkillSettingResources(_store, entries, active, appSkillIds);

  Future<void> _applyCompaction(
    List<WorkspaceConfigurationEntry> entries,
    List<WorkspaceResource> active,
  ) async {
    final entry = _entryOfKind(entries, .compactionSetting);
    if (entry == null) return;
    await _saveCompactionSetting(
      _store,
      _resourceOfKind(active, .compactionSetting),
      entry.data,
    );
  }
}

Future<WorkspaceConfigurationArchive> _exportWorkspaceConfigurationArchive(
  _CloudExportRequest request,
) async {
  if (request.selectedKinds.isEmpty) {
    return WorkspaceConfigurationArchive(
      workspaceName: request.workspaceName,
      entries: const [],
    );
  }
  final entries = await _cloudConfigurationEntries(request);

  return WorkspaceConfigurationArchiveCodec.selectKinds(
    .new(workspaceName: request.workspaceName, entries: entries),
    request.selectedKinds,
  );
}

Future<List<WorkspaceConfigurationEntry>> _cloudConfigurationEntries(
  _CloudExportRequest request,
) async {
  final resources = await request.store
      .watchResources(request.resourceKinds)
      .first;
  final active = _activeResources(resources);
  final rows = _cloudExportRows(active);
  final entries = _resourceEntries(active, rows);
  await _appendExternalEntries(
    request.calls,
    entries,
    rows.skills,
    request.selectedKinds,
  );

  return entries;
}

Future<List<_CloudResourceCreate>> _upsertBaseWorkspaceResources(
  CloudWorkspaceResourceStore store,
  List<WorkspaceConfigurationEntry> entries,
  List<WorkspaceResource> active,
) async {
  final resources = <_CloudResourceCreate>[
    ..._baseSkillResources(entries),
    ..._baseToolResources(entries),
    ..._baseAgentResources(entries),
  ];
  final creates = <_CloudResourceCreate>[];
  for (final resource in resources) {
    await _upsertBaseWorkspaceResource(store, resource, active, creates);
  }

  return creates;
}

Future<void> _upsertBaseWorkspaceResource(
  CloudWorkspaceResourceStore store,
  _CloudResourceCreate resource,
  List<WorkspaceResource> active,
  List<_CloudResourceCreate> creates,
) async {
  final existing = _resourceById(active, resource.kind, resource.id);
  if (existing == null) {
    creates.add(resource);

    return;
  }
  if (_resourceDataMatches(existing, resource.data)) return;
  await _updateBaseWorkspaceResource(store, resource, existing);
}

Future<void> _updateBaseWorkspaceResource(
  CloudWorkspaceResourceStore store,
  _CloudResourceCreate resource,
  WorkspaceResource existing,
) => store.update(
  kind: resource.kind,
  id: resource.id,
  revision: existing.revision,
  data: _mergeResourceData(existing, resource.data),
);

Future<void> _upsertAgentAssociationResources(
  CloudWorkspaceResourceStore store,
  List<WorkspaceConfigurationEntry> entries,
  List<WorkspaceResource> active,
  Map<String, String> appSkillIds,
) async {
  for (final entry in entries.where(
    (item) => item.kind == .agentSkill || item.kind == .agentToolPermission,
  )) {
    await _upsertAgentAssociationResource(store, entry, active, appSkillIds);
  }
}

Future<void> _upsertAgentAssociationResource(
  CloudWorkspaceResourceStore store,
  WorkspaceConfigurationEntry entry,
  List<WorkspaceResource> active,
  Map<String, String> appSkillIds,
) {
  if (entry.kind == .agentSkill) {
    return _createAgentSkillAssociation(store, entry, active, appSkillIds);
  }

  return _upsertAgentToolPermissionResource(store, entry, active);
}

Future<void> _createAgentSkillAssociation(
  CloudWorkspaceResourceStore store,
  WorkspaceConfigurationEntry entry,
  List<WorkspaceResource> active,
  Map<String, String> appSkillIds,
) async {
  final existing = _resourceById(active, .agentAssociation, entry.id);
  if (existing != null) return;
  await store.create(
    kind: .agentAssociation,
    id: entry.id,
    data: _agentSkillData(entry, appSkillIds),
  );
}

Future<void> _upsertAgentToolPermissionResource(
  CloudWorkspaceResourceStore store,
  WorkspaceConfigurationEntry entry,
  List<WorkspaceResource> active,
) async {
  final existing = _resourceById(active, .agentAssociation, entry.id);
  await _upsertCloudResource((
    store: store,
    kind: .agentAssociation,
    id: entry.id,
    existing: existing,
    data: _agentToolPermissionData(entry),
  ));
}

Future<void> _upsertSkillSettingResources(
  CloudWorkspaceResourceStore store,
  List<WorkspaceConfigurationEntry> entries,
  List<WorkspaceResource> active,
  Map<String, String> appSkillIds,
) async {
  for (final entry in entries.where((item) => item.kind == .skillSetting)) {
    await _upsertSkillSettingResource((
      store: store,
      entry: entry,
      active: active,
      appSkillIds: appSkillIds,
    ));
  }
}

Future<void> _upsertSkillSettingResource(_CloudSkillSettingRequest request) =>
    _upsertCloudResource(_skillSettingUpsertRequest(request));

_CloudResourceUpsertRequest _skillSettingUpsertRequest(
  _CloudSkillSettingRequest request,
) {
  final entry = request.entry;
  final resolution = _resolveSkillSettingResource(request, entry);

  return (
    store: request.store,
    kind: .skillSetting,
    id: resolution.id,
    existing: resolution.existing,
    data: _skillSettingData(entry, request.appSkillIds, resolution.id),
  );
}

({String id, WorkspaceResource? existing}) _resolveSkillSettingResource(
  _CloudSkillSettingRequest request,
  WorkspaceConfigurationEntry entry,
) {
  final mapped = _resourceById(request.active, .skillSetting, entry.id);
  final id = mapped?.resourceId ?? _settingId(entry, request.appSkillIds);
  final existing = mapped ?? _resourceById(request.active, .skillSetting, id);

  return (id: id, existing: existing);
}

Future<void> _upsertCloudResource(_CloudResourceUpsertRequest request) async {
  final existing = request.existing;
  if (existing == null) {
    await _createCloudResource(request);

    return;
  }
  if (_resourceDataMatches(existing, request.data)) return;
  await _updateCloudResource(request, existing);
}

Future<void> _createCloudResource(_CloudResourceUpsertRequest request) =>
    request.store.create(
      kind: request.kind,
      id: request.id,
      data: request.data,
    );

Future<void> _updateCloudResource(
  _CloudResourceUpsertRequest request,
  WorkspaceResource existing,
) => request.store.update(
  kind: request.kind,
  id: request.id,
  revision: existing.revision,
  data: _mergeResourceData(existing, request.data),
);

CloudWorkspaceConfigurationCalls _productionCalls(
  CloudWorkspaceResourceStore store,
) => _ProductionWorkspaceConfigurationCalls(store).toRecord();

class _ProductionWorkspaceConfigurationCalls(
  final CloudWorkspaceResourceStore _store,
) {
  CloudWorkspaceConfigurationCalls toRecord() => (
    listConnections: listConnections,
    listModelSelections: listModelSelections,
    listSkillResources: listSkillResources,
    createConnection: createConnection,
    createSkillResource: createSkillResource,
    updateSkillResource: updateSkillResource,
    updateToolSamplingPolicy: updateToolSamplingPolicy,
  );

  Future<List<ModelConnectionView>> listConnections() =>
      _listModelConnections(_store);

  Future<List<WorkspaceModelSelectionView>> listModelSelections() =>
      _listModelSelections(_store);

  Future<List<SkillResourceView>> listSkillResources(String skillId) =>
      _listSkillResources(_store, skillId);

  Future<void> createConnection(WorkspaceConfigurationEntry entry) =>
      _createModelConnection(_store, entry);

  Future<void> createSkillResource(WorkspaceConfigurationEntry entry) =>
      _createSkillResource(_store, entry);

  Future<void> updateSkillResource(
    WorkspaceConfigurationEntry entry,
    int expectedRevision,
  ) => _updateSkillResource(_store, entry, expectedRevision);

  Future<void> updateToolSamplingPolicy(String selectionId, String policy) =>
      _updateToolSamplingPolicy(_store, selectionId, policy);
}

Future<List<ModelConnectionView>> _listModelConnections(
  CloudWorkspaceResourceStore store,
) async {
  final api = await _api(store);

  return await api.client.modelConnection.list(
    .new(workspaceId: api.workspaceId),
  );
}

Future<List<SkillResourceView>> _listSkillResources(
  CloudWorkspaceResourceStore store,
  String skillId,
) async {
  final api = await _api(store);

  return await api.client.skillResource.list(
    .new(workspaceId: api.workspaceId, skillId: skillId),
  );
}

Future<List<WorkspaceModelSelectionView>> _listModelSelections(
  CloudWorkspaceResourceStore store,
) async {
  final api = await _api(store);

  return await api.client.modelConnection.listSelections(
    .new(workspaceId: api.workspaceId),
  );
}

Future<void> _createModelConnection(
  CloudWorkspaceResourceStore store,
  WorkspaceConfigurationEntry entry,
) async {
  final api = await _api(store);
  final _ = await api.client.modelConnection.create(
    _modelConnectionRequest(api, entry),
  );
}

CreateModelConnectionRequest _modelConnectionRequest(
  ({Client client, int workspaceId}) api,
  WorkspaceConfigurationEntry entry,
) {
  final data = entry.data;

  return .new(
    workspaceId: api.workspaceId,
    requestId: const UuidV7().generate(),
    connectionId: entry.id,
    name: _string(data, 'name'),
    providerId: _string(data, 'providerId'),
    url: data['url'] as String?,
  );
}

Future<void> _createSkillResource(
  CloudWorkspaceResourceStore store,
  WorkspaceConfigurationEntry entry,
) async {
  final api = await _api(store);
  final _ = await api.client.skillResource.create(
    _skillResourceRequest(api, entry),
  );
}

Future<void> _updateSkillResource(
  CloudWorkspaceResourceStore store,
  WorkspaceConfigurationEntry entry,
  int expectedRevision,
) async {
  final api = await _api(store);
  final _ = await api.client.skillResource.update(
    _skillResourceUpdateRequest(api, entry, expectedRevision),
  );
}

UpdateSkillResourceRequest _skillResourceUpdateRequest(
  ({Client client, int workspaceId}) api,
  WorkspaceConfigurationEntry entry,
  int expectedRevision,
) => .new(
  workspaceId: api.workspaceId,
  requestId: const UuidV7().generate(),
  resourceId: entry.id,
  expectedRevision: expectedRevision,
  title: _string(entry.data, 'title'),
  description: _string(entry.data, 'description'),
  content: _string(entry.data, 'content'),
);

Future<void> _updateToolSamplingPolicy(
  CloudWorkspaceResourceStore store,
  String selectionId,
  String policy,
) async {
  final api = await _api(store);
  await api.client.modelConnection.updateToolSamplingPolicy(
    .new(
      workspaceId: api.workspaceId,
      requestId: const UuidV7().generate(),
      selectionId: selectionId,
      toolSamplingPolicy: policy,
    ),
  );
}

CreateSkillResourceRequest _skillResourceRequest(
  ({Client client, int workspaceId}) api,
  WorkspaceConfigurationEntry entry,
) {
  final data = entry.data;

  return .new(
    workspaceId: api.workspaceId,
    requestId: const UuidV7().generate(),
    resourceId: entry.id,
    skillId: _string(data, 'skillId'),
    title: _string(data, 'title'),
    description: _string(data, 'description'),
    content: _string(data, 'content'),
  );
}

Future<({Client client, int workspaceId})> _api(
  CloudWorkspaceResourceStore store,
) async {
  final client = await store.client;
  final workspaceId = await store.cloudWorkspaceId;
  if (client == null || workspaceId == null) {
    throw const WorkspaceConfigurationArchiveException(
      'workspace_archive.invalid_target',
    );
  }

  return (client: client, workspaceId: workspaceId);
}

WorkspaceConfigurationEntry _agentEntry(WorkspaceResource resource) {
  final data = CloudResourceMapper.decode(resource);

  return WorkspaceConfigurationEntry(
    kind: .agent,
    id: resource.resourceId,
    data: {
      'name': _string(data, 'name'),
      'description': data['description'] as String? ?? '',
      'content': _string(data, 'content'),
      'isEnabled': data['isEnabled'] ?? true,
      'visibility': data['visibility'],
    },
  );
}

WorkspaceConfigurationEntry _skillEntry(WorkspaceResource resource) {
  final data = CloudResourceMapper.decode(resource);

  return WorkspaceConfigurationEntry(
    kind: .skill,
    id: resource.resourceId,
    data: {
      'source': data['source'] ?? 'user',
      'kind': data['kind'],
      'title': data['title'],
      'slug': data['slug'],
      'description': data['description'],
      'content': data['content'],
      'isEnabled': data['isEnabled'],
    },
  );
}

WorkspaceConfigurationEntry _toolEntry(
  WorkspaceResource resource,
  WorkspaceResource? permission,
) {
  final data = CloudResourceMapper.decode(resource);
  final override = permission == null
      ? <String, dynamic>{}
      : CloudResourceMapper.decode(permission);

  return WorkspaceConfigurationEntry(
    kind: .tool,
    id: resource.resourceId,
    data: {
      'toolId': data['toolId'],
      'isEnabled': override['isEnabled'] ?? data['isEnabled'],
      'permissionMode': override['permissionMode'] ?? data['permissionMode'],
    },
  );
}

WorkspaceConfigurationEntry _associationEntry(WorkspaceResource resource) {
  final data = CloudResourceMapper.decode(resource);
  final skillId = data['skillId'];
  if (skillId is String) {
    return WorkspaceConfigurationEntry(
      kind: .agentSkill,
      id: resource.resourceId,
      data: {
        'agentId': data['agentId'],
        'skillId': data['appSkillIdentifier'] ?? skillId,
        'source': data['appSkillIdentifier'] == null ? 'user' : 'app',
      },
    );
  }

  return WorkspaceConfigurationEntry(
    kind: .agentToolPermission,
    id: resource.resourceId,
    data: {
      'agentId': data['agentId'],
      'toolId': data['toolId'],
      'permissionMode': data['permissionMode'],
    },
  );
}

WorkspaceConfigurationEntry? _skillSettingEntry(
  WorkspaceResource resource,
  List<WorkspaceResource> skills,
) {
  final data = CloudResourceMapper.decode(resource);
  final skill = skills
      .where((item) => item.resourceId == data['skillId'])
      .firstOrNull;
  if (skill == null) return null;

  return _mappedSkillSettingEntry(resource, skill);
}

WorkspaceConfigurationEntry _mappedSkillSettingEntry(
  WorkspaceResource resource,
  WorkspaceResource skill,
) {
  final data = CloudResourceMapper.decode(resource);
  final skillData = CloudResourceMapper.decode(skill);
  final isAppSkill = skillData['source'] == 'app';

  return WorkspaceConfigurationEntry(
    kind: .skillSetting,
    id: resource.resourceId,
    data: {
      'skillId': isAppSkill ? skillData['slug'] : data['skillId'],
      'source': isAppSkill ? 'app' : 'user',
      'isEnabled': data['isEnabled'],
    },
  );
}

WorkspaceConfigurationEntry _compactionEntry(List<WorkspaceResource> active) =>
    WorkspaceConfigurationEntry(
      kind: .compactionSetting,
      id: 'workspace',
      data: _compactionData(active),
    );

Map<String, Object?> _compactionData(List<WorkspaceResource> active) {
  final resource = active
      .where((item) => item.resourceKind == .compactionSetting)
      .firstOrNull;
  final data = resource == null
      ? <String, dynamic>{}
      : CloudResourceMapper.decode(resource);

  return {
    'autoCompactionEnabled': data['autoCompactionEnabled'] ?? true,
    'usagePercentageThreshold': data['usagePercentageThreshold'] ?? 80,
    'remainingTokenThreshold': data['remainingTokenThreshold'] ?? 2000,
  };
}

WorkspaceConfigurationEntry _skillResourceEntry(SkillResourceView resource) =>
    WorkspaceConfigurationEntry(
      kind: .skillResource,
      id: resource.id,
      data: {
        'skillId': resource.skillId,
        'title': resource.title,
        'slug': resource.slug,
        'description': resource.description,
        'content': resource.content,
      },
    );

WorkspaceConfigurationEntry _modelConnectionEntry(ModelConnectionView view) =>
    WorkspaceConfigurationEntry(
      kind: .modelConnection,
      id: view.id,
      data: {
        'name': view.name,
        'providerId': view.providerId,
        'url': WorkspaceConfigurationArchiveCodec.publicUrl(view.url),
      },
    );

Map<String, String> _nativeToolIdsByName(List<WorkspaceResource> resources) => {
  for (final resource in resources.where(_isNativeTool))
    _string(CloudResourceMapper.decode(resource), 'toolId'):
        resource.resourceId,
};

Map<String, String> _existingAppSkillIds(List<WorkspaceResource> resources) => {
  for (final resource in resources.where((item) => item.resourceKind == .skill))
    if (_isAppSkill(resource))
      _string(CloudResourceMapper.decode(resource), 'slug'):
          resource.resourceId,
};

bool _isAppSkill(WorkspaceResource resource) =>
    CloudResourceMapper.decode(resource)['source'] == 'app';

void _validateAppReferences(
  List<WorkspaceConfigurationEntry> entries,
  Map<String, String> appSkillIds,
) {
  for (final entry in entries.where(
    (item) =>
        (item.kind == .skillSetting || item.kind == .agentSkill) &&
        item.data['source'] == 'app',
  )) {
    if (!appSkillIds.containsKey(_string(entry.data, 'skillId'))) {
      throw const WorkspaceConfigurationArchiveException(
        'workspace_archive.unsupported_configuration',
      );
    }
  }
}

void _validateCloudEntries(List<WorkspaceConfigurationEntry> entries) {
  for (final entry in entries.where((entry) => entry.kind == .agent)) {
    if (_string(entry.data, 'name').trim().isEmpty) {
      throw const WorkspaceConfigurationArchiveException(
        'workspace_archive.unsupported_configuration',
      );
    }
  }
}

String _string(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is! String) {
    throw const WorkspaceConfigurationArchiveException(
      'workspace_archive.invalid',
    );
  }

  return value;
}

String _settingId(
  WorkspaceConfigurationEntry entry,
  Map<String, String> appSkillIds,
) => entry.data['source'] == 'app'
    ? appSkillIds[_string(entry.data, 'skillId')]!
    : entry.id;

bool _isSupportedAssociation(
  WorkspaceResource resource,
  Set<String> nativeToolIds,
) {
  final data = CloudResourceMapper.decode(resource);
  if (data['toolId'] == null) return true;

  return nativeToolIds.contains(_string(data, 'toolId'));
}

WorkspaceConfigurationArchive _cloudArchive(String json) {
  final archive = WorkspaceConfigurationArchiveCodec.decode(json);
  WorkspaceConfigurationArchiveCodec.validateNaturalIdentities(archive);
  _validateCloudEntries(archive.entries);

  return archive;
}

Future<_CloudImportPlan> _importPlan(_CloudImportRequest request) async {
  final active = await _activeImportResources(request);

  return await _resolveCloudImportPlan(request, active);
}

Future<List<WorkspaceResource>> _activeImportResources(
  _CloudImportRequest request,
) async => _activeResources(
  await request.store.watchResources(request.resourceKinds).first,
);

Future<_CloudImportPlan> _resolveCloudImportPlan(
  _CloudImportRequest request,
  List<WorkspaceResource> active,
) async {
  final archive = request.archive;
  final calls = request.calls;
  final modelViews = await _existingCloudModelViews(calls, archive);
  final externalState = await _existingCloudImportState((
    archive: archive,
    active: active,
    calls: calls,
    modelViews: modelViews,
  ));

  return _finishCloudImportPlan((
    archive: archive,
    active: active,
    modelViews: modelViews,
    externalState: externalState,
  ));
}

Future<_CloudModelViews> _existingCloudModelViews(
  CloudWorkspaceConfigurationCalls calls,
  WorkspaceConfigurationArchive archive,
) async {
  final entries = archive.entries;
  final hasConnections = _containsModelConnection(entries);
  final hasSelections = _containsModelSelection(entries);

  return (
    connections: hasConnections
        ? await calls.listConnections()
        : <ModelConnectionView>[],
    selections: hasSelections
        ? await calls.listModelSelections()
        : <WorkspaceModelSelectionView>[],
  );
}

bool _containsModelConnection(List<WorkspaceConfigurationEntry> entries) =>
    entries.any(
      (entry) =>
          entry.kind == .modelConnection || entry.kind == .modelSelection,
    );

bool _containsModelSelection(List<WorkspaceConfigurationEntry> entries) =>
    entries.any((entry) => entry.kind == .modelSelection);

Future<_CloudExternalImportState> _existingCloudImportState(
  ({
    WorkspaceConfigurationArchive archive,
    List<WorkspaceResource> active,
    CloudWorkspaceConfigurationCalls calls,
    _CloudModelViews modelViews,
  })
  request,
) async {
  final definitions = _existingCloudDefinitions(request);
  final skillResources = await _existingCloudSkillResources(
    request,
    definitions.ids,
  );

  return (
    ids: definitions.ids,
    appSkillIds: definitions.appSkillIds,
    skillResources: skillResources,
  );
}

typedef _CloudExistingDefinitions = ({
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
  Map<String, String> appSkillIds,
});

_CloudExistingDefinitions _existingCloudDefinitions(
  ({
    WorkspaceConfigurationArchive archive,
    List<WorkspaceResource> active,
    CloudWorkspaceConfigurationCalls calls,
    _CloudModelViews modelViews,
  })
  request,
) {
  final archive = request.archive;
  final active = request.active;
  final modelViews = request.modelViews;
  final ids = _existingDefinitionIds(archive, active, modelViews.connections);
  final appSkillIds = _existingAppSkillIds(active);
  _mapExistingRelationships((
    archive: archive,
    active: active,
    selections: modelViews.selections,
    appSkillIds: appSkillIds,
    ids: ids,
  ));

  return (ids: ids, appSkillIds: appSkillIds);
}

Future<List<SkillResourceView>> _existingCloudSkillResources(
  ({
    WorkspaceConfigurationArchive archive,
    List<WorkspaceResource> active,
    CloudWorkspaceConfigurationCalls calls,
    _CloudModelViews modelViews,
  })
  request,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) async {
  final archive = request.archive;
  final resources = await _existingSkillResources(request.calls, archive, ids);
  _mapExistingSkillResources(archive, ids, resources);

  return resources;
}

_CloudImportPlan _finishCloudImportPlan(_CloudImportFinalization request) {
  final external = request.externalState;
  final remapped = WorkspaceConfigurationArchiveCodec.remapIds(
    request.archive,
    idMapping: external.ids,
  );
  final appSkillIds = _resolvedAppSkillIds(
    external.appSkillIds,
    remapped.entries,
  );
  _validateCloudEntries(remapped.entries);
  _validateAppReferences(remapped.entries, appSkillIds);

  return _finalizedCloudImportPlan(request, remapped.entries, appSkillIds);
}

_CloudImportPlan _finalizedCloudImportPlan(
  _CloudImportFinalization request,
  List<WorkspaceConfigurationEntry> entries,
  Map<String, String> appSkillIds,
) => (
  active: request.active,
  entries: entries,
  appSkillIds: appSkillIds,
  existingConnectionIds: {
    for (final item in request.modelViews.connections) item.id,
  },
  skillResourcesById: {
    for (final item in request.externalState.skillResources) item.id: item,
  },
);

Map<String, String> _resolvedAppSkillIds(
  Map<String, String> existing,
  List<WorkspaceConfigurationEntry> entries,
) => {
  ...existing,
  for (final entry in entries.where(
    (item) => item.kind == .skill && item.data['source'] == 'app',
  ))
    _string(entry.data, 'slug'): entry.id,
};

Map<WorkspaceConfigurationArchiveEntryId, String> _existingDefinitionIds(
  WorkspaceConfigurationArchive archive,
  List<WorkspaceResource> active,
  List<ModelConnectionView> connections,
) {
  final ids = <WorkspaceConfigurationArchiveEntryId, String>{};
  _mapAgentDefinitionIds(archive, active, ids);
  _mapSkillDefinitionIds(archive, active, ids);
  _mapToolDefinitionIds(archive, active, ids);
  _mapModelConnectionDefinitionIds(archive, connections, ids);

  return ids;
}

void _mapAgentDefinitionIds(
  WorkspaceConfigurationArchive archive,
  List<WorkspaceResource> active,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final existingByName = _existingAgentIdsByName(active);
  for (final entry in archive.entries.where((item) => item.kind == .agent)) {
    final existingId = existingByName[_string(entry.data, 'name').trim()];
    if (existingId != null) ids[(kind: entry.kind, id: entry.id)] = existingId;
  }
}

Map<String, String> _existingAgentIdsByName(List<WorkspaceResource> active) {
  final ids = <String, String>{};
  for (final resource in active) {
    if (resource.resourceKind != .agent) continue;
    final name = _string(CloudResourceMapper.decode(resource), 'name').trim();
    final _ = ids.putIfAbsent(name, () => resource.resourceId);
  }

  return ids;
}

void _mapSkillDefinitionIds(
  WorkspaceConfigurationArchive archive,
  List<WorkspaceResource> active,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final existingByIdentity = _existingSkillIdsByIdentity(active);
  for (final entry in archive.entries) {
    if (entry.kind != .skill) continue;
    final identity = _cloudSkillIdentity(entry.data);
    final existingId = existingByIdentity[identity];
    if (existingId != null) ids[(kind: entry.kind, id: entry.id)] = existingId;
  }
}

_CloudSkillIdentity _cloudSkillIdentity(Map<String, Object?> data) =>
    (source: _string(data, 'source'), slug: _string(data, 'slug'));

Map<_CloudSkillIdentity, String> _existingSkillIdsByIdentity(
  List<WorkspaceResource> active,
) {
  final ids = <_CloudSkillIdentity, String>{};
  for (final resource in active.where((item) => item.resourceKind == .skill)) {
    final identity = _cloudSkillIdentity(CloudResourceMapper.decode(resource));
    final _ = ids.putIfAbsent(identity, () => resource.resourceId);
  }

  return ids;
}

void _mapToolDefinitionIds(
  WorkspaceConfigurationArchive archive,
  List<WorkspaceResource> active,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final existingByToolId = _nativeToolIdsByName(active);
  for (final entry in archive.entries.where((item) => item.kind == .tool)) {
    final existingId = existingByToolId[_string(entry.data, 'toolId')];
    if (existingId != null) ids[(kind: entry.kind, id: entry.id)] = existingId;
  }
}

void _mapModelConnectionDefinitionIds(
  WorkspaceConfigurationArchive archive,
  List<ModelConnectionView> connections,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final existingByIdentity = _existingModelConnectionIdsByIdentity(connections);
  for (final entry in archive.entries) {
    if (entry.kind != .modelConnection) continue;
    final identity = _cloudConnectionIdentity(entry);
    final existingId = existingByIdentity[identity];
    if (existingId != null) ids[(kind: entry.kind, id: entry.id)] = existingId;
  }
}

_CloudConnectionIdentity _cloudConnectionIdentity(
  WorkspaceConfigurationEntry entry,
) {
  final data = entry.data;

  return (
    providerId: _string(data, 'providerId'),
    name: _string(data, 'name'),
    url: data['url'] as String?,
  );
}

Map<_CloudConnectionIdentity, String> _existingModelConnectionIdsByIdentity(
  List<ModelConnectionView> connections,
) {
  final ids = <_CloudConnectionIdentity, String>{};
  for (final connection in connections) {
    final identity = (
      providerId: connection.providerId,
      name: connection.name,
      url: WorkspaceConfigurationArchiveCodec.publicUrl(connection.url),
    );
    final _ = ids.putIfAbsent(identity, () => connection.id);
  }

  return ids;
}

void _mapExistingRelationships(_CloudRelationshipRequest request) {
  _mapExistingAgentSkills(request);
  _mapExistingAgentToolPermissions(request);
  _mapExistingSkillSettings(request);
  _mapExistingModelSelections(request);
}

void _mapExistingAgentSkills(_CloudRelationshipRequest request) {
  for (final entry in request.archive.entries.where(
    (item) => item.kind == .agentSkill,
  )) {
    _mapExistingAgentSkill(request, entry);
  }
}

void _mapExistingAgentSkill(
  _CloudRelationshipRequest request,
  WorkspaceConfigurationEntry entry,
) {
  final target = _cloudAgentSkillTarget(entry, request);
  if (target == null) return;
  final existing = _existingAgentSkillAssociation(request.active, target);
  if (existing != null) {
    request.ids[(kind: entry.kind, id: entry.id)] = existing.resourceId;
  }
}

({String agentId, String skillId, bool isAppSkill, String identifier})?
_cloudAgentSkillTarget(
  WorkspaceConfigurationEntry entry,
  _CloudRelationshipRequest request,
) {
  final identity = _cloudAgentSkillIdentity(entry);
  final agentId = _cloudTargetAgentId(identity, request.ids);
  if (agentId == null) return null;
  final skillId = _cloudTargetSkillId(request, identity);
  if (skillId == null) return null;

  return _cloudAgentSkillTargetRecord(
    agentId: agentId,
    skillId: skillId,
    identity: identity,
  );
}

String? _cloudTargetAgentId(
  _CloudAgentSkillIdentity identity,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) => _mappedArchiveId(ids, .agent, identity.sourceAgentId);

({String agentId, String skillId, bool isAppSkill, String identifier})
_cloudAgentSkillTargetRecord({
  required String agentId,
  required String skillId,
  required _CloudAgentSkillIdentity identity,
}) => (
  agentId: agentId,
  skillId: skillId,
  isAppSkill: identity.source == 'app',
  identifier: identity.identifier,
);

typedef _CloudAgentSkillIdentity = ({
  Object? sourceAgentId,
  String source,
  String identifier,
});

_CloudAgentSkillIdentity _cloudAgentSkillIdentity(
  WorkspaceConfigurationEntry entry,
) {
  final data = entry.data;

  return (
    sourceAgentId: data['agentId'],
    source: _string(data, 'source'),
    identifier: _string(data, 'skillId'),
  );
}

String? _cloudTargetSkillId(
  _CloudRelationshipRequest request,
  _CloudAgentSkillIdentity identity,
) => identity.source == 'app'
    ? request.appSkillIds[identity.identifier]
    : _mappedArchiveId(request.ids, .skill, identity.identifier);

WorkspaceResource? _existingAgentSkillAssociation(
  List<WorkspaceResource> active,
  ({String agentId, String skillId, bool isAppSkill, String identifier}) target,
) => active
    .where((item) => item.resourceKind == .agentAssociation)
    .where((item) => _matchesAgentSkillAssociation(item, target))
    .firstOrNull;

bool _matchesAgentSkillAssociation(
  WorkspaceResource resource,
  ({String agentId, String skillId, bool isAppSkill, String identifier}) target,
) {
  final data = CloudResourceMapper.decode(resource);

  return data['agentId'] == target.agentId &&
      data['skillId'] == target.skillId &&
      (target.isAppSkill
          ? data['appSkillIdentifier'] == target.identifier
          : data['appSkillIdentifier'] == null);
}

void _mapExistingAgentToolPermissions(_CloudRelationshipRequest request) {
  for (final entry in request.archive.entries.where(
    (item) => item.kind == .agentToolPermission,
  )) {
    _mapExistingAgentToolPermission(request, entry);
  }
}

void _mapExistingAgentToolPermission(
  _CloudRelationshipRequest request,
  WorkspaceConfigurationEntry entry,
) {
  final target = _cloudAgentToolTarget(entry, request.ids);
  if (target == null) return;
  final existing = _existingAgentToolAssociation(request.active, target);
  if (existing != null) {
    request.ids[(kind: entry.kind, id: entry.id)] = existing.resourceId;
  }
}

({String agentId, String toolId})? _cloudAgentToolTarget(
  WorkspaceConfigurationEntry entry,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final agentId = _mappedArchiveId(ids, .agent, entry.data['agentId']);
  final toolId = _mappedArchiveId(ids, .tool, entry.data['toolId']);
  if (agentId == null || toolId == null) return null;

  return (agentId: agentId, toolId: toolId);
}

WorkspaceResource? _existingAgentToolAssociation(
  List<WorkspaceResource> active,
  ({String agentId, String toolId}) target,
) => active
    .where((item) => item.resourceKind == .agentAssociation)
    .where((item) => _matchesAgentToolAssociation(item, target))
    .firstOrNull;

bool _matchesAgentToolAssociation(
  WorkspaceResource resource,
  ({String agentId, String toolId}) target,
) {
  final data = CloudResourceMapper.decode(resource);

  return data['agentId'] == target.agentId && data['toolId'] == target.toolId;
}

void _mapExistingSkillSettings(_CloudRelationshipRequest request) {
  for (final entry in request.archive.entries.where(
    (item) => item.kind == .skillSetting,
  )) {
    _mapExistingSkillSetting(request, entry);
  }
}

void _mapExistingSkillSetting(
  _CloudRelationshipRequest request,
  WorkspaceConfigurationEntry entry,
) {
  final skillId = _cloudSkillSettingTarget(entry, request);
  if (skillId == null) return;
  final existing = _existingSkillSetting(request.active, skillId);
  if (existing != null) {
    request.ids[(kind: entry.kind, id: entry.id)] = existing.resourceId;
  }
}

String? _cloudSkillSettingTarget(
  WorkspaceConfigurationEntry entry,
  _CloudRelationshipRequest request,
) {
  if (entry.data['source'] == 'app') {
    return request.appSkillIds[_string(entry.data, 'skillId')];
  }

  return _mappedArchiveId(request.ids, .skill, entry.data['skillId']);
}

WorkspaceResource? _existingSkillSetting(
  List<WorkspaceResource> active,
  String skillId,
) => active
    .where((item) => item.resourceKind == .skillSetting)
    .where((item) => CloudResourceMapper.decode(item)['skillId'] == skillId)
    .firstOrNull;

void _mapExistingModelSelections(_CloudRelationshipRequest request) {
  for (final entry in request.archive.entries.where(
    (item) => item.kind == .modelSelection,
  )) {
    _mapExistingModelSelection(request, entry);
  }
}

void _mapExistingModelSelection(
  _CloudRelationshipRequest request,
  WorkspaceConfigurationEntry entry,
) {
  final target = _cloudModelSelectionTarget(entry, request.ids);
  if (target == null) return;
  final existing = _existingModelSelection(request.selections, target);
  if (existing != null) {
    request.ids[(kind: entry.kind, id: entry.id)] = existing.id;
  }
}

({String connectionId, String modelId})? _cloudModelSelectionTarget(
  WorkspaceConfigurationEntry entry,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final connectionId = _mappedArchiveId(
    ids,
    .modelConnection,
    entry.data['modelConnectionId'],
  );
  if (connectionId == null) return null;

  return (connectionId: connectionId, modelId: _string(entry.data, 'modelId'));
}

WorkspaceModelSelectionView? _existingModelSelection(
  List<WorkspaceModelSelectionView> selections,
  ({String connectionId, String modelId}) target,
) => selections
    .where(
      (item) =>
          item.connectionId == target.connectionId &&
          item.modelId == target.modelId,
    )
    .firstOrNull;

String? _mappedArchiveId(
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
  WorkspaceConfigurationKind kind,
  Object? sourceId,
) => sourceId is String ? ids[(kind: kind, id: sourceId)] : null;

Future<List<SkillResourceView>> _existingSkillResources(
  CloudWorkspaceConfigurationCalls calls,
  WorkspaceConfigurationArchive archive,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) async {
  final skillIds = _skillResourceOwnerIds(archive, ids);
  final resources = <SkillResourceView>[];
  for (final skillId in skillIds) {
    resources.addAll(await calls.listSkillResources(skillId));
  }

  return resources;
}

Set<String> _skillResourceOwnerIds(
  WorkspaceConfigurationArchive archive,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final skillIds = <String>{};
  for (final entry in archive.entries.where(
    (item) => item.kind == .skillResource,
  )) {
    final skillId = _mappedArchiveId(ids, .skill, entry.data['skillId']);
    if (skillId != null) {
      final _ = skillIds.add(skillId);
    }
  }

  return skillIds;
}

void _mapExistingSkillResources(
  WorkspaceConfigurationArchive archive,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
  List<SkillResourceView> resources,
) {
  for (final entry in archive.entries.where(
    (item) => item.kind == .skillResource,
  )) {
    _mapExistingSkillResource(entry, ids, resources);
  }
}

void _mapExistingSkillResource(
  WorkspaceConfigurationEntry entry,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
  List<SkillResourceView> resources,
) {
  final skillId = _mappedArchiveId(ids, .skill, entry.data['skillId']);
  if (skillId == null) return;
  final existing = _existingSkillResourceForSlug(
    resources,
    skillId,
    _string(entry.data, 'slug'),
  );
  if (existing != null) ids[(kind: entry.kind, id: entry.id)] = existing.id;
}

SkillResourceView? _existingSkillResourceForSlug(
  List<SkillResourceView> resources,
  String skillId,
  String slug,
) => resources
    .where((item) => item.skillId == skillId && item.slug == slug)
    .firstOrNull;

List<WorkspaceResource> _activeResources(List<WorkspaceResource> resources) =>
    resources.where((resource) => resource.deletedAt == null).toList();

_CloudExportRows _cloudExportRows(List<WorkspaceResource> active) {
  final skills = _cloudSkills(active);
  final nativeTools = _cloudNativeTools(active);
  final nativeToolIds = nativeTools.map((item) => item.resourceId).toSet();
  final permissions = _nativeToolPermissions(active);

  return (
    skills: skills,
    nativeTools: nativeTools,
    nativeToolIds: nativeToolIds,
    permissions: permissions,
  );
}

List<WorkspaceResource> _cloudSkills(List<WorkspaceResource> active) =>
    active.where((item) => item.resourceKind == .skill).toList();

List<WorkspaceResource> _cloudNativeTools(List<WorkspaceResource> active) =>
    active.where(_isNativeTool).toList();

bool _isNativeTool(WorkspaceResource resource) {
  if (resource.resourceKind != .tool) return false;

  return CloudResourceMapper.decode(resource)['toolGroupId'] == null;
}

Map<String, WorkspaceResource> _nativeToolPermissions(
  List<WorkspaceResource> active,
) => {
  for (final resource in active.where(_isNativeToolPermission))
    _string(CloudResourceMapper.decode(resource), 'toolId'): resource,
};

bool _isNativeToolPermission(WorkspaceResource resource) {
  if (resource.resourceKind != .toolPermission) return false;

  return CloudResourceMapper.decode(resource)['toolGroupId'] == null;
}

List<WorkspaceConfigurationEntry> _resourceEntries(
  List<WorkspaceResource> active,
  _CloudExportRows rows,
) => [
  ..._agentEntries(active),
  ..._skillEntries(rows.skills),
  ..._toolEntries(rows.nativeTools, rows.permissions),
  ..._associationEntries(active, rows.nativeToolIds),
  ..._skillSettingEntries(active, rows.skills),
  _compactionEntry(active),
];

List<WorkspaceConfigurationEntry> _agentEntries(
  List<WorkspaceResource> active,
) => [
  for (final resource in active.where((item) => item.resourceKind == .agent))
    _agentEntry(resource),
];

List<WorkspaceConfigurationEntry> _skillEntries(
  List<WorkspaceResource> skills,
) => [for (final resource in skills) _skillEntry(resource)];

List<WorkspaceConfigurationEntry> _toolEntries(
  List<WorkspaceResource> tools,
  Map<String, WorkspaceResource> permissions,
) => [
  for (final resource in tools)
    _toolEntry(resource, permissions[resource.resourceId]),
];

List<WorkspaceConfigurationEntry> _associationEntries(
  List<WorkspaceResource> active,
  Set<String> nativeToolIds,
) => [
  for (final resource in active.where(
    (item) =>
        item.resourceKind == .agentAssociation &&
        _isSupportedAssociation(item, nativeToolIds),
  ))
    _associationEntry(resource),
];

List<WorkspaceConfigurationEntry> _skillSettingEntries(
  List<WorkspaceResource> active,
  List<WorkspaceResource> skills,
) {
  final entries = <WorkspaceConfigurationEntry>[];
  for (final resource in active.where(
    (item) => item.resourceKind == .skillSetting,
  )) {
    final entry = _skillSettingEntry(resource, skills);
    if (entry != null) entries.add(entry);
  }

  return entries;
}

Future<void> _appendExternalEntries(
  CloudWorkspaceConfigurationCalls calls,
  List<WorkspaceConfigurationEntry> entries,
  List<WorkspaceResource> skills,
  Set<WorkspaceConfigurationKind> selectedKinds,
) async {
  if (selectedKinds.contains(WorkspaceConfigurationKind.modelConnection) ||
      selectedKinds.contains(WorkspaceConfigurationKind.modelSelection)) {
    await _appendModelConnections(calls, entries);
  }
  if (selectedKinds.contains(WorkspaceConfigurationKind.modelSelection)) {
    await _appendModelSelections(calls, entries);
  }
  if (selectedKinds.contains(WorkspaceConfigurationKind.skillResource)) {
    await _appendSkillResources(calls, entries, skills);
  }
}

Future<void> _appendModelConnections(
  CloudWorkspaceConfigurationCalls calls,
  List<WorkspaceConfigurationEntry> entries,
) async {
  final connections = await calls.listConnections();
  entries.addAll(connections.map(_modelConnectionEntry));
}

Future<void> _appendModelSelections(
  CloudWorkspaceConfigurationCalls calls,
  List<WorkspaceConfigurationEntry> entries,
) async {
  final selections = await calls.listModelSelections();
  entries.addAll([
    for (final selection in selections)
      if (selection.toolSamplingPolicy case final String policy)
        WorkspaceConfigurationEntry(
          kind: .modelSelection,
          id: selection.id,
          data: {
            'modelConnectionId': selection.connectionId,
            'modelId': selection.modelId,
            'toolSamplingPolicy': policy,
          },
        ),
  ]);
}

Future<void> _appendSkillResources(
  CloudWorkspaceConfigurationCalls calls,
  List<WorkspaceConfigurationEntry> entries,
  List<WorkspaceResource> skills,
) async {
  for (final skill in skills) {
    final resources = await calls.listSkillResources(skill.resourceId);
    entries.addAll(resources.map(_skillResourceEntry));
  }
}

Future<void> _applyExternalEntries(
  CloudWorkspaceConfigurationCalls calls,
  _CloudImportPlan plan,
) async {
  await _applyExternalConnections(calls, plan);
  await _applyExternalSkillResources(calls, plan);
  await _applyExternalModelSelections(calls, plan);
}

Future<void> _applyExternalConnections(
  CloudWorkspaceConfigurationCalls calls,
  _CloudImportPlan plan,
) async {
  for (final entry in plan.entries.where(
    (item) => item.kind == .modelConnection,
  )) {
    if (plan.existingConnectionIds.contains(entry.id)) continue;
    await calls.createConnection(entry);
  }
}

Future<void> _applyExternalSkillResources(
  CloudWorkspaceConfigurationCalls calls,
  _CloudImportPlan plan,
) async {
  for (final entry in plan.entries.where(
    (item) => item.kind == .skillResource,
  )) {
    final existing = plan.skillResourcesById[entry.id];
    if (existing == null) {
      await calls.createSkillResource(entry);
    } else if (!_skillResourceMatches(existing, entry)) {
      await calls.updateSkillResource(entry, existing.revision);
    }
  }
}

Future<void> _applyExternalModelSelections(
  CloudWorkspaceConfigurationCalls calls,
  _CloudImportPlan plan,
) async {
  final entries = plan.entries.where((item) => item.kind == .modelSelection);
  if (entries.isEmpty) return;
  final selections = await calls.listModelSelections();
  for (final entry in entries) {
    await _applyExternalModelSelection(calls, entry, selections);
  }
}

Future<void> _applyExternalModelSelection(
  CloudWorkspaceConfigurationCalls calls,
  WorkspaceConfigurationEntry entry,
  List<WorkspaceModelSelectionView> selections,
) async {
  final existing = _existingModelSelectionForEntry(entry, selections);
  if (existing == null) {
    throw const WorkspaceConfigurationArchiveException(
      'workspace_archive.unsupported_configuration',
    );
  }
  final policy = _string(entry.data, 'toolSamplingPolicy');
  if (existing.toolSamplingPolicy == policy) return;
  await calls.updateToolSamplingPolicy(existing.id, policy);
}

WorkspaceModelSelectionView? _existingModelSelectionForEntry(
  WorkspaceConfigurationEntry entry,
  List<WorkspaceModelSelectionView> selections,
) {
  final data = entry.data;
  final connectionId = _string(data, 'modelConnectionId');
  final modelId = _string(data, 'modelId');

  return selections
      .where(
        (item) => item.connectionId == connectionId && item.modelId == modelId,
      )
      .firstOrNull;
}

List<_CloudResourceCreate> _baseSkillResources(
  List<WorkspaceConfigurationEntry> entries,
) => [
  for (final entry in entries.where((item) => item.kind == .skill))
    (kind: .skill, id: entry.id, data: _skillResourceData(entry)),
];

Map<String, Object?> _skillResourceData(WorkspaceConfigurationEntry entry) => {
  'source': entry.data['source'],
  'kind': entry.data['kind'],
  'title': entry.data['title'],
  'slug': entry.data['slug'],
  'description': entry.data['description'],
  'content': entry.data['content'],
  'isEnabled': entry.data['isEnabled'],
};

List<_CloudResourceCreate> _baseToolResources(
  List<WorkspaceConfigurationEntry> entries,
) => [
  for (final entry in entries.where((item) => item.kind == .tool))
    (kind: .tool, id: entry.id, data: _toolUpdateData(entry)),
];

List<_CloudResourceCreate> _baseAgentResources(
  List<WorkspaceConfigurationEntry> entries,
) => [
  for (final entry in entries.where((item) => item.kind == .agent))
    (kind: .agent, id: entry.id, data: _agentResourceData(entry)),
];

Map<String, Object?> _agentResourceData(WorkspaceConfigurationEntry entry) => {
  'name': entry.data['name'],
  'description': entry.data['description'],
  'content': entry.data['content'],
  'isEnabled': entry.data['isEnabled'],
  'visibility': entry.data['visibility'],
};

Map<String, Object?> _agentSkillData(
  WorkspaceConfigurationEntry entry,
  Map<String, String> appSkillIds,
) {
  final isAppSkill = entry.data['source'] == 'app';
  final skillIdentifier = _string(entry.data, 'skillId');
  final skillId = isAppSkill ? appSkillIds[skillIdentifier]! : skillIdentifier;

  return {
    'agentId': entry.data['agentId'],
    'skillId': skillId,
    if (isAppSkill) 'appSkillIdentifier': skillIdentifier,
  };
}

Map<String, Object?> _agentToolPermissionData(
  WorkspaceConfigurationEntry entry,
) => {
  'agentId': entry.data['agentId'],
  'toolId': entry.data['toolId'],
  'permissionMode': entry.data['permissionMode'],
};

Map<String, Object?> _skillSettingData(
  WorkspaceConfigurationEntry entry,
  Map<String, String> appSkillIds,
  String id,
) {
  final skillId = entry.data['source'] == 'app'
      ? appSkillIds[_string(entry.data, 'skillId')]!
      : _string(entry.data, 'skillId');

  return {'id': id, 'skillId': skillId, 'isEnabled': entry.data['isEnabled']};
}

WorkspaceResource? _resourceById(
  List<WorkspaceResource> active,
  WorkspaceResourceKind kind,
  String id,
) => active
    .where(
      (resource) => resource.resourceKind == kind && resource.resourceId == id,
    )
    .firstOrNull;

bool _resourceDataMatches(
  WorkspaceResource resource,
  Map<String, Object?> expected,
) {
  final current = CloudResourceMapper.decode(resource);

  return expected.entries.every((entry) => current[entry.key] == entry.value);
}

Map<String, Object?> _mergeResourceData(
  WorkspaceResource resource,
  Map<String, Object?> values,
) => {...CloudResourceMapper.decode(resource), ...values};

bool _skillResourceMatches(
  SkillResourceView resource,
  WorkspaceConfigurationEntry entry,
) =>
    resource.skillId == _string(entry.data, 'skillId') &&
    resource.title == _string(entry.data, 'title') &&
    resource.slug == _string(entry.data, 'slug') &&
    resource.description == _string(entry.data, 'description') &&
    resource.content == _string(entry.data, 'content');

Map<String, Object?> _toolUpdateData(WorkspaceConfigurationEntry entry) => {
  'toolId': entry.data['toolId'],
  'isEnabled': entry.data['isEnabled'],
  'permissionMode': entry.data['permissionMode'],
};

Future<void> _upsertToolPermission(
  CloudWorkspaceResourceStore store,
  WorkspaceConfigurationEntry entry,
  List<WorkspaceResource> active,
  String toolId,
) async {
  final existing = _existingToolPermission(active, toolId);
  if (existing == null) {
    await _createToolPermission(store, entry, toolId);

    return;
  }
  final data = _toolPermissionData(entry, toolId);
  if (_resourceDataMatches(existing, data)) return;
  await _updateToolPermission(store, entry, existing, toolId);
}

WorkspaceResource? _existingToolPermission(
  List<WorkspaceResource> active,
  String toolId,
) => active
    .where(_isNativeToolPermission)
    .where(
      (resource) => CloudResourceMapper.decode(resource)['toolId'] == toolId,
    )
    .firstOrNull;

Future<void> _createToolPermission(
  CloudWorkspaceResourceStore store,
  WorkspaceConfigurationEntry entry,
  String toolId,
) => store.create(
  kind: .toolPermission,
  id: const UuidV7().generate(),
  data: _toolPermissionData(entry, toolId),
);

Future<void> _updateToolPermission(
  CloudWorkspaceResourceStore store,
  WorkspaceConfigurationEntry entry,
  WorkspaceResource existing,
  String toolId,
) => store.update(
  kind: .toolPermission,
  id: existing.resourceId,
  revision: existing.revision,
  data: _mergeResourceData(existing, _toolPermissionData(entry, toolId)),
);

Map<String, Object?> _toolPermissionData(
  WorkspaceConfigurationEntry entry,
  String toolId,
) => {
  'toolId': toolId,
  'toolGroupId': null,
  'isEnabled': entry.data['isEnabled'],
  'permissionMode': entry.data['permissionMode'],
};

WorkspaceConfigurationEntry? _entryOfKind(
  List<WorkspaceConfigurationEntry> entries,
  WorkspaceConfigurationKind kind,
) => entries.where((entry) => entry.kind == kind).firstOrNull;

WorkspaceResource? _resourceOfKind(
  List<WorkspaceResource> resources,
  WorkspaceResourceKind kind,
) => resources.where((resource) => resource.resourceKind == kind).firstOrNull;

Future<void> _saveCompactionSetting(
  CloudWorkspaceResourceStore store,
  WorkspaceResource? existing,
  Map<String, Object?> data,
) async {
  if (existing == null) {
    await store.create(kind: .compactionSetting, id: 'workspace', data: data);

    return;
  }
  if (_resourceDataMatches(existing, data)) return;
  await store.update(
    kind: .compactionSetting,
    id: existing.resourceId,
    revision: existing.revision,
    data: _mergeResourceData(existing, data),
  );
}
