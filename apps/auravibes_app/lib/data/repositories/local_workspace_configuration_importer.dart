import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/agent_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/skill_resources_dao.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/database/drift/tables/skills.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_configuration_archive.dart';
import 'package:drift/drift.dart';

class LocalWorkspaceConfigurationImporter(final AppDatabase _database) {
  Future<String> importJson(String json, {String? targetWorkspaceId}) =>
      Future.sync(() => _importArchiveJson(_database, json, targetWorkspaceId));
}

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
  final idMapping = await _archiveIdMapping(
    database,
    workspaceId,
    archive,
    targetWorkspaceId,
  );
  await _insertRemappedArchive(database, workspaceId, archive, idMapping);

  return workspaceId;
}

Future<Map<WorkspaceConfigurationArchiveEntryId, String>> _archiveIdMapping(
  AppDatabase database,
  String workspaceId,
  WorkspaceConfigurationArchive archive,
  String? targetWorkspaceId,
) => targetWorkspaceId == null
    ? Future.value(const {})
    : _existingEntryIds(database, workspaceId, archive);

Future<void> _insertRemappedArchive(
  AppDatabase database,
  String workspaceId,
  WorkspaceConfigurationArchive archive,
  Map<WorkspaceConfigurationArchiveEntryId, String> idMapping,
) async {
  final imported = WorkspaceConfigurationArchiveCodec.remapIds(
    archive,
    idMapping: idMapping,
  );
  await _insertEntries(database, workspaceId, imported.entries);
}

Future<String> _importArchiveJson(
  AppDatabase database,
  String json,
  String? targetWorkspaceId,
) {
  final archive = WorkspaceConfigurationArchiveCodec.decode(json);
  WorkspaceConfigurationArchiveCodec.validateNaturalIdentities(archive);

  return database.transaction(
    () => _importArchive(database, archive, targetWorkspaceId),
  );
}

typedef _ExistingArchiveEntryIdContext = ({
  AppDatabase database,
  String workspaceId,
  WorkspaceConfigurationArchive archive,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
});

Future<Map<WorkspaceConfigurationArchiveEntryId, String>> _existingEntryIds(
  AppDatabase database,
  String workspaceId,
  WorkspaceConfigurationArchive archive,
) async {
  final ids = <WorkspaceConfigurationArchiveEntryId, String>{};
  final context = (
    database: database,
    workspaceId: workspaceId,
    archive: archive,
    ids: ids,
  );
  await _mapBaseArchiveIds(context);
  await _mapDependentArchiveIds(context);

  return ids;
}

Future<void> _mapBaseArchiveIds(_ExistingArchiveEntryIdContext context) async {
  await _mapAgentIds(context);
  await _mapSkillIds(context);
  await _mapModelConnectionIds(context);
  await _mapToolIds(context);
}

Future<void> _mapAgentIds(_ExistingArchiveEntryIdContext context) async {
  final agents = await _workspaceAgents(context.database, context.workspaceId);
  for (final entry in _entriesOf(context.archive, .agent)) {
    final id = _existingAgentId(entry, agents);
    if (id != null) context.ids[(kind: entry.kind, id: entry.id)] = id;
  }
}

Future<List<AgentsTable>> _workspaceAgents(
  AppDatabase database,
  String workspaceId,
) => (database.select(
  database.agents,
)..where((row) => row.workspaceId.equals(workspaceId))).get();

String? _existingAgentId(
  WorkspaceConfigurationEntry entry,
  List<AgentsTable> agents,
) {
  final name = _string(entry.data, 'name').trim();

  return agents.where((row) => row.name.trim() == name).firstOrNull?.id;
}

Future<void> _mapSkillIds(_ExistingArchiveEntryIdContext context) async {
  final skills = await _workspaceSkills(context.database, context.workspaceId);
  for (final entry in _entriesOf(context.archive, .skill)) {
    final id = _existingSkillId(entry, skills);
    if (id != null) context.ids[(kind: entry.kind, id: entry.id)] = id;
  }
}

Future<List<SkillsTable>> _workspaceSkills(
  AppDatabase database,
  String workspaceId,
) => (database.select(
  database.skills,
)..where((row) => row.workspaceId.equals(workspaceId))).get();

String? _existingSkillId(
  WorkspaceConfigurationEntry entry,
  List<SkillsTable> skills,
) {
  final source = _string(entry.data, 'source');
  final slug = _string(entry.data, 'slug');

  return skills
      .where((row) => row.source.name == source && row.slug == slug)
      .firstOrNull
      ?.id;
}

Future<void> _mapModelConnectionIds(
  _ExistingArchiveEntryIdContext context,
) async {
  final connections = await _workspaceModelConnections(
    context.database,
    context.workspaceId,
  );
  for (final entry in _entriesOf(context.archive, .modelConnection)) {
    final id = _existingModelConnectionId(entry, connections);
    if (id != null) context.ids[(kind: entry.kind, id: entry.id)] = id;
  }
}

Future<List<ServiceConnectionTable>> _workspaceModelConnections(
  AppDatabase database,
  String workspaceId,
) =>
    (database.select(database.serviceConnections)..where(
          (row) =>
              row.workspaceId.equals(workspaceId) &
              row.kind.equals(ServiceConnectionKindTable.modelProvider.name),
        ))
        .get();

String? _existingModelConnectionId(
  WorkspaceConfigurationEntry entry,
  List<ServiceConnectionTable> connections,
) {
  final target = _modelConnectionTarget(entry);
  final match = connections
      .where((row) => _matchesModelConnection(row, target))
      .firstOrNull;

  return match?.id;
}

typedef _ModelConnectionIdentity = ({
  String providerId,
  String name,
  String? url,
});

_ModelConnectionIdentity _modelConnectionTarget(
  WorkspaceConfigurationEntry entry,
) {
  final data = entry.data;

  return (
    providerId: _string(data, 'providerId'),
    name: _string(data, 'name'),
    url: data['url'] as String?,
  );
}

bool _matchesModelConnection(
  ServiceConnectionTable row,
  _ModelConnectionIdentity target,
) =>
    row.serviceId == target.providerId &&
    row.name == target.name &&
    WorkspaceConfigurationArchiveCodec.publicUrl(row.url) == target.url;

Future<void> _mapToolIds(_ExistingArchiveEntryIdContext context) async {
  final tools = await _workspaceTools(context.database, context.workspaceId);
  for (final entry in _entriesOf(context.archive, .tool)) {
    final id = _existingToolId(entry, tools);
    if (id != null) context.ids[(kind: entry.kind, id: entry.id)] = id;
  }
}

Future<List<ToolsTable>> _workspaceTools(
  AppDatabase database,
  String workspaceId,
) =>
    (database.select(database.tools)..where(
          (row) =>
              row.workspaceId.equals(workspaceId) &
              row.workspaceToolsGroupId.isNull(),
        ))
        .get();

String? _existingToolId(
  WorkspaceConfigurationEntry entry,
  List<ToolsTable> tools,
) {
  final toolId = _string(entry.data, 'toolId');

  return tools.where((row) => row.toolId == toolId).firstOrNull?.id;
}

Future<void> _mapDependentArchiveIds(
  _ExistingArchiveEntryIdContext context,
) async {
  final agentIds = _mappedEntryIds(context.ids, .agent);
  final skillIds = _mappedEntryIds(context.ids, .skill);
  final connectionIds = _mappedEntryIds(context.ids, .modelConnection);
  await _mapAgentSkillIds(context, agentIds);
  await _mapAgentToolIds(context, agentIds);
  await _mapModelSelectionIds(context, connectionIds);
  await _mapSkillResourceIds(context, skillIds);
  await _mapAppSkillSettingIds(context);
}

Set<String> _mappedEntryIds(
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
  WorkspaceConfigurationKind kind,
) => ids.entries
    .where((entry) => entry.key.kind == kind)
    .map((entry) => entry.value)
    .toSet();

Future<void> _mapAgentSkillIds(
  _ExistingArchiveEntryIdContext context,
  Set<String> matchedAgentIds,
) async {
  if (matchedAgentIds.isEmpty) return;
  final rows = await _workspaceAgentSkills(context.database, matchedAgentIds);
  for (final entry in _entriesOf(context.archive, .agentSkill)) {
    final id = _existingAgentSkillId(entry, rows, context.ids);
    if (id != null) context.ids[(kind: entry.kind, id: entry.id)] = id;
  }
}

Future<List<AgentSkillsTable>> _workspaceAgentSkills(
  AppDatabase database,
  Set<String> agentIds,
) => (database.select(
  database.agentSkills,
)..where((row) => row.agentId.isIn(agentIds))).get();

String? _existingAgentSkillId(
  WorkspaceConfigurationEntry entry,
  List<AgentSkillsTable> rows,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final target = _agentSkillTarget(entry, ids);
  if (target.agentId == null || target.skillId == null) return null;

  return rows.where((row) => _matchesAgentSkill(row, target)).firstOrNull?.id;
}

bool _matchesAgentSkill(
  AgentSkillsTable row,
  ({String? agentId, String? skillId, String source}) target,
) =>
    row.agentId == target.agentId &&
    (target.source == 'user'
        ? row.workspaceSkillId == target.skillId
        : row.appSkillIdentifier == target.skillId);

({String? agentId, String? skillId, String source}) _agentSkillTarget(
  WorkspaceConfigurationEntry entry,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final data = entry.data;
  final source = _string(data, 'source');

  return (
    agentId: _mappedImportedArchiveId(ids, .agent, data, 'agentId'),
    skillId: _agentSkillId(ids, data, source),
    source: source,
  );
}

String? _mappedImportedArchiveId(
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
  WorkspaceConfigurationKind kind,
  Map<String, Object?> data,
  String key,
) => ids[(kind: kind, id: _string(data, key))];

String? _agentSkillId(
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
  Map<String, Object?> data,
  String source,
) {
  final skillId = _string(data, 'skillId');
  if (source != 'user') return skillId;

  return ids[(kind: WorkspaceConfigurationKind.skill, id: skillId)];
}

Future<void> _mapAgentToolIds(
  _ExistingArchiveEntryIdContext context,
  Set<String> matchedAgentIds,
) async {
  if (matchedAgentIds.isEmpty) return;
  final rows = await _workspaceAgentTools(context.database, matchedAgentIds);
  for (final entry in _entriesOf(context.archive, .agentToolPermission)) {
    final id = _existingAgentToolId(entry, rows, context.ids);
    if (id != null) context.ids[(kind: entry.kind, id: entry.id)] = id;
  }
}

Future<List<AgentToolsTable>> _workspaceAgentTools(
  AppDatabase database,
  Set<String> agentIds,
) => (database.select(
  database.agentTools,
)..where((row) => row.agentId.isIn(agentIds))).get();

String? _existingAgentToolId(
  WorkspaceConfigurationEntry entry,
  List<AgentToolsTable> rows,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final target = _agentToolTarget(entry, ids);
  final agentId = target.agentId;
  final toolId = target.toolId;
  if (agentId == null || toolId == null) return null;

  return rows.where((row) => _matchesAgentTool(row, target)).firstOrNull?.id;
}

({String? agentId, String? toolId}) _agentToolTarget(
  WorkspaceConfigurationEntry entry,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final data = entry.data;

  return (
    agentId:
        ids[(
          kind: WorkspaceConfigurationKind.agent,
          id: _string(data, 'agentId'),
        )],
    toolId:
        ids[(
          kind: WorkspaceConfigurationKind.tool,
          id: _string(data, 'toolId'),
        )],
  );
}

bool _matchesAgentTool(
  AgentToolsTable row,
  ({String? agentId, String? toolId}) target,
) => row.agentId == target.agentId && row.toolId == target.toolId;

Future<void> _mapModelSelectionIds(
  _ExistingArchiveEntryIdContext context,
  Set<String> matchedConnectionIds,
) async {
  if (matchedConnectionIds.isEmpty) return;
  final rows = await _workspaceModelSelections(
    context.database,
    matchedConnectionIds,
  );
  for (final entry in _entriesOf(context.archive, .modelSelection)) {
    final id = _existingModelSelectionId(entry, rows, context.ids);
    if (id != null) context.ids[(kind: entry.kind, id: entry.id)] = id;
  }
}

Future<List<WorkspaceModelSelectionTable>> _workspaceModelSelections(
  AppDatabase database,
  Set<String> connectionIds,
) => (database.select(
  database.workspaceModelSelections,
)..where((row) => row.modelConnectionId.isIn(connectionIds))).get();

String? _existingModelSelectionId(
  WorkspaceConfigurationEntry entry,
  List<WorkspaceModelSelectionTable> rows,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final target = _modelSelectionTarget(entry, ids);
  if (target.connectionId == null) return null;

  return rows
      .where((row) => _matchesModelSelection(row, target))
      .firstOrNull
      ?.id;
}

({String? connectionId, String modelId}) _modelSelectionTarget(
  WorkspaceConfigurationEntry entry,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final data = entry.data;

  return (
    connectionId:
        ids[(
          kind: WorkspaceConfigurationKind.modelConnection,
          id: _string(data, 'modelConnectionId'),
        )],
    modelId: _string(data, 'modelId'),
  );
}

bool _matchesModelSelection(
  WorkspaceModelSelectionTable row,
  ({String? connectionId, String modelId}) target,
) =>
    row.modelConnectionId == target.connectionId &&
    row.modelId == target.modelId;

Future<void> _mapSkillResourceIds(
  _ExistingArchiveEntryIdContext context,
  Set<String> matchedSkillIds,
) async {
  if (matchedSkillIds.isEmpty) return;
  final rows = await _workspaceSkillResources(
    context.database,
    matchedSkillIds,
  );
  for (final entry in _entriesOf(context.archive, .skillResource)) {
    final id = _existingSkillResourceId(entry, rows, context.ids);
    if (id != null) context.ids[(kind: entry.kind, id: entry.id)] = id;
  }
}

Future<List<SkillResourcesTable>> _workspaceSkillResources(
  AppDatabase database,
  Set<String> skillIds,
) => (database.select(
  database.skillResources,
)..where((row) => row.skillId.isIn(skillIds))).get();

String? _existingSkillResourceId(
  WorkspaceConfigurationEntry entry,
  List<SkillResourcesTable> rows,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final target = _skillResourceTarget(entry, ids);
  if (target.skillId == null) return null;

  return rows
      .where((row) => _matchesSkillResource(row, target))
      .firstOrNull
      ?.id;
}

({String? skillId, String slug}) _skillResourceTarget(
  WorkspaceConfigurationEntry entry,
  Map<WorkspaceConfigurationArchiveEntryId, String> ids,
) {
  final data = entry.data;

  return (
    skillId:
        ids[(
          kind: WorkspaceConfigurationKind.skill,
          id: _string(data, 'skillId'),
        )],
    slug: _string(data, 'slug'),
  );
}

bool _matchesSkillResource(
  SkillResourcesTable row,
  ({String? skillId, String slug}) target,
) => row.skillId == target.skillId && row.slug == target.slug;

Future<void> _mapAppSkillSettingIds(
  _ExistingArchiveEntryIdContext context,
) async {
  for (final entry in _entriesOf(context.archive, .skillSetting)) {
    if (entry.data['source'] != 'app') continue;
    final setting = await context.database.appSkillWorkspaceSettingsDao
        .getSetting(context.workspaceId, _string(entry.data, 'skillId'));
    if (setting != null) {
      context.ids[(kind: entry.kind, id: entry.id)] = setting.id;
    }
  }
}

Iterable<WorkspaceConfigurationEntry> _entriesOf(
  WorkspaceConfigurationArchive archive,
  WorkspaceConfigurationKind kind,
) => archive.entries.where((entry) => entry.kind == kind);

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
  await _insertModelSelections(context);
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
  final existing = await _existingSkill(context, entry.id);
  final identity = _importedSkillIdentity(entry, existing, names);
  final companion = _skillCompanion(
    context.workspaceId,
    entry,
    identity.title,
    identity.slug,
  );
  await _writeSkill(context, existing, companion);
  _trackSkillName(names, identity);
}

void _trackSkillName(
  _SkillNames names,
  ({String title, String slug}) identity,
) {
  final _ = names.titles.add(identity.title);
  final _ = names.slugs.add(identity.slug);
}

Future<SkillsTable?> _existingSkill(_ImportContext context, String skillId) =>
    (context.database.select(
      context.database.skills,
    )..where((row) => row.id.equals(skillId))).getSingleOrNull();

({String title, String slug}) _importedSkillIdentity(
  WorkspaceConfigurationEntry entry,
  SkillsTable? existing,
  _SkillNames names,
) {
  if (existing != null) {
    final _ = names.titles.remove(existing.title);
    final _ = names.slugs.remove(existing.slug);
  }

  return (
    title: _unique(_string(entry.data, 'title'), names.titles),
    slug: _unique(_string(entry.data, 'slug'), names.slugs),
  );
}

Future<void> _writeSkill(
  _ImportContext context,
  SkillsTable? existing,
  SkillsCompanion companion,
) async {
  if (existing == null) {
    await _insertSkillRow(context.database, companion);
  } else {
    await _updateSkillRow(context.database, existing.id, companion);
  }
}

Future<void> _insertSkillRow(
  AppDatabase database,
  SkillsCompanion companion,
) async {
  final _ = await database.into(database.skills).insert(companion);
}

Future<void> _updateSkillRow(
  AppDatabase database,
  String skillId,
  SkillsCompanion companion,
) async {
  final _ = await (database.update(
    database.skills,
  )..where((row) => row.id.equals(skillId))).write(companion);
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
    await _insertAgent(context, entry);
  }
}

Future<void> _insertAgent(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
) async {
  final existing = await _existingAgent(context.database, entry.id);
  if (existing == null) {
    await _createAgent(context, entry);

    return;
  }
  await _updateAgent(context.database, existing.id, _agentValues(entry));
}

Future<AgentsTable?> _existingAgent(AppDatabase database, String id) =>
    (database.select(
      database.agents,
    )..where((row) => row.id.equals(id))).getSingleOrNull();

Future<void> _createAgent(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
) async {
  final _ = await context.database
      .into(context.database.agents)
      .insert(_agentCompanion(context.workspaceId, entry));
}

Future<void> _updateAgent(
  AppDatabase database,
  String id,
  AgentsCompanion values,
) async {
  final _ = await (database.update(
    database.agents,
  )..where((row) => row.id.equals(id))).write(values);
}

AgentsCompanion _agentValues(WorkspaceConfigurationEntry entry) {
  final data = entry.data;

  return AgentsCompanion(
    name: .new(_string(data, 'name').trim()),
    description: .new(_string(data, 'description')),
    content: .new(_string(data, 'content')),
    isEnabled: .new(_bool(data, 'isEnabled')),
    visibility: .new(_string(data, 'visibility')),
  );
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
    await _insertModelConnection(context, entry);
  }
}

Future<void> _insertModelConnection(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
) async {
  if (await _modelConnectionExists(context.database, entry.id)) return;
  await _createModelConnection(context, entry);
}

Future<bool> _modelConnectionExists(AppDatabase database, String id) async =>
    await (database.select(
      database.serviceConnections,
    )..where((row) => row.id.equals(id))).getSingleOrNull() !=
    null;

Future<void> _createModelConnection(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
) async {
  final _ = await context.database.modelConnectionsDao.insertModelConnection(
    _modelConnectionCompanion(context.workspaceId, entry),
  );
}

Future<void> _insertModelSelections(_ImportContext context) async {
  for (final entry in _entriesOfKind(context, .modelSelection)) {
    await _insertModelSelection(context, entry);
  }
}

Future<void> _insertModelSelection(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
) async {
  final existing = await _existingModelSelection(context, entry);
  if (existing == null) {
    final _ = await context.database
        .into(context.database.workspaceModelSelections)
        .insert(_modelSelectionCompanion(entry));

    return;
  }
  final _ = await context.database.workspaceModelSelectionsDao
      .updateToolSamplingPolicy(
        existing.id,
        _string(entry.data, 'toolSamplingPolicy'),
      );
}

Future<WorkspaceModelSelectionTable?> _existingModelSelection(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
) =>
    (context.database.select(context.database.workspaceModelSelections)..where(
          (row) =>
              row.modelConnectionId.equals(
                _string(entry.data, 'modelConnectionId'),
              ) &
              row.modelId.equals(_string(entry.data, 'modelId')),
        ))
        .getSingleOrNull();

WorkspaceModelSelectionsCompanion _modelSelectionCompanion(
  WorkspaceConfigurationEntry entry,
) => WorkspaceModelSelectionsCompanion.insert(
  id: .new(entry.id),
  modelId: _string(entry.data, 'modelId'),
  modelConnectionId: _string(entry.data, 'modelConnectionId'),
  toolSamplingPolicy: .new(_string(entry.data, 'toolSamplingPolicy')),
);

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
    await _insertSkillResource(context, entry);
  }
}

Future<void> _insertSkillResource(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
) async {
  final database = context.database;
  final dao = database.skillResourcesDao;
  final data = entry.data;
  final skillId = _string(data, 'skillId');
  final slug = _string(data, 'slug');
  final existing = await dao.getResourceBySlug(skillId, slug);
  await _saveSkillResource(database, dao, entry, existing);
}

Future<void> _saveSkillResource(
  AppDatabase database,
  SkillResourcesDao dao,
  WorkspaceConfigurationEntry entry,
  SkillResourcesTable? existing,
) async {
  if (existing == null) {
    final _ = await database
        .into(database.skillResources)
        .insert(_skillResourceCompanion(entry));

    return;
  }
  final _ = await dao.updateResource(existing.id, _skillResourceValues(entry));
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

SkillResourcesCompanion _skillResourceValues(
  WorkspaceConfigurationEntry entry,
) => SkillResourcesCompanion(
  skillId: .new(_string(entry.data, 'skillId')),
  title: .new(_string(entry.data, 'title')),
  slug: .new(_string(entry.data, 'slug')),
  description: .new(_string(entry.data, 'description')),
  content: .new(_string(entry.data, 'content')),
);

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
    if (await _findAgentSkill(context, entry) != null) continue;
    final _ = await context.database
        .into(context.database.agentSkills)
        .insert(_agentSkillCompanion(entry));
  }
}

Future<AgentSkillsTable?> _findAgentSkill(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
) {
  if (entry.data['source'] == 'user') {
    return _findUserAgentSkill(
      context.database,
      _string(entry.data, 'agentId'),
      _string(entry.data, 'skillId'),
    );
  }

  return _findAppAgentSkill(
    context.database,
    _string(entry.data, 'agentId'),
    _string(entry.data, 'skillId'),
  );
}

Future<AgentSkillsTable?> _findUserAgentSkill(
  AppDatabase database,
  String agentId,
  String skillId,
) =>
    (database.select(database.agentSkills)..where(
          (row) =>
              row.agentId.equals(agentId) &
              row.workspaceSkillId.equals(skillId),
        ))
        .getSingleOrNull();

Future<AgentSkillsTable?> _findAppAgentSkill(
  AppDatabase database,
  String agentId,
  String skillId,
) =>
    (database.select(database.agentSkills)..where(
          (row) =>
              row.agentId.equals(agentId) &
              row.appSkillIdentifier.equals(skillId),
        ))
        .getSingleOrNull();

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
  final request = await _agentToolPermissionSaveRequest(context, entry);
  await _saveAgentToolPermission(request);
}

Future<_AgentToolPermissionSaveRequest> _agentToolPermissionSaveRequest(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
) async {
  final database = context.database;
  final dao = database.agentToolsDao;
  final toolId = _requiredImportedToolId(context, entry);
  final agentId = _string(entry.data, 'agentId');
  final existing = await dao.getAgentTool(agentId, toolId);

  return (
    database: database,
    dao: dao,
    entry: entry,
    agentId: agentId,
    toolId: toolId,
    existing: existing,
  );
}

typedef _AgentToolPermissionSaveRequest = ({
  AppDatabase database,
  AgentToolsDao dao,
  WorkspaceConfigurationEntry entry,
  String agentId,
  String toolId,
  AgentToolsTable? existing,
});

Future<void> _saveAgentToolPermission(
  _AgentToolPermissionSaveRequest request,
) async {
  if (request.existing == null) {
    final _ = await request.database
        .into(request.database.agentTools)
        .insert(_agentToolCompanion(request.entry, request.toolId));

    return;
  }
  final _ = await request.dao.setAgentToolPermission(
    request.agentId,
    request.toolId,
    permission: _localPermission(_string(request.entry.data, 'permissionMode')),
  );
}

String _requiredImportedToolId(
  _ImportContext context,
  WorkspaceConfigurationEntry entry,
) {
  final toolId = context.toolIds[_string(entry.data, 'toolId')];
  if (toolId == null) {
    throw const WorkspaceConfigurationArchiveException(
      'workspace_archive.invalid',
    );
  }

  return toolId;
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
