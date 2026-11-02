import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/repositories/workspace_verification_reservations.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';

class const ScopedVerificationToolOption({
  required final String id,
  required final String serverId,
  required final String toolIdentifier,
  required final String label,
  required final bool canRunUnattended,
});

/// Only enabled, permitted tools owned by the route's local workspace.
class const ScopedVerificationConfiguration(final AppDatabase database) {
  Stream<List<ScopedVerificationToolOption>> watchTools(String workspaceId) =>
      _query(workspaceId).watch().map(_options);

  Future<List<ScopedVerificationToolOption>> tools(String workspaceId) async =>
      _options(await _query(workspaceId).get());

  Future<bool> validate(
    String workspaceId,
    ScopedVerificationSettings settings,
  ) async {
    if (!await isLocalVerificationWorkspace(database, workspaceId))
      return false;
    final available = await tools(workspaceId);
    final runner = available
        .where(
          (tool) =>
              tool.id == settings.runnerToolId &&
              tool.serverId == settings.mcpServerId &&
              tool.canRunUnattended,
        )
        .firstOrNull;
    if (runner == null) return false;
    return settings.editToolIds.isNotEmpty &&
        settings.editToolIds.every(
          (id) =>
              id != runner.id &&
              available.any(
                (tool) => tool.id == id && tool.serverId == runner.serverId,
              ),
        );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _query(String workspaceId) {
    final tools = database.tools;
    final groups = database.toolsGroups;
    final servers = database.mcpServers;
    return database.select(tools).join([
      innerJoin(groups, groups.id.equalsExp(tools.workspaceToolsGroupId)),
      innerJoin(servers, servers.id.equalsExp(groups.mcpServerId)),
    ])..where(
      tools.workspaceId.equals(workspaceId) &
          groups.workspaceId.equals(workspaceId) &
          servers.workspaceId.equals(workspaceId) &
          tools.isEnabled &
          groups.isEnabled &
          servers.isEnabled &
          tools.permissions.isNotValue(PermissionAccess.denied.name) &
          groups.permissions.isNotValue(PermissionAccess.denied.name),
    );
  }

  List<ScopedVerificationToolOption> _options(List<TypedResult> rows) =>
      List.unmodifiable([
        for (final row in rows)
          _option(
            row.readTable(database.tools),
            row.readTable(database.toolsGroups),
            row.readTable(database.mcpServers),
          ),
      ]);

  ScopedVerificationToolOption _option(
    ToolsTable tool,
    ToolsGroupsTable group,
    McpServersTable server,
  ) => ScopedVerificationToolOption(
    id: tool.id,
    serverId: server.id,
    toolIdentifier: tool.toolId,
    label: '${server.name} · ${tool.toolId}',
    canRunUnattended:
        tool.permissions == .granted && group.permissions == .granted,
  );
}
