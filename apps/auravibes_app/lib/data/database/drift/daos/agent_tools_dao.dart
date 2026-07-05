import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/agent_tools.dart';
import 'package:drift/drift.dart';

part 'agent_tools_dao.g.dart';

@DriftAccessor(tables: [AgentTools])
class AgentToolsDao extends DatabaseAccessor<AppDatabase>
    with _$AgentToolsDaoMixin {
  AgentToolsDao(super.attachedDatabase);

  Future<List<AgentToolsTable>> getAgentTools(String agentId) {
    return (select(agentTools)
          ..where((tbl) => tbl.agentId.equals(agentId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.toolId)]))
        .get();
  }

  Future<AgentToolsTable?> getAgentTool(String agentId, String toolId) {
    return (select(agentTools)..where(
          (tbl) => tbl.agentId.equals(agentId) & tbl.toolId.equals(toolId),
        ))
        .getSingleOrNull();
  }

  Future<AgentToolsTable> setAgentToolPermission(
    String agentId,
    String toolId, {
    required PermissionAccess permission,
  }) {
    return into(agentTools).insertReturning(
      AgentToolsCompanion(
        agentId: Value(agentId),
        toolId: Value(toolId),
        permissions: Value(permission),
      ),
      onConflict: DoUpdate(
        (old) => AgentToolsCompanion(
          updatedAt: Value(DateTime.now()),
          permissions: Value(permission),
        ),
        target: [agentTools.agentId, agentTools.toolId],
      ),
    );
  }

  Future<bool> clearAgentToolPermission(String agentId, String toolId) async {
    final count =
        await (delete(agentTools)..where(
              (tbl) => tbl.agentId.equals(agentId) & tbl.toolId.equals(toolId),
            ))
            .go();

    return count > 0;
  }
}
