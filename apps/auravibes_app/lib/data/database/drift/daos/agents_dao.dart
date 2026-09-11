import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/agent_skills.dart';
import 'package:auravibes_app/data/database/drift/tables/agents.dart';
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
