import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/database/drift/tables/skills.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_configuration_archive.dart';
import 'package:drift/drift.dart';

class LocalWorkspaceConfigurationImporter(final AppDatabase _database) {
  Future<String> importJson(String json, {String? targetWorkspaceId}) =>
      Future.sync(() => _importArchiveJson(_database, json, targetWorkspaceId));
}

WorkspaceConfigurationArchive _decodeAndRemap(String json) =>
    WorkspaceConfigurationArchiveCodec.remapIds(
      WorkspaceConfigurationArchiveCodec.decode(json),
    );

Future<String> _importArchive(
  AppDatabase database,
  WorkspaceConfigurationArchive archive,
  String? targetWorkspaceId,
) async {
  final workspaceId = await _targetWorkspace(
    database,
    archive.workspaceName,
    targetWorkspaceId,
  );
  await _insertEntries(database, workspaceId, archive.entries);

  return workspaceId;
}

Future<String> _importArchiveJson(
  AppDatabase database,
  String json,
  String? targetWorkspaceId,
) {
  final archive = _decodeAndRemap(json);

  return database.transaction(
    () => _importArchive(database, archive, targetWorkspaceId),
  );
}

typedef _ImportContext = ({
  AppDatabase database,
  String workspaceId,
  List<WorkspaceConfigurationEntry> entries,
  Map<String, String> toolIds,
});

typedef _SkillNames = ({Set<String> titles, Set<String> slugs});
typedef _SkillValues = ({
  SkillSourceTable source,
  SkillKindTable kind,
  String description,
  String content,
  bool isEnabled,
});

Future<String> _targetWorkspace(
  AppDatabase database,
  String name,
  String? targetWorkspaceId,
) async {
  if (targetWorkspaceId == null) {
    final workspace = await WorkspaceRepository(database)
        .createWorkspace(.new(name: name, type: .local));

    return workspace.id;
  }
  final existing = await database.workspaceDao.getWorkspaceById(
    targetWorkspaceId,
  );
  if (existing == null || existing.type != WorkspaceType.local) {
    throw const WorkspaceConfigurationArchiveException(
      'workspace_archive.invalid_target',
    );
  }

  return targetWorkspaceId;
}

Future<void> _insertEntries(
  AppDatabase database,
  String workspaceId,
  List<WorkspaceConfigurationEntry> entries,
) async {
  final context = (
    database: database,
    workspaceId: workspaceId,
    entries: entries,
    toolIds: <String, String>{},
  );
  await _insertDefinitions(context);
  await _insertSkillResources(context);
  await _insertSkillSettings(context);
  await _insertAgentLinks(context);
  await _insertCompaction(context);
}

Future<void> _insertDefinitions(_ImportContext context) async {
  await _insertSkills(context);
  await _insertAgents(context);
  await _insertModelConnections(context);
  await _insertTools(context);
}

Future<void> _insertSkills(_ImportContext context) async {
  final names = await _skillNames(context.database, context.workspaceId);
  for (final entry in _entriesOfKind(context, .skill)) {
    await _insertSkill(context, entry, names);
  }
}

Future<_SkillNames> _skillNames(
  AppDatabase database,
  String workspaceId,
) async {
  final rows = await _existingSkills(database, workspaceId);

  return _skillNamesFrom(rows);
}

Future<List<SkillsTable>> _existingSkills(
  AppDatabase database,
  String workspaceId,
) => (database.select(
  database.skills,
)..where((row) => row.workspaceId.equals(workspaceId))).get();

_SkillNames _skillNamesFrom(List<SkillsTable> rows) {
  final titles = rows.map((row) => row.title).toSet();
  final slugs = rows.map((row) => row.slug).toSet();

  return (titles: titles, slugs: slugs);
}

Future<void> _insertSkill(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
  _SkillNames names,
) async {
  final data = entry.data;
  final title = _unique(_string(data, 'title'), names.titles);
  final slug = _unique(_string(data, 'slug'), names.slugs);
  final _ = await context.database
      .into(context.database.skills)
      .insert(_skillCompanion(context.workspaceId, entry, title, slug));
}

SkillsCompanion _skillCompanion(
  String workspaceId,
  WorkspaceConfigurationEntry entry,
  String title,
  String slug,
) {
  final values = _skillValues(entry.data);

  return _skillIdentity(workspaceId, entry, title, slug).copyWith(
    source: .new(values.source),
    kind: .new(values.kind),
    description: .new(values.description),
    content: .new(values.content),
    isEnabled: .new(values.isEnabled),
  );
}

SkillsCompanion _skillIdentity(
  String workspaceId,
  WorkspaceConfigurationEntry entry,
  String title,
  String slug,
) => SkillsCompanion(
  id: .new(entry.id),
  workspaceId: .new(workspaceId),
  title: .new(title),
  slug: .new(slug),
);

_SkillValues _skillValues(Map<String, Object?> data) => (
  source: SkillSourceTable.values.byName(_string(data, 'source')),
  kind: SkillKindTable.values.byName(_string(data, 'kind')),
  description: _string(data, 'description'),
  content: _string(data, 'content'),
  isEnabled: _bool(data, 'isEnabled'),
);

Future<void> _insertAgents(_ImportContext context) async {
  for (final entry in _entriesOfKind(context, .agent)) {
    final _ = await context.database
        .into(context.database.agents)
        .insert(_agentCompanion(context.workspaceId, entry));
  }
}

AgentsCompanion _agentCompanion(
  String workspaceId,
  WorkspaceConfigurationEntry entry,
) {
  final data = entry.data;

  return AgentsCompanion.insert(
    id: .new(entry.id),
    workspaceId: workspaceId,
    name: _string(data, 'name'),
    description: .new(_string(data, 'description')),
    content: _string(data, 'content'),
    isEnabled: .new(_bool(data, 'isEnabled')),
    visibility: .new(_string(data, 'visibility')),
  );
}

Future<void> _insertModelConnections(_ImportContext context) async {
  for (final entry in _entriesOfKind(context, .modelConnection)) {
    final _ = await context.database.modelConnectionsDao.insertModelConnection(
      _modelConnectionCompanion(context.workspaceId, entry),
    );
  }
}

ServiceConnectionsCompanion _modelConnectionCompanion(
  String workspaceId,
  WorkspaceConfigurationEntry entry,
) {
  final data = entry.data;

  return ServiceConnectionsCompanion.insert(
    id: .new(entry.id),
    name: _string(data, 'name'),
    serviceId: _string(data, 'providerId'),
    kind: .modelProvider,
    authenticationType: .apiKey,
    url: .new(data['url'] as String?),
    workspaceId: workspaceId,
    isEnabled: const Value(false),
  );
}

Future<void> _insertTools(_ImportContext context) async {
  final existing = await (context.database.select(
    context.database.tools,
  )..where((row) => row.workspaceId.equals(context.workspaceId))).get();
  for (final entry in _entriesOfKind(context, .tool)) {
    await _upsertTool(context, entry, existing);
  }
}

Future<void> _upsertTool(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
  List<ToolsTable> existing,
) async {
  final match = _findNativeTool(entry, existing);
  if (match == null) {
    await _createTool(context, entry);
    context.toolIds[entry.id] = entry.id;

    return;
  }
  await _updateTool(context.database, entry, match);
  context.toolIds[entry.id] = match.id;
}

ToolsTable? _findNativeTool(
  WorkspaceConfigurationEntry entry,
  List<ToolsTable> existing,
) => existing
    .where(
      (row) =>
          row.toolId == _string(entry.data, 'toolId') &&
          row.workspaceToolsGroupId == null,
    )
    .firstOrNull;

Future<void> _createTool(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
) async {
  final _ = await context.database
      .into(context.database.tools)
      .insert(_newToolCompanion(context.workspaceId, entry));
}

ToolsCompanion _newToolCompanion(
  String workspaceId,
  WorkspaceConfigurationEntry entry,
) {
  final data = entry.data;

  return ToolsCompanion.insert(
    id: .new(entry.id),
    workspaceId: workspaceId,
    toolId: _string(data, 'toolId'),
    isEnabled: .new(_bool(data, 'isEnabled')),
    permissions: .new(_localPermission(_string(data, 'permissionMode'))),
  );
}

Future<void> _updateTool(
  AppDatabase database,
  WorkspaceConfigurationEntry entry,
  ToolsTable existing,
) async {
  final _ = await (database.update(
    database.tools,
  )..where((row) => row.id.equals(existing.id))).write(_toolSettings(entry));
}

ToolsCompanion _toolSettings(WorkspaceConfigurationEntry entry) {
  final data = entry.data;

  return ToolsCompanion(
    isEnabled: .new(_bool(data, 'isEnabled')),
    permissions: .new(_localPermission(_string(data, 'permissionMode'))),
  );
}

Future<void> _insertSkillResources(_ImportContext context) async {
  for (final entry in _entriesOfKind(context, .skillResource)) {
    final _ = await context.database
        .into(context.database.skillResources)
        .insert(_skillResourceCompanion(entry));
  }
}

SkillResourcesCompanion _skillResourceCompanion(
  WorkspaceConfigurationEntry entry,
) {
  final data = entry.data;

  return SkillResourcesCompanion.insert(
    id: .new(entry.id),
    skillId: _string(data, 'skillId'),
    title: _string(data, 'title'),
    slug: _string(data, 'slug'),
    description: .new(_string(data, 'description')),
    content: _string(data, 'content'),
  );
}

Future<void> _insertSkillSettings(_ImportContext context) async {
  for (final entry in _entriesOfKind(context, .skillSetting)) {
    if (entry.data['source'] == 'app') {
      await _setAppSkillSetting(context, entry);
    } else {
      await _setUserSkillSetting(context, entry);
    }
  }
}

Future<void> _setAppSkillSetting(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
) async {
  final _ = await context.database.appSkillWorkspaceSettingsDao
      .setAppSkillEnabled(
        context.workspaceId,
        _string(entry.data, 'skillId'),
        isEnabled: _bool(entry.data, 'isEnabled'),
      );
}

Future<void> _setUserSkillSetting(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
) async {
  final _ =
      await (context.database.update(
        context.database.skills,
      )..where((row) => row.id.equals(_string(entry.data, 'skillId')))).write(
        SkillsCompanion(isEnabled: .new(_bool(entry.data, 'isEnabled'))),
      );
}

Future<void> _insertAgentLinks(_ImportContext context) async {
  await _insertAgentSkills(context);
  await _insertAgentToolPermissions(context);
}

Future<void> _insertAgentSkills(_ImportContext context) async {
  for (final entry in _entriesOfKind(context, .agentSkill)) {
    final _ = await context.database
        .into(context.database.agentSkills)
        .insert(_agentSkillCompanion(entry));
  }
}

AgentSkillsCompanion _agentSkillCompanion(WorkspaceConfigurationEntry entry) {
  final data = entry.data;
  final userSkill = data['source'] == 'user';

  return AgentSkillsCompanion.insert(
    id: .new(entry.id),
    agentId: _string(data, 'agentId'),
    workspaceSkillId: .new(userSkill ? _string(data, 'skillId') : null),
    appSkillIdentifier: .new(userSkill ? null : _string(data, 'skillId')),
  );
}

Future<void> _insertAgentToolPermissions(_ImportContext context) async {
  for (final entry in _entriesOfKind(context, .agentToolPermission)) {
    await _insertAgentToolPermission(context, entry);
  }
}

Future<void> _insertAgentToolPermission(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
) async {
  final toolId = context.toolIds[_string(entry.data, 'toolId')];
  if (toolId == null) {
    throw const WorkspaceConfigurationArchiveException(
      'workspace_archive.invalid',
    );
  }
  final _ = await context.database
      .into(context.database.agentTools)
      .insert(_agentToolCompanion(entry, toolId));
}

AgentToolsCompanion _agentToolCompanion(
  WorkspaceConfigurationEntry entry,
  String toolId,
) => AgentToolsCompanion.insert(
  id: .new(entry.id),
  agentId: _string(entry.data, 'agentId'),
  toolId: toolId,
  permissions: _localPermission(_string(entry.data, 'permissionMode')),
);

Future<void> _insertCompaction(_ImportContext context) async {
  final entry = _entriesOfKind(context, .compactionSetting).firstOrNull;
  if (entry == null) return;
  final _ = await context.database.workspaceCompactionSettingsDao.upsert(
    context.workspaceId,
    _compactionSettings(entry.data),
  );
}

WorkspaceCompactionSettingsCompanion _compactionSettings(
  Map<String, Object?> data,
) => WorkspaceCompactionSettingsCompanion(
  autoCompactEnabled: .new(_bool(data, 'autoCompactionEnabled')),
  usagePercentageThreshold: .new(_int(data, 'usagePercentageThreshold')),
  remainingTokenThreshold: .new(_int(data, 'remainingTokenThreshold')),
);

Iterable<WorkspaceConfigurationEntry> _entriesOfKind(
  _ImportContext context,
  WorkspaceConfigurationKind kind,
) => context.entries.where((entry) => entry.kind == kind);

String _unique(String value, Set<String> used) {
  var result = value;
  var index = 2;
  while (!used.add(result)) {
    result = '$value-$index';
    index++;
  }

  return result;
}

String _string(Map<String, Object?> data, String key) => switch (data[key]) {
  final String value => value,
  _ => throw const WorkspaceConfigurationArchiveException(
    'workspace_archive.invalid',
  ),
};

bool _bool(Map<String, Object?> data, String key) => switch (data[key]) {
  final bool value => value,
  _ => throw const WorkspaceConfigurationArchiveException(
    'workspace_archive.invalid',
  ),
};

int _int(Map<String, Object?> data, String key) => switch (data[key]) {
  final int value => value,
  _ => throw const WorkspaceConfigurationArchiveException(
    'workspace_archive.invalid',
  ),
};

PermissionAccess _localPermission(String mode) => switch (mode) {
  'alwaysAllow' => .granted,
  'alwaysDeny' => .denied,
  _ => .ask,
};
