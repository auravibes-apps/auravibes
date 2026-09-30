import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_configuration_archive.dart';

class LocalWorkspaceConfigurationRepository(final AppDatabase _database) {
  Future<WorkspaceConfigurationArchive> export(
    String workspaceId, {
    Set<WorkspaceConfigurationKind>? selectedKinds,
  }) async {
    final workspaceName = await _localWorkspaceName(_database, workspaceId);
    if (selectedKinds?.isEmpty ?? false) {
      return WorkspaceConfigurationArchive(
        workspaceName: workspaceName,
        entries: const [],
      );
    }
    final rows = await _configurationRows(_database, workspaceId);
    final relations = await _relationshipRows(
      _database,
      rows.content.agents,
      rows.content.skills,
    );

    return WorkspaceConfigurationArchiveCodec.selectKinds(
      .new(
        workspaceName: workspaceName,
        entries: _configurationEntries(rows, relations),
      ),
      selectedKinds ?? WorkspaceConfigurationKind.values.toSet(),
    );
  }
}

typedef _ContentRows = ({
  List<AgentsTable> agents,
  List<SkillsTable> skills,
  List<ToolsTable> tools,
  List<ServiceConnectionTable> modelConnections,
  List<WorkspaceModelSelectionTable> modelSelections,
});

typedef _SettingsRows = ({
  List<AppSkillWorkspaceSettingsTable> appSkillSettings,
  WorkspaceCompactionSettingsTable? compaction,
});

typedef _ConfigurationRows = ({_ContentRows content, _SettingsRows settings});

typedef _RelationshipRows = ({
  List<AgentSkillsTable> agentSkills,
  List<AgentToolsTable> agentTools,
  List<SkillResourcesTable> skillResources,
});

Future<String> _localWorkspaceName(
  AppDatabase database,
  String workspaceId,
) async {
  final workspace = await database.workspaceDao.getWorkspaceById(workspaceId);
  if (workspace == null || workspace.type != WorkspaceType.local) {
    throw const WorkspaceConfigurationArchiveException(
      'workspace_archive.invalid_target',
    );
  }

  return workspace.name;
}

Future<_ConfigurationRows> _configurationRows(
  AppDatabase database,
  String workspaceId,
) async => (
  content: await _contentRows(database, workspaceId),
  settings: await _settingsRows(database, workspaceId),
);

Future<_ContentRows> _contentRows(
  AppDatabase database,
  String workspaceId,
) async {
  final modelConnections = await _modelConnections(database, workspaceId);

  return (
    agents: await _workspaceAgents(database, workspaceId),
    skills: await _workspaceSkills(database, workspaceId),
    tools: await _workspaceTools(database, workspaceId),
    modelConnections: modelConnections,
    modelSelections: await _workspaceModelSelections(
      database,
      modelConnections.map((row) => row.id).toList(),
    ),
  );
}

Future<List<AgentsTable>> _workspaceAgents(
  AppDatabase database,
  String workspaceId,
) => (database.select(
  database.agents,
)..where((row) => row.workspaceId.equals(workspaceId))).get();

Future<List<SkillsTable>> _workspaceSkills(
  AppDatabase database,
  String workspaceId,
) => (database.select(
  database.skills,
)..where((row) => row.workspaceId.equals(workspaceId))).get();

Future<List<ToolsTable>> _workspaceTools(
  AppDatabase database,
  String workspaceId,
) => (database.select(
  database.tools,
)..where((row) => row.workspaceId.equals(workspaceId))).get();

Future<List<ServiceConnectionTable>> _modelConnections(
  AppDatabase database,
  String workspaceId,
) => database.modelConnectionsDao.getAllModelConnectionsByWorkspace(
  workspaceIds: [workspaceId],
);

Future<List<WorkspaceModelSelectionTable>> _workspaceModelSelections(
  AppDatabase database,
  List<String> connectionIds,
) {
  if (connectionIds.isEmpty) return Future.value([]);

  return (database.select(
    database.workspaceModelSelections,
  )..where((row) => row.modelConnectionId.isIn(connectionIds))).get();
}

Future<_SettingsRows> _settingsRows(
  AppDatabase database,
  String workspaceId,
) async => (
  appSkillSettings: await (database.select(
    database.appSkillWorkspaceSettings,
  )..where((row) => row.workspaceId.equals(workspaceId))).get(),
  compaction: await database.workspaceCompactionSettingsDao.getByWorkspaceId(
    workspaceId,
  ),
);

Future<_RelationshipRows> _relationshipRows(
  AppDatabase database,
  List<AgentsTable> agents,
  List<SkillsTable> skills,
) async {
  final agentIds = agents.map((agent) => agent.id).toList();
  final skillIds = skills.map((skill) => skill.id).toList();

  return (
    agentSkills: await _agentSkills(database, agentIds),
    agentTools: await _agentTools(database, agentIds),
    skillResources: await _skillResources(database, skillIds),
  );
}

Future<List<AgentSkillsTable>> _agentSkills(
  AppDatabase database,
  List<String> agentIds,
) => (database.select(
  database.agentSkills,
)..where((row) => row.agentId.isIn(agentIds))).get();

Future<List<AgentToolsTable>> _agentTools(
  AppDatabase database,
  List<String> agentIds,
) => (database.select(
  database.agentTools,
)..where((row) => row.agentId.isIn(agentIds))).get();

Future<List<SkillResourcesTable>> _skillResources(
  AppDatabase database,
  List<String> skillIds,
) => (database.select(
  database.skillResources,
)..where((row) => row.skillId.isIn(skillIds))).get();

List<WorkspaceConfigurationEntry> _configurationEntries(
  _ConfigurationRows rows,
  _RelationshipRows relations,
) => [..._definitionEntries(rows), ..._relationshipEntries(rows, relations)];

List<WorkspaceConfigurationEntry> _definitionEntries(_ConfigurationRows rows) {
  final content = rows.content;
  final settings = rows.settings;

  return [
    ..._agentEntries(content.agents),
    ..._skillEntries(content.skills),
    ..._toolEntries(content.tools),
    ..._modelConnectionEntries(content.modelConnections),
    ..._modelSelectionEntries(content.modelSelections),
    ..._appSkillSettingEntries(settings.appSkillSettings),
    _compactionEntry(settings.compaction),
  ];
}

List<WorkspaceConfigurationEntry> _relationshipEntries(
  _ConfigurationRows rows,
  _RelationshipRows relations,
) {
  final nativeToolIds = rows.content.tools
      .where((tool) => tool.workspaceToolsGroupId == null)
      .map((tool) => tool.id)
      .toSet();

  return [
    ..._agentSkillEntries(relations.agentSkills),
    ..._nativeToolPermissionEntries(relations.agentTools, nativeToolIds),
    ..._skillResourceEntries(relations.skillResources),
  ];
}

List<WorkspaceConfigurationEntry> _agentEntries(List<AgentsTable> rows) => [
  for (final row in rows) _agentEntry(row),
];

List<WorkspaceConfigurationEntry> _skillEntries(List<SkillsTable> rows) => [
  for (final row in rows) _skillEntry(row),
];

List<WorkspaceConfigurationEntry> _toolEntries(List<ToolsTable> rows) => [
  for (final row in rows.where((tool) => tool.workspaceToolsGroupId == null))
    _toolEntry(row),
];

List<WorkspaceConfigurationEntry> _modelConnectionEntries(
  List<ServiceConnectionTable> rows,
) => [for (final row in rows) _modelConnectionEntry(row)];

List<WorkspaceConfigurationEntry> _modelSelectionEntries(
  List<WorkspaceModelSelectionTable> rows,
) => [
  for (final row in rows)
    if (row.toolSamplingPolicy case final String policy)
      WorkspaceConfigurationEntry(
        kind: .modelSelection,
        id: row.id,
        data: {
          'modelConnectionId': row.modelConnectionId,
          'modelId': row.modelId,
          'toolSamplingPolicy': policy,
        },
      ),
];

List<WorkspaceConfigurationEntry> _appSkillSettingEntries(
  List<AppSkillWorkspaceSettingsTable> rows,
) => [for (final row in rows) _appSkillSettingEntry(row)];

List<WorkspaceConfigurationEntry> _agentSkillEntries(
  List<AgentSkillsTable> rows,
) => [for (final row in rows) _agentSkillEntry(row)];

List<WorkspaceConfigurationEntry> _nativeToolPermissionEntries(
  List<AgentToolsTable> rows,
  Set<String> nativeToolIds,
) => [
  for (final row in rows.where((row) => nativeToolIds.contains(row.toolId)))
    _agentToolPermissionEntry(row),
];

List<WorkspaceConfigurationEntry> _skillResourceEntries(
  List<SkillResourcesTable> rows,
) => [for (final row in rows) _skillResourceEntry(row)];

WorkspaceConfigurationEntry _agentEntry(AgentsTable row) =>
    WorkspaceConfigurationEntry(
      kind: .agent,
      id: row.id,
      data: {
        'name': row.name,
        'description': row.description,
        'content': row.content,
        'isEnabled': row.isEnabled,
        'visibility': row.visibility,
      },
    );

WorkspaceConfigurationEntry _skillEntry(SkillsTable row) =>
    WorkspaceConfigurationEntry(
      kind: .skill,
      id: row.id,
      data: {
        'source': row.source.name,
        'kind': row.kind.name,
        'title': row.title,
        'slug': row.slug,
        'description': row.description,
        'content': row.content,
        'isEnabled': row.isEnabled,
      },
    );

WorkspaceConfigurationEntry _skillResourceEntry(SkillResourcesTable row) =>
    WorkspaceConfigurationEntry(
      kind: .skillResource,
      id: row.id,
      data: {
        'skillId': row.skillId,
        'title': row.title,
        'slug': row.slug,
        'description': row.description,
        'content': row.content,
      },
    );

WorkspaceConfigurationEntry _appSkillSettingEntry(
  AppSkillWorkspaceSettingsTable row,
) => WorkspaceConfigurationEntry(
  kind: .skillSetting,
  id: row.id,
  data: {
    'skillId': row.appSkillIdentifier,
    'source': 'app',
    'isEnabled': row.isEnabled,
  },
);

WorkspaceConfigurationEntry _modelConnectionEntry(ServiceConnectionTable row) =>
    WorkspaceConfigurationEntry(
      kind: .modelConnection,
      id: row.id,
      data: {
        'name': row.name,
        'providerId': row.serviceId,
        'url': WorkspaceConfigurationArchiveCodec.publicUrl(row.url),
      },
    );

WorkspaceConfigurationEntry _toolEntry(ToolsTable row) =>
    WorkspaceConfigurationEntry(
      kind: .tool,
      id: row.id,
      data: {
        'toolId': row.toolId,
        'isEnabled': row.isEnabled,
        'permissionMode': _archivePermission(row.permissions.name),
      },
    );

WorkspaceConfigurationEntry _agentSkillEntry(AgentSkillsTable row) =>
    WorkspaceConfigurationEntry(
      kind: .agentSkill,
      id: row.id,
      data: {
        'agentId': row.agentId,
        'skillId': row.workspaceSkillId ?? row.appSkillIdentifier,
        'source': row.workspaceSkillId == null ? 'app' : 'user',
      },
    );

WorkspaceConfigurationEntry _agentToolPermissionEntry(AgentToolsTable row) =>
    WorkspaceConfigurationEntry(
      kind: .agentToolPermission,
      id: row.id,
      data: {
        'agentId': row.agentId,
        'toolId': row.toolId,
        'permissionMode': _archivePermission(row.permissions.name),
      },
    );

WorkspaceConfigurationEntry _compactionEntry(
  WorkspaceCompactionSettingsTable? row,
) => WorkspaceConfigurationEntry(
  kind: .compactionSetting,
  id: 'workspace',
  data: {
    'autoCompactionEnabled': row?.autoCompactEnabled ?? true,
    'usagePercentageThreshold': row?.usagePercentageThreshold ?? 80,
    'remainingTokenThreshold': row?.remainingTokenThreshold ?? 2000,
  },
);

String _archivePermission(String access) => switch (access) {
  'granted' => 'alwaysAllow',
  'denied' => 'alwaysDeny',
  _ => 'alwaysAsk',
};
