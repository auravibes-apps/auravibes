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
});

typedef _CloudExportRows = ({
  List<WorkspaceResource> skills,
  List<WorkspaceResource> nativeTools,
  Set<String> nativeToolIds,
  Map<String, WorkspaceResource> permissions,
});

typedef _CloudImportPlan = ({
  List<WorkspaceResource> active,
  Map<String, String> toolIds,
  Map<String, String> appSkillIds,
  Map<String, String> skillIds,
});

typedef _CloudResourceCreate = ({
  WorkspaceResourceKind kind,
  String id,
  Map<String, Object?> data,
});

typedef _SkillSettingUpdates = ({
  CloudWorkspaceResourceStore store,
  List<WorkspaceConfigurationEntry> entries,
  List<WorkspaceResource> active,
  Map<String, String> appSkillIds,
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
    final plan = await _importPlan(_store, _kinds, archive.entries);
    await _applyArchive(archive.entries, plan);
  }

  Future<void> _applyArchive(
    List<WorkspaceConfigurationEntry> entries,
    _CloudImportPlan plan,
  ) async {
    final (:active, :toolIds, :appSkillIds, :skillIds) = plan;
    await _createBaseResources(entries, toolIds, appSkillIds);
    await _applyExistingTools(entries, active, toolIds);
    await _createLinkedResources(entries, active, toolIds, appSkillIds);
    await _applyToolPermissions(entries, active, toolIds);
    await _applyCompaction(entries, active);
    await _applyExternalEntries(_calls, entries, skillIds);
  }

  Future<void> _createBaseResources(
    List<WorkspaceConfigurationEntry> entries,
    Map<String, String> toolIds,
    Map<String, String> appSkillIds,
  ) async {
    final resources = <_CloudResourceCreate>[
      ..._baseSkillResources(entries, appSkillIds),
      ..._baseToolResources(entries, toolIds),
      ..._baseAgentResources(entries),
    ];
    await _createBatches(resources);
  }

  Future<void> _createLinkedResources(
    List<WorkspaceConfigurationEntry> entries,
    List<WorkspaceResource> active,
    Map<String, String> toolIds,
    Map<String, String> appSkillIds,
  ) async {
    final resources = <_CloudResourceCreate>[
      ..._agentSkillResources(entries),
      ..._agentToolPermissionResources(entries, toolIds),
      ..._newSkillSettingResources(entries, active, appSkillIds),
    ];
    await _createBatches(resources);
    await _updateExistingSkillSettings((
      store: _store,
      entries: entries,
      active: active,
      appSkillIds: appSkillIds,
    ));
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

  Future<void> _applyExistingTools(
    List<WorkspaceConfigurationEntry> entries,
    List<WorkspaceResource> active,
    Map<String, String> toolIds,
  ) async {
    for (final entry in entries.where((entry) => entry.kind == .tool)) {
      final id = toolIds[entry.id];
      if (id == null) continue;
      await _updateExistingTool(_store, entry, active, id);
    }
  }

  Future<void> _applyToolPermissions(
    List<WorkspaceConfigurationEntry> entries,
    List<WorkspaceResource> active,
    Map<String, String> toolIds,
  ) async {
    for (final entry in entries.where((entry) => entry.kind == .tool)) {
      final id = toolIds[entry.id];
      if (id == null) continue;
      await _upsertToolPermission(_store, entry, active, id);
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

Map<String, String> _matchingToolIds(
  List<WorkspaceConfigurationEntry> entries,
  List<WorkspaceResource> target,
) {
  final existing = _nativeToolIdsByName(target);

  return {
    for (final entry in entries.where((item) => item.kind == .tool))
      entry.id: existing[_string(entry.data, 'toolId')] ?? entry.id,
  };
}

Map<String, String> _nativeToolIdsByName(List<WorkspaceResource> resources) => {
  for (final resource in resources.where(_isNativeTool))
    _string(CloudResourceMapper.decode(resource), 'toolId'):
        resource.resourceId,
};

Map<String, String> _appSkillIds(
  List<WorkspaceConfigurationEntry> entries,
  List<WorkspaceResource> target,
) {
  final existing = _existingAppSkillIds(target);
  final imported = _importedAppSkillIds(entries, existing);

  return {..._existingAppSettingIds(entries, existing), ...imported};
}

Map<String, String> _existingAppSettingIds(
  List<WorkspaceConfigurationEntry> entries,
  Map<String, String> existing,
) => _existingSettingsMap(_appSettingEntries(entries), existing);

List<WorkspaceConfigurationEntry> _appSettingEntries(
  List<WorkspaceConfigurationEntry> entries,
) => entries
    .where((item) => item.kind == .skillSetting && item.data['source'] == 'app')
    .toList();

Map<String, String> _existingSettingsMap(
  List<WorkspaceConfigurationEntry> entries,
  Map<String, String> existing,
) {
  final ids = <String, String>{};
  for (final entry in entries) {
    final skillId = _string(entry.data, 'skillId');
    final existingId = existing[skillId];
    if (existingId != null) ids[skillId] = existingId;
  }

  return ids;
}

Map<String, String> _existingAppSkillIds(List<WorkspaceResource> resources) => {
  for (final resource in resources.where((item) => item.resourceKind == .skill))
    if (_isAppSkill(resource))
      _string(CloudResourceMapper.decode(resource), 'slug'):
          resource.resourceId,
};

bool _isAppSkill(WorkspaceResource resource) =>
    CloudResourceMapper.decode(resource)['source'] == 'app';

Map<String, String> _importedAppSkillIds(
  List<WorkspaceConfigurationEntry> entries,
  Map<String, String> existing,
) => {
  for (final entry in entries.where(
    (item) => item.kind == .skill && item.data['source'] == 'app',
  ))
    _string(entry.data, 'slug'):
        existing[_string(entry.data, 'slug')] ?? entry.id,
};

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
  final archive = WorkspaceConfigurationArchiveCodec.remapIds(
    WorkspaceConfigurationArchiveCodec.decode(json),
  );
  _validateCloudEntries(archive.entries);

  return archive;
}

Future<_CloudImportPlan> _importPlan(
  CloudWorkspaceResourceStore store,
  List<WorkspaceResourceKind> kinds,
  List<WorkspaceConfigurationEntry> entries,
) async {
  final active = _activeResources(await store.watchResources(kinds).first);
  final toolIds = _matchingToolIds(entries, active);
  final appSkillIds = _appSkillIds(entries, active);
  _validateAppReferences(entries, appSkillIds);
  final skillIds = _cloudSkillIds(entries, appSkillIds);

  return (
    active: active,
    toolIds: toolIds,
    appSkillIds: appSkillIds,
    skillIds: skillIds,
  );
}

Map<String, String> _cloudSkillIds(
  List<WorkspaceConfigurationEntry> entries,
  Map<String, String> appSkillIds,
) => {
  for (final entry in entries.where((item) => item.kind == .skill))
    entry.id: _cloudSkillId(entry, appSkillIds),
};

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
  List<WorkspaceConfigurationEntry> entries,
  Map<String, String> skillIds,
) async {
  await _createModelConnections(calls, entries);
  await _createSkillResources(calls, entries, skillIds);
}

Future<void> _createModelConnections(
  CloudWorkspaceConfigurationCalls calls,
  List<WorkspaceConfigurationEntry> entries,
) async {
  for (final entry in entries.where((item) => item.kind == .modelConnection)) {
    await calls.createConnection(entry);
  }
}

Future<void> _createSkillResources(
  CloudWorkspaceConfigurationCalls calls,
  List<WorkspaceConfigurationEntry> entries,
  Map<String, String> skillIds,
) async {
  for (final entry in entries.where((item) => item.kind == .skillResource)) {
    await calls.createSkillResource(_skillResourceForTarget(entry, skillIds));
  }
}

WorkspaceConfigurationEntry _skillResourceForTarget(
  WorkspaceConfigurationEntry entry,
  Map<String, String> skillIds,
) => WorkspaceConfigurationEntry(
  kind: entry.kind,
  id: entry.id,
  data: {...entry.data, 'skillId': skillIds[_string(entry.data, 'skillId')]},
);

List<_CloudResourceCreate> _baseSkillResources(
  List<WorkspaceConfigurationEntry> entries,
  Map<String, String> appSkillIds,
) => [
  for (final entry in entries.where((item) => item.kind == .skill))
    if (_cloudSkillId(entry, appSkillIds) == entry.id)
      (
        kind: .skill,
        id: _cloudSkillId(entry, appSkillIds),
        data: _skillResourceData(entry),
      ),
];

String _cloudSkillId(
  WorkspaceConfigurationEntry entry,
  Map<String, String> appSkillIds,
) => entry.data['source'] == 'app'
    ? appSkillIds[_string(entry.data, 'slug')]!
    : entry.id;

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
  Map<String, String> toolIds,
) => [
  for (final entry in entries.where((item) => item.kind == .tool))
    if (toolIds[entry.id] == entry.id)
      (kind: .tool, id: toolIds[entry.id]!, data: _toolUpdateData(entry)),
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

List<_CloudResourceCreate> _agentSkillResources(
  List<WorkspaceConfigurationEntry> entries,
) => [
  for (final entry in entries.where((item) => item.kind == .agentSkill))
    (kind: .agentAssociation, id: entry.id, data: _agentSkillData(entry)),
];

Map<String, Object?> _agentSkillData(WorkspaceConfigurationEntry entry) {
  final isAppSkill = entry.data['source'] == 'app';
  final skillId = _string(entry.data, 'skillId');

  return {
    'agentId': entry.data['agentId'],
    'skillId': skillId,
    if (isAppSkill) 'appSkillIdentifier': skillId,
  };
}

List<_CloudResourceCreate> _agentToolPermissionResources(
  List<WorkspaceConfigurationEntry> entries,
  Map<String, String> toolIds,
) => [
  for (final entry in entries.where(
    (item) => item.kind == .agentToolPermission,
  ))
    (
      kind: .agentAssociation,
      id: entry.id,
      data: _agentToolPermissionData(entry, toolIds),
    ),
];

Map<String, Object?> _agentToolPermissionData(
  WorkspaceConfigurationEntry entry,
  Map<String, String> toolIds,
) => {
  'agentId': entry.data['agentId'],
  'toolId': toolIds[_string(entry.data, 'toolId')],
  'permissionMode': entry.data['permissionMode'],
};

List<_CloudResourceCreate> _newSkillSettingResources(
  List<WorkspaceConfigurationEntry> entries,
  List<WorkspaceResource> active,
  Map<String, String> appSkillIds,
) => [
  for (final entry in entries.where(
    (item) => item.kind == .skillSetting && item.data['source'] == 'app',
  ))
    if (_existingAppSkillSetting(active, entry, appSkillIds) == null)
      (
        kind: .skillSetting,
        id: _settingId(entry, appSkillIds),
        data: _skillSettingData(entry, appSkillIds),
      ),
];

WorkspaceResource? _existingAppSkillSetting(
  List<WorkspaceResource> active,
  WorkspaceConfigurationEntry entry,
  Map<String, String> appSkillIds,
) => active
    .where(
      (resource) =>
          resource.resourceKind == .skillSetting &&
          resource.resourceId == _settingId(entry, appSkillIds),
    )
    .firstOrNull;

Map<String, Object?> _skillSettingData(
  WorkspaceConfigurationEntry entry,
  Map<String, String> appSkillIds,
) {
  final id = _settingId(entry, appSkillIds);

  return {'id': id, 'skillId': id, 'isEnabled': entry.data['isEnabled']};
}

Future<void> _updateExistingSkillSettings(_SkillSettingUpdates updates) async {
  final entries = updates.entries.where(
    (item) => item.kind == .skillSetting && item.data['source'] == 'app',
  );
  for (final entry in entries) {
    await _updateAppSkillSetting(updates, entry);
  }
}

Future<void> _updateAppSkillSetting(
  _SkillSettingUpdates updates,
  WorkspaceConfigurationEntry entry,
) async {
  final existing = _existingAppSkillSetting(
    updates.active,
    entry,
    updates.appSkillIds,
  );
  if (existing == null) return;
  await updates.store.update(
    kind: .skillSetting,
    id: existing.resourceId,
    revision: existing.revision,
    data: _skillSettingData(entry, updates.appSkillIds),
  );
}

Future<void> _updateExistingTool(
  CloudWorkspaceResourceStore store,
  WorkspaceConfigurationEntry entry,
  List<WorkspaceResource> active,
  String id,
) async {
  final existing = _resourceById(active, .tool, id);
  if (existing == null) return;
  await store.update(
    kind: .tool,
    id: id,
    revision: existing.revision,
    data: _toolUpdateData(entry),
  );
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
  data: _toolPermissionData(entry, toolId),
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
  await store.update(
    kind: .compactionSetting,
    id: existing.resourceId,
    revision: existing.revision,
    data: data,
  );
}
