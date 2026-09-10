import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/agent_tools.dart';
import 'package:drift/drift.dart';

part 'agent_tools_dao.g.dart';

@DriftAccessor(tables: [AgentTools])
class AgentToolsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$AgentToolsDaoMixin {
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
  }) => _setAgentToolPermission((agentId: agentId, toolId: toolId), permission);

  Future<bool> clearAgentToolPermission(String agentId, String toolId) async {
    final count =
        await (delete(agentTools)..where(
              (tbl) => tbl.agentId.equals(agentId) & tbl.toolId.equals(toolId),
            ))
            .go();

    return count > 0;
  }

  Future<AgentToolsTable> _setAgentToolPermission(
    ({String agentId, String toolId}) ids,
    PermissionAccess permission,
  ) => _insertAgentTool(
    _permissionCompanion(ids.agentId, ids.toolId, permission),
  );

  Future<AgentToolsTable> _insertAgentTool(AgentToolsCompanion companion) =>
      into(
        agentTools,
      ).insertReturning(companion, onConflict: _permissionConflict(companion));

  DoUpdate<$AgentToolsTable, AgentToolsTable> _permissionConflict(
    AgentToolsCompanion companion,
  ) => DoUpdate(
    (_) => companion.copyWith(updatedAt: .new(DateTime.now())),
    target: [agentTools.agentId, agentTools.toolId],
  );

  AgentToolsCompanion _permissionCompanion(
    String agentId,
    String toolId,
    PermissionAccess permission,
  ) => AgentToolsCompanion(
    agentId: .new(agentId),
    toolId: .new(toolId),
    permissions: .new(permission),
  );
}
