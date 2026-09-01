import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/agent_skills.dart';
import 'package:auravibes_app/data/database/drift/tables/agents.dart';
import 'package:drift/drift.dart';

part 'agents_dao.g.dart';

@DriftAccessor(tables: [Agents, AgentSkills])
class AgentsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$AgentsDaoMixin {
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
    return transaction(() async {
      final _ = await (update(
        agents,
      )..where((tbl) => tbl.id.equals(agentId))).write(agent);
      await _replaceSkills(agentId, skills);

      final updated = await getAgentById(agentId);
      if (updated == null) throw StateError('Updated agent was not found');

      return updated;
    });
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
    final _ = await (delete(
      agentSkills,
    )..where((tbl) => tbl.agentId.equals(agentId))).go();

    for (final skill in skills) {
      final _ = await into(agentSkills)
          .insert(skill.copyWith(agentId: Value(agentId)));
    }
  }
}
