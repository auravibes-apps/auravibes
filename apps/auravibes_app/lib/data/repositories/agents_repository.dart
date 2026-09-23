import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/agent_list_query.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';

const _agentContentEmpty = 'Agent content cannot be empty';
const _agentDescriptionEmpty = 'Agent description cannot be empty';
const _agentDescriptionTooLong =
    'Agent description cannot exceed 512 characters';
const _agentNameEmpty = 'Agent name cannot be empty';
const _unknownAgentValidationError = 'Unknown validation error';

class AgentsRepository(final AppDatabase _database) implements AgentRepository {
  @override
  Stream<List<AgentEntity>> watchAgentsByWorkspace(String workspaceId) {
    return _database.agentsDao
        .watchAgentsByWorkspace(workspaceId)
        .asyncMap(_mapAgentRows);
  }

  @override
  Future<List<AgentEntity>> getAgentsByWorkspace(String workspaceId) async {
    final rows = await _database.agentsDao.getAgentsByWorkspace(workspaceId);

    return await _mapAgentRows(rows);
  }

  @override
  Future<AgentListPage> listAgents(AgentListQuery query) async {
    final normalized = _validateListQuery(query);
    final cursor = _decodeCursor(normalized);
    final page = await _loadAgentPage(_database, normalized, cursor);
    final skillCounts = await _agentSkillCounts(_database, page.rows);

    return _agentListPage(normalized, page, skillCounts);
  }

  @override
  Future<AgentEntity?> getAgentById(String agentId) async {
    final row = await _database.agentsDao.getAgentById(agentId);
    if (row == null) return null;

    return await _mapToAgent(row);
  }

  @override
  Future<AgentEntity> createAgent(
    String workspaceId,
    AgentToCreate agent,
  ) async {
    _validateAgentToCreate(agent);

    final created = await _database.agentsDao.createAgent(
      _agentToCreateCompanion(workspaceId, agent),
      _mapSkillRefsToCompanions(agent.skills),
    );

    return await _mapToAgent(created);
  }

  @override
  Future<AgentEntity> duplicateAgent(String agentId) =>
      _database.transaction(() => _duplicateAgent(agentId));

  @override
  Future<AgentEntity> updateAgent(String agentId, AgentToUpdate agent) async {
    _validateAgentToUpdate(agent);

    final updated = await _database.agentsDao.updateAgent(
      agentId,
      _agentToUpdateCompanion(agent),
      _mapSkillRefsToCompanions(agent.skills),
    );

    return await _mapToAgent(updated);
  }

  @override
  Future<AgentEntity> updateAgentVisibility(
    String agentId,
    AgentVisibility visibility,
  ) async {
    final updated = await _database.agentsDao.updateAgentVisibility(
      agentId,
      visibility.name,
    );

    return await _mapToAgent(updated);
  }

  @override
  Future<bool> deleteAgent(String agentId) =>
      _database.agentsDao.deleteAgent(agentId);
}

extension AgentsRepositoryDuplication on AgentsRepository {
  Future<AgentEntity> _duplicateAgent(String agentId) async {
    final source = await _sourceAgent(agentId);
    final created = await _createAgentCopy(source);
    await _copyToolOverrides(agentId, created.id);

    return await _mapToAgent(created);
  }

  Future<AgentEntity> _sourceAgent(String agentId) async {
    final source = await getAgentById(agentId);
    if (source == null) throw StateError('Agent not found: $agentId');

    return source;
  }

  Future<AgentsTable> _createAgentCopy(AgentEntity source) async {
    final agents = await getAgentsByWorkspace(source.workspaceId);
    final copy = _agentCopy(source, agents);

    return await _database.agentsDao.createAgent(
      _agentToCreateCompanion(source.workspaceId, copy),
      _mapSkillRefsToCompanions(source.skills),
    );
  }

  AgentToCreate _agentCopy(AgentEntity source, Iterable<AgentEntity> agents) =>
      AgentToCreate(
        name: _copyName(source.name, agents),
        description: source.description,
        content: source.content,
        isEnabled: source.isEnabled,
        visibility: source.visibility,
        skills: source.skills,
      );

  Future<void> _copyToolOverrides(String sourceId, String targetId) async {
    final overrides = await _database.agentToolsDao.getAgentTools(sourceId);
    for (final override in overrides) {
      final _ = await _database.agentToolsDao.setAgentToolPermission(
        targetId,
        override.toolId,
        permission: override.permissions,
      );
    }
  }
}

typedef _AgentListCursor = ({String name, String id});

AgentListQuery _validateListQuery(AgentListQuery query) {
  final search = query.search.trim().toLowerCase();
  if (_isInvalidListQuery(query, search)) {
    throw const AgentValidationException('Invalid agent list query');
  }

  return AgentListQuery(
    workspaceId: query.workspaceId,
    search: search,
    type: query.type,
    status: query.status,
    limit: query.limit,
    cursor: query.cursor,
  );
}

bool _isInvalidListQuery(AgentListQuery query, String search) =>
    query.workspaceId.isEmpty ||
    query.limit < 1 ||
    query.limit > 100 ||
    search.length > 200 ||
    (query.cursor?.length ?? 0) > 2048;

typedef _DecodedAgentListCursor = ({
  String workspaceId,
  String search,
  String? type,
  String? status,
  String name,
  String id,
});

_AgentListCursor? _decodeCursor(AgentListQuery query) {
  final value = query.cursor;
  if (value == null) return null;
  try {
    final cursor = _parseCursor(_decodeCursorValue(value));
    if (cursor != null && _cursorMatchesQuery(cursor, query)) {
      return (name: cursor.name, id: cursor.id);
    }
  } on FormatException {
    // Handled below as one typed validation failure.
  }
  throw const AgentValidationException('Invalid agent list cursor');
}

Object? _decodeCursorValue(String value) =>
    jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(value))));

_DecodedAgentListCursor? _parseCursor(Object? value) => switch (value) {
  {
    'v': 1,
    'workspace': final String workspaceId,
    'search': final String search,
    'type': final String? type,
    'status': final String? status,
    'name': final String name,
    'id': final String id,
  }
      when name.isNotEmpty && id.isNotEmpty =>
    (
      workspaceId: workspaceId,
      search: search,
      type: type,
      status: status,
      name: name,
      id: id,
    ),
  _ => null,
};

bool _cursorMatchesQuery(
  _DecodedAgentListCursor cursor,
  AgentListQuery query,
) =>
    cursor.workspaceId == query.workspaceId &&
    cursor.search == query.search &&
    cursor.type == query.type?.name &&
    cursor.status == query.status?.name;

Future<Map<String, int>> _agentSkillCounts(
  AppDatabase database,
  List<AgentsTable> rows,
) async {
  final skills = await database.agentsDao.getSkillsForAgents(
    rows.map((row) => row.id),
  );
  final counts = <String, int>{};
  for (final skill in skills) {
    _incrementCount(counts, skill.agentId);
  }

  return counts;
}

void _incrementCount(Map<String, int> counts, String agentId) {
  final _ = counts.update(agentId, (count) => count + 1, ifAbsent: () => 1);
}

Future<({List<AgentsTable> rows, bool hasMore})> _loadAgentPage(
  AppDatabase database,
  AgentListQuery query,
  _AgentListCursor? cursor,
) async {
  final rows = await database.agentsDao.listAgents(
    query: query,
    afterName: cursor?.name,
    afterId: cursor?.id,
  );

  return (
    rows: rows.take(query.limit).toList(),
    hasMore: rows.length > query.limit,
  );
}

AgentListPage _agentListPage(
  AgentListQuery query,
  ({List<AgentsTable> rows, bool hasMore}) page,
  Map<String, int> skillCounts,
) {
  final rows = page.rows;

  return AgentListPage(
    agents: _agentListItems(rows, skillCounts),
    nextCursor: page.hasMore && rows.isNotEmpty
        ? _encodeCursor(query, rows.last)
        : null,
  );
}

List<AgentListItem> _agentListItems(
  List<AgentsTable> rows,
  Map<String, int> skillCounts,
) => [
  for (final row in rows)
    AgentListItem(
      id: row.id,
      name: row.name,
      description: row.description,
      isEnabled: row.isEnabled,
      visibility: _agentVisibilityFromStorage(row.visibility),
      skillCount: skillCounts[row.id] ?? 0,
    ),
];

String _encodeCursor(AgentListQuery query, AgentsTable row) => base64Url.encode(
  utf8.encode(
    jsonEncode({
      'v': 1,
      'workspace': query.workspaceId,
      'search': query.search,
      'type': query.type?.name,
      'status': query.status?.name,
      'name': row.name.toLowerCase(),
      'id': row.id,
    }),
  ),
);

String _copyName(String originalName, Iterable<AgentEntity> agents) {
  final names = agents.map((agent) => agent.name).toSet();
  for (var suffix = 1; ; suffix++) {
    final name = suffix == 1
        ? '$originalName Copy'
        : '$originalName Copy $suffix';
    if (!names.contains(name)) return name;
  }
}

extension AgentsRepositoryValidation on AgentsRepository {
  void _validateAgentToCreate(AgentToCreate agent) {
    if (!agent.isValid) {
      throw AgentValidationException(_agentCreateValidationMessage(agent));
    }
  }

  String _agentCreateValidationMessage(AgentToCreate agent) {
    if (agent.name.trim().isEmpty) return _agentNameEmpty;
    if (agent.description.trim().isEmpty) return _agentDescriptionEmpty;
    if (agent.description.trim().length > AgentLimits.descriptionMaxLength) {
      return _agentDescriptionTooLong;
    }
    if (agent.content.trim().isEmpty) return _agentContentEmpty;

    return _unknownAgentValidationError;
  }

  void _validateAgentToUpdate(AgentToUpdate agent) {
    if (!agent.isValid) {
      throw AgentValidationException(_agentUpdateValidationMessage(agent));
    }
  }

  String _agentUpdateValidationMessage(AgentToUpdate agent) {
    if (agent.name.trim().isEmpty) return _agentNameEmpty;
    if (agent.description.trim().isEmpty) return _agentDescriptionEmpty;
    if (agent.description.trim().length > AgentLimits.descriptionMaxLength) {
      return _agentDescriptionTooLong;
    }

    if (agent.content.trim().isEmpty) return _agentContentEmpty;

    return _unknownAgentValidationError;
  }
}

extension AgentsRepositoryPersistence on AgentsRepository {
  Future<AgentEntity> _mapToAgent(AgentsTable table) async {
    final skills = await _database.agentsDao.getAgentSkills(table.id);

    return _mapAgentRow(table, skills);
  }

  Future<List<AgentEntity>> _mapAgentRows(List<AgentsTable> rows) async {
    final skills = await _database.agentsDao.getSkillsForAgents(
      rows.map((row) => row.id),
    );

    return _mapAgentRowsWithSkills(rows, skills);
  }

  List<AgentEntity> _mapAgentRowsWithSkills(
    List<AgentsTable> rows,
    List<AgentSkillsTable> skills,
  ) {
    final skillsByAgentId = <String, List<AgentSkillsTable>>{};
    for (final skill in skills) {
      skillsByAgentId.putIfAbsent(skill.agentId, () => []).add(skill);
    }

    return [
      for (final row in rows) _mapAgentRow(row, skillsByAgentId[row.id] ?? []),
    ];
  }

  AgentEntity _mapAgentRow(AgentsTable table, List<AgentSkillsTable> skills) {
    return _withAgentState((
      agent: _baseAgentEntity(table, skills),
      description: table.description,
      isEnabled: table.isEnabled,
      visibility: _agentVisibilityFromStorage(table.visibility),
    ));
  }

  AgentEntity _baseAgentEntity(
    AgentsTable table,
    List<AgentSkillsTable> skills,
  ) => _emptyAgentEntity.copyWith(
    id: table.id,
    workspaceId: table.workspaceId,
    name: table.name,
    content: table.content,
    skills: skills.map(_mapSkillRef).toList(),
    createdAt: table.createdAt,
    updatedAt: table.updatedAt,
  );

  AgentEntity _withAgentState(
    ({
      AgentEntity agent,
      String description,
      bool isEnabled,
      AgentVisibility visibility,
    })
    state,
  ) => state.agent.copyWith(
    description: state.description,
    isEnabled: state.isEnabled,
    visibility: state.visibility,
  );

  AgentSkillRef _mapSkillRef(AgentSkillsTable table) {
    final workspaceSkillId = table.workspaceSkillId;
    if (workspaceSkillId != null) return AgentSkillRef.user(workspaceSkillId);

    final appSkillIdentifier = table.appSkillIdentifier;
    if (appSkillIdentifier == null) throw StateError('Agent skill is invalid');

    return AgentSkillRef.app(appSkillIdentifier);
  }
}

AgentVisibility _agentVisibilityFromStorage(String value) =>
    AgentVisibility.values.asNameMap()[value] ?? AgentVisibility.both;

AgentsCompanion _agentToCreateCompanion(
  String workspaceId,
  AgentToCreate agent,
) => AgentsCompanion(
  workspaceId: .new(workspaceId),
  name: .new(agent.name.trim()),
  description: .new(agent.description.trim()),
  content: .new(agent.content.trim()),
  isEnabled: .new(agent.isEnabled),
  visibility: .new(agent.visibility.name),
);

AgentsCompanion _agentToUpdateCompanion(AgentToUpdate agent) => AgentsCompanion(
  updatedAt: .new(DateTime.now()),
  name: .new(agent.name.trim()),
  description: .new(agent.description.trim()),
  content: .new(agent.content.trim()),
  isEnabled: .new(agent.isEnabled),
  visibility: .new(agent.visibility.name),
);

List<AgentSkillsCompanion> _mapSkillRefsToCompanions(
  Iterable<AgentSkillRef> refs,
) => refs.map(_mapSkillRefToCompanion).toList();

AgentSkillsCompanion _mapSkillRefToCompanion(AgentSkillRef ref) {
  return switch (ref) {
    UserAgentSkillRef(:final skillId) => AgentSkillsCompanion(
      workspaceSkillId: .new(skillId),
    ),
    AppAgentSkillRef(:final identifier) => AgentSkillsCompanion(
      appSkillIdentifier: .new(identifier),
    ),
  };
}

final _emptyAgentEntity = AgentEntity(
  id: '',
  workspaceId: '',
  name: '',
  content: '',
  skills: const [],
  createdAt: .new(0),
  updatedAt: .new(0),
);

class const AgentException(final String message, [final Exception? cause])
    implements Exception {
  @override
  String toString() {
    final causedBy = ' (Caused by: ${cause.runtimeType})';

    return 'AgentException: $message${cause != null ? causedBy : ''}';
  }
}

class const AgentValidationException(super.message, [super.cause])
    extends AgentException;
