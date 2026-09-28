import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/agent_skills.dart';
import 'package:auravibes_app/data/database/drift/tables/agents.dart';
import 'package:auravibes_app/domain/entities/agent_list_query.dart';
import 'package:drift/drift.dart';

part 'agents_dao.g.dart';

@DriftAccessor(tables: [Agents, AgentSkills])
class AgentsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$AgentsDaoMixin;

extension AgentsDaoReadOperations on AgentsDao {
  Stream<List<AgentsTable>> watchAgentsByWorkspace(String workspaceId) =>
      (select(agents)
            ..where((tbl) => tbl.workspaceId.equals(workspaceId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
          .watch();

  Future<List<AgentsTable>> getAgentsByWorkspace(String workspaceId) =>
      (select(agents)
            ..where((tbl) => tbl.workspaceId.equals(workspaceId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
          .get();

  Future<List<AgentsTable>> listAgents({
    required AgentListQuery query,
    required String? afterName,
    required String? afterId,
  }) =>
      (select(agents)
            ..where(
              (table) => _agentListPredicate(table, query, afterName, afterId),
            )
            ..orderBy([_orderAgentName, _orderAgentId])
            ..limit(query.limit + 1))
          .get();

  Future<AgentsTable?> getAgentById(String agentId) => (select(
    agents,
  )..where((tbl) => tbl.id.equals(agentId))).getSingleOrNull();

  Future<List<AgentSkillsTable>> getAgentSkills(String agentId) =>
      (select(agentSkills)..where((tbl) => tbl.agentId.equals(agentId))).get();

  Future<List<AgentSkillsTable>> getSkillsForAgents(Iterable<String> agentIds) {
    final ids = agentIds.toList();
    if (ids.isEmpty) return Future.value(const []);

    return (select(agentSkills)..where((tbl) => tbl.agentId.isIn(ids))).get();
  }
}

Expression<bool> _agentListPredicate(
  Agents table,
  AgentListQuery query,
  String? afterName,
  String? afterId,
) =>
    table.workspaceId.equals(query.workspaceId) &
    _agentSearchPredicate(table, query.search) &
    _agentTypePredicate(table, query.type) &
    _agentStatusPredicate(table, query.status) &
    _agentCursorPredicate(table, afterName, afterId);

Expression<bool> _agentSearchPredicate(Agents table, String search) {
  if (search.isEmpty) return const Constant(true);
  final pattern = '%${_escapeLike(search)}%';

  return table.name.like(pattern, escapeChar: r'\') |
      table.description.like(pattern, escapeChar: r'\');
}

Expression<bool> _agentTypePredicate(Agents table, AgentListType? type) =>
    switch (type) {
      .chatSelector => table.visibility.isIn(['chatSelector', 'both']),
      .subAgentList => table.visibility.isIn(['subAgentList', 'both']),
      null => const Constant(true),
    };

Expression<bool> _agentStatusPredicate(Agents table, AgentListStatus? status) =>
    switch (status) {
      .enabled => table.isEnabled.equals(true),
      .disabled => table.isEnabled.equals(false),
      null => const Constant(true),
    };

Expression<bool> _agentCursorPredicate(
  Agents table,
  String? afterName,
  String? afterId,
) {
  if (afterName == null || afterId == null) return const Constant(true);
  final orderedName = table.name.collate(.noCase);

  return orderedName.isBiggerThanValue(afterName) |
      orderedName.equals(afterName) & table.id.isBiggerThanValue(afterId);
}

String _escapeLike(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

OrderingTerm _orderAgentName(Agents table) =>
    OrderingTerm(expression: table.name.collate(.noCase));

OrderingTerm _orderAgentId(Agents table) => OrderingTerm(expression: table.id);

extension AgentsDaoWriteOperations on AgentsDao {
  Future<AgentsTable> createAgent(
    AgentsCompanion agent,
    List<AgentSkillsCompanion> skills,
  ) {
    return transaction(() async {
      final created = await into(agents).insertReturning(agent);
      await _replaceSkills(created.id, skills);

      return created;
    });
  }

  Future<AgentsTable> updateAgent(
    String agentId,
    AgentsCompanion agent,
    List<AgentSkillsCompanion> skills,
  ) {
    return transaction(() => _updateAgent(agentId, agent, skills));
  }

  Future<AgentsTable> updateAgentVisibility(
    String agentId,
    String visibility,
  ) async {
    final _ = await _writeAgent(agentId, .new(visibility: .new(visibility)));

    return await _requireAgent(agentId);
  }

  Future<AgentsTable> _updateAgent(
    String agentId,
    AgentsCompanion agent,
    List<AgentSkillsCompanion> skills,
  ) async {
    final _ = await _writeAgent(agentId, agent);
    final _ = await _replaceSkills(agentId, skills);

    return await _requireAgent(agentId);
  }

  Future<bool> deleteAgent(String agentId) async {
    final count = await (delete(
      agents,
    )..where((tbl) => tbl.id.equals(agentId))).go();

    return count > 0;
  }

  Future<void> _replaceSkills(
    String agentId,
    List<AgentSkillsCompanion> skills,
  ) async {
    final _ = await _deleteSkills(agentId);
    for (final skill in skills) {
      final _ = await _insertSkill(agentId, skill);
    }
  }
}

extension AgentsDaoPersistence on AgentsDao {
  Future<int> _writeAgent(String id, AgentsCompanion agent) =>
      (update(agents)..where((tbl) => tbl.id.equals(id))).write(agent);

  Future<AgentsTable> _requireAgent(String id) async =>
      await getAgentById(id) ??
      (throw StateError('Updated agent was not found'));

  Future<int> _deleteSkills(String id) =>
      (delete(agentSkills)..where((tbl) => tbl.agentId.equals(id))).go();

  Future<int> _insertSkill(String id, AgentSkillsCompanion skill) =>
      into(agentSkills).insert(skill.copyWith(agentId: .new(id)));
}
