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
    Set<WorkspaceConfigurationKind>? selectedKinds,
  }) async {
    if (selectedKinds?.isEmpty ?? false) {
      return WorkspaceConfigurationArchive(
        workspaceName: workspaceName,
        entries: const [],
      );
    }
    final resources = await _store.watchResources(_kinds).first;
    final active = _activeResources(resources);
    final rows = _cloudExportRows(active);
    final entries = _resourceEntries(active, rows);
    await _appendExternalEntries(_calls, entries, rows.skills, selectedKinds);

    return WorkspaceConfigurationArchiveCodec.selectKinds(
      .new(workspaceName: workspaceName, entries: entries),
      selectedKinds ?? WorkspaceConfigurationKind.values.toSet(),
    );
  }

  Future<void> importJson(String json) async {
    final archive = _cloudArchive(json);
    final plan = await _importPlan(_store, _kinds, _calls, archive);
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
    final resources = <_CloudResourceCreate>[
      ..._baseSkillResources(entries),
      ..._baseToolResources(entries),
      ..._baseAgentResources(entries),
    ];
    final creates = <_CloudResourceCreate>[];
    for (final resource in resources) {
      final existing = _resourceById(active, resource.kind, resource.id);
      if (existing == null) {
        creates.add(resource);
        continue;
      }
      if (_resourceDataMatches(existing, resource.data)) continue;
      await _store.update(
        kind: resource.kind,
        id: resource.id,
        revision: existing.revision,
        data: _mergeResourceData(existing, resource.data),
      );
    }
    await _createBatches(creates);
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
  ) async {
    for (final entry in entries.where(
      (item) => item.kind == .agentSkill || item.kind == .agentToolPermission,
    )) {
      final existing = _resourceById(active, .agentAssociation, entry.id);
      final data = entry.kind == .agentSkill
          ? _agentSkillData(entry, appSkillIds)
          : _agentToolPermissionData(entry);
      if (existing == null) {
        await _store.create(kind: .agentAssociation, id: entry.id, data: data);
      } else if (entry.kind == .agentToolPermission &&
          !_resourceDataMatches(existing, data)) {
        await _store.update(
          kind: .agentAssociation,
          id: entry.id,
          revision: existing.revision,
          data: _mergeResourceData(existing, data),
        );
      }
    }
  }

  Future<void> _upsertSkillSettings(
    List<WorkspaceConfigurationEntry> entries,
    List<WorkspaceResource> active,
    Map<String, String> appSkillIds,
  ) async {
    for (final entry in entries.where((item) => item.kind == .skillSetting)) {
      final mappedExisting = _resourceById(active, .skillSetting, entry.id);
      final id = mappedExisting?.resourceId ?? _settingId(entry, appSkillIds);
      final existing =
          mappedExisting ?? _resourceById(active, .skillSetting, id);
      final data = _skillSettingData(entry, appSkillIds, id);
      if (existing == null) {
        await _store.create(kind: .skillSetting, id: id, data: data);
      } else if (!_resourceDataMatches(existing, data)) {
        await _store.update(
          kind: .skillSetting,
          id: id,
          revision: existing.revision,
          data: _mergeResourceData(existing, data),
        );
      }
    }
  }

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

CloudWorkspaceConfigurationCalls _productionCalls(
  CloudWorkspaceResourceStore store,
) => (
  listConnections: () => _listModelConnections(store),
  listModelSelections: () => _listModelSelections(store),
  listSkillResources: (skillId) => _listSkillResources(store, skillId),
  createConnection: (entry) => _createModelConnection(store, entry),
  createSkillResource: (entry) => _createSkillResource(store, entry),
  updateSkillResource: (entry, revision) =>
      _updateSkillResource(store, entry, revision),
  updateToolSamplingPolicy: (selectionId, policy) =>
      _updateToolSamplingPolicy(store, selectionId, policy),
);

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
    .new(
      workspaceId: api.workspaceId,
      requestId: const UuidV7().generate(),
      resourceId: entry.id,
      expectedRevision: expectedRevision,
      title: _string(entry.data, 'title'),
      description: _string(entry.data, 'description'),
      content: _string(entry.data, 'content'),
    ),
  );
}

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

Future<_CloudImportPlan> _importPlan(
  CloudWorkspaceResourceStore store,
  List<WorkspaceResourceKind> kinds,
  CloudWorkspaceConfigurationCalls calls,
  WorkspaceConfigurationArchive archive,
) async {
  final active = _activeResources(await store.watchResources(kinds).first);
  final hasModelConnections = archive.entries.any(
    (item) => item.kind == .modelConnection || item.kind == .modelSelection,
  );
  final hasModelSelections = archive.entries.any(
    (item) => item.kind == .modelSelection,
  );
  final connections = hasModelConnections
      ? await calls.listConnections()
      : <ModelConnectionView>[];
  final selections = hasModelSelections
      ? await calls.listModelSelections()
      : <WorkspaceModelSelectionView>[];
  final idMapping = _existingDefinitionIds(archive, active, connections);
  final appSkillIds = _existingAppSkillIds(active);
  _mapExistingRelationships(
    archive,
    active,
    selections,
    appSkillIds,
    idMapping,
  );
  final skillResources = await _existingSkillResources(
    calls,
    archive,
    idMapping,
  );
  _mapExistingSkillResources(archive, idMapping, skillResources);
  final remapped = WorkspaceConfigurationArchiveCodec.remapIds(
    archive,
    idMapping: idMapping,
  );
  final resolvedAppSkillIds = {
    ...appSkillIds,
    for (final entry in remapped.entries.where(
      (item) => item.kind == .skill && item.data['source'] == 'app',
    ))
      _string(entry.data, 'slug'): entry.id,
  };
  _validateCloudEntries(remapped.entries);
  _validateAppReferences(remapped.entries, resolvedAppSkillIds);

  return (
    active: active,
    entries: remapped.entries,
    appSkillIds: resolvedAppSkillIds,
    existingConnectionIds: {for (final item in connections) item.id},
    skillResourcesById: {for (final item in skillResources) item.id: item},
  );
}

Map<WorkspaceConfigurationArchiveEntryId, String> _existingDefinitionIds(
  WorkspaceConfigurationArchive archive,
  List<WorkspaceResource> active,
  List<ModelConnectionView> connections,
) {
  final ids = <WorkspaceConfigurationArchiveEntryId, String>{};
  for (final entry in archive.entries.where((item) => item.kind == .agent)) {
    final name = _string(entry.data, 'name').trim();
    final existing = active
        .where((item) => item.resourceKind == .agent)
        .where(
          (item) =>
              _string(CloudResourceMapper.decode(item), 'name').trim() == name,
        )
        .firstOrNull;
    if (existing != null) {
      ids[(kind: entry.kind, id: entry.id)] = existing.resourceId;
    }
  }
  for (final entry in archive.entries.where((item) => item.kind == .skill)) {
    final source = _string(entry.data, 'source');
    final slug = _string(entry.data, 'slug');
    final existing = active.where((item) => item.resourceKind == .skill).where((
      item,
    ) {
      final data = CloudResourceMapper.decode(item);

      return data['source'] == source && data['slug'] == slug;
    }).firstOrNull;
    if (existing != null) {
      ids[(kind: entry.kind, id: entry.id)] = existing.resourceId;
    }
  }
  final toolIds = _nativeToolIdsByName(active);
  for (final entry in archive.entries.where((item) => item.kind == .tool)) {
    final existingId = toolIds[_string(entry.data, 'toolId')];
    if (existingId != null) ids[(kind: entry.kind, id: entry.id)] = existingId;
  }
  for (final entry in archive.entries.where(
    (item) => item.kind == .modelConnection,
  )) {
    final providerId = _string(entry.data, 'providerId');
    final name = _string(entry.data, 'name');
    final url = entry.data['url'] as String?;
    final existing = connections
        .where(
          (item) =>
              item.providerId == providerId &&
              item.name == name &&
              WorkspaceConfigurationArchiveCodec.publicUrl(item.url) == url,
        )
        .firstOrNull;
    if (existing != null) {
      ids[(kind: entry.kind, id: entry.id)] = existing.id;
    }
  }

  return ids;
}

void _mapExistingRelationships(
  WorkspaceConfigurationArchive archive,
  List<WorkspaceResource> active,
  List<WorkspaceModelSelectionView> selections,
  Map<String, String> appSkillIds,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  String? targetId(WorkspaceConfigurationKind kind, Object? sourceId) =>
      sourceId is String ? ids[(kind: kind, id: sourceId)] : null;

  for (final entry in archive.entries.where(
    (item) => item.kind == .agentSkill,
  )) {
    final agentId = targetId(.agent, entry.data['agentId']);
    final isAppSkill = entry.data['source'] == 'app';
    final skillIdentifier = _string(entry.data, 'skillId');
    final skillId = isAppSkill
        ? appSkillIds[skillIdentifier]
        : targetId(.skill, skillIdentifier);
    if (agentId == null || skillId == null) continue;
    final existing = active
        .where((item) => item.resourceKind == .agentAssociation)
        .where((item) {
          final data = CloudResourceMapper.decode(item);

          return data['agentId'] == agentId &&
              data['skillId'] == skillId &&
              (isAppSkill
                  ? data['appSkillIdentifier'] == skillIdentifier
                  : data['appSkillIdentifier'] == null);
        })
        .firstOrNull;
    if (existing != null) {
      ids[(kind: entry.kind, id: entry.id)] = existing.resourceId;
    }
  }
  for (final entry in archive.entries.where(
    (item) => item.kind == .agentToolPermission,
  )) {
    final agentId = targetId(.agent, entry.data['agentId']);
    final toolId = targetId(.tool, entry.data['toolId']);
    if (agentId == null || toolId == null) continue;
    final existing = active
        .where((item) => item.resourceKind == .agentAssociation)
        .where((item) {
          final data = CloudResourceMapper.decode(item);

          return data['agentId'] == agentId && data['toolId'] == toolId;
        })
        .firstOrNull;
    if (existing != null) {
      ids[(kind: entry.kind, id: entry.id)] = existing.resourceId;
    }
  }
  for (final entry in archive.entries.where(
    (item) => item.kind == .skillSetting,
  )) {
    final isAppSkill = entry.data['source'] == 'app';
    final skillId = isAppSkill
        ? appSkillIds[_string(entry.data, 'skillId')]
        : targetId(.skill, entry.data['skillId']);
    if (skillId == null) continue;
    final existing = active
        .where((item) => item.resourceKind == .skillSetting)
        .where((item) => CloudResourceMapper.decode(item)['skillId'] == skillId)
        .firstOrNull;
    if (existing != null) {
      ids[(kind: entry.kind, id: entry.id)] = existing.resourceId;
    }
  }
  for (final entry in archive.entries.where(
    (item) => item.kind == .modelSelection,
  )) {
    final connectionId = targetId(
      .modelConnection,
      entry.data['modelConnectionId'],
    );
    if (connectionId == null) continue;
    final modelId = _string(entry.data, 'modelId');
    final existing = selections
        .where(
          (item) =>
              item.connectionId == connectionId && item.modelId == modelId,
        )
        .firstOrNull;
    if (existing != null) {
      ids[(kind: entry.kind, id: entry.id)] = existing.id;
    }
  }
}

Future<List<SkillResourceView>> _existingSkillResources(
  CloudWorkspaceConfigurationCalls calls,
  WorkspaceConfigurationArchive archive,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) async {
  final skillIds = {
    for (final entry in archive.entries.where(
      (item) => item.kind == .skillResource,
    ))
      if (ids[(
            kind: WorkspaceConfigurationKind.skill,
            id: _string(entry.data, 'skillId'),
          )]
          case final String skillId)
        skillId,
  };
  final resources = <SkillResourceView>[];
  for (final skillId in skillIds) {
    resources.addAll(await calls.listSkillResources(skillId));
  }

  return resources;
}

void _mapExistingSkillResources(
  WorkspaceConfigurationArchive archive,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
  List<SkillResourceView> resources,
) {
  for (final entry in archive.entries.where(
    (item) => item.kind == .skillResource,
  )) {
    final skillId =
        ids[(
          kind: WorkspaceConfigurationKind.skill,
          id: _string(entry.data, 'skillId'),
        )];
    if (skillId == null) continue;
    final slug = _string(entry.data, 'slug');
    final existing = resources
        .where((item) => item.skillId == skillId && item.slug == slug)
        .firstOrNull;
    if (existing != null) {
      ids[(kind: entry.kind, id: entry.id)] = existing.id;
    }
  }
}

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
  Set<WorkspaceConfigurationKind>? selectedKinds,
) async {
  if (selectedKinds == null ||
      selectedKinds.contains(WorkspaceConfigurationKind.modelConnection) ||
      selectedKinds.contains(WorkspaceConfigurationKind.modelSelection)) {
    await _appendModelConnections(calls, entries);
  }
  if (selectedKinds == null ||
      selectedKinds.contains(WorkspaceConfigurationKind.modelSelection)) {
    await _appendModelSelections(calls, entries);
  }
  if (selectedKinds == null ||
      selectedKinds.contains(WorkspaceConfigurationKind.skillResource)) {
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
  final entries = plan.entries;
  final existingConnectionIds = plan.existingConnectionIds;
  final skillResourcesById = plan.skillResourcesById;
  final connections = entries.where((item) => item.kind == .modelConnection);
  for (final entry in connections) {
    if (existingConnectionIds.contains(entry.id)) continue;
    await calls.createConnection(entry);
  }
  for (final entry in entries.where((item) => item.kind == .skillResource)) {
    final existing = skillResourcesById[entry.id];
    if (existing == null) {
      await calls.createSkillResource(entry);
    } else if (!_skillResourceMatches(existing, entry)) {
      await calls.updateSkillResource(entry, existing.revision);
    }
  }
  final selections = entries.where((item) => item.kind == .modelSelection);
  if (selections.isEmpty) return;
  final views = await calls.listModelSelections();
  for (final entry in selections) {
    final connectionId = _string(entry.data, 'modelConnectionId');
    final modelId = _string(entry.data, 'modelId');
    final selection = views
        .where(
          (item) =>
              item.connectionId == connectionId && item.modelId == modelId,
        )
        .firstOrNull;
    if (selection == null) {
      throw const WorkspaceConfigurationArchiveException(
        'workspace_archive.unsupported_configuration',
      );
    }
    final policy = _string(entry.data, 'toolSamplingPolicy');
    if (selection.toolSamplingPolicy == policy) continue;
    await calls.updateToolSamplingPolicy(selection.id, policy);
  }
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
