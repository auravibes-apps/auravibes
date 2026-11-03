import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/repositories/workspace_verification_reservations.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';

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
    if (!await isLocalVerificationWorkspace(database, workspaceId)) {
      return false;
    }
    final available = await tools(workspaceId);

    return _hasValidRunnerAndEdits(available, settings);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _query(String workspaceId) {
    final tools = database.tools;
    final groups = database.toolsGroups;
    final servers = database.mcpServers;

    return database.select(tools).join([
      innerJoin(groups, groups.id.equalsExp(tools.workspaceToolsGroupId)),
      innerJoin(servers, servers.id.equalsExp(groups.mcpServerId)),
    ])..where(_eligibleToolsWhere(workspaceId, tools, groups, servers));
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
    label: '${server.name}: ${tool.toolId}',
    canRunUnattended:
        tool.permissions == .granted && group.permissions == .granted,
  );
}

bool _hasValidRunnerAndEdits(
  List<ScopedVerificationToolOption> available,
  ScopedVerificationSettings settings,
) {
  final runner = _matchingRunner(available, settings);
  if (runner == null) return false;

  return _hasMatchingEditTools(available, settings.editToolIds, runner);
}

bool _hasMatchingEditTools(
  List<ScopedVerificationToolOption> available,
  Set<String> editToolIds,
  ScopedVerificationToolOption runner,
) =>
    editToolIds.isNotEmpty &&
    editToolIds.every(
      (id) => id != runner.id && _hasBoundEditTool(available, id, runner),
    );

bool _hasBoundEditTool(
  List<ScopedVerificationToolOption> available,
  String id,
  ScopedVerificationToolOption runner,
) => available.any((tool) => tool.id == id && tool.serverId == runner.serverId);

ScopedVerificationToolOption? _matchingRunner(
  List<ScopedVerificationToolOption> available,
  ScopedVerificationSettings settings,
) => available
    .where(
      (tool) =>
          tool.id == settings.runnerToolId &&
          tool.serverId == settings.mcpServerId &&
          tool.canRunUnattended,
    )
    .firstOrNull;

Expression<bool> _eligibleToolsWhere(
  String workspaceId,
  $ToolsTable tools,
  $ToolsGroupsTable groups,
  $McpServersTable servers,
) =>
    _workspaceMatch(workspaceId, tools, groups, servers) &
    _enabledResources(tools, groups, servers) &
    _permittedResources(tools, groups);

Expression<bool> _workspaceMatch(
  String workspaceId,
  $ToolsTable tools,
  $ToolsGroupsTable groups,
  $McpServersTable servers,
) =>
    tools.workspaceId.equals(workspaceId) &
    groups.workspaceId.equals(workspaceId) &
    servers.workspaceId.equals(workspaceId);

Expression<bool> _enabledResources(
  $ToolsTable tools,
  $ToolsGroupsTable groups,
  $McpServersTable servers,
) => tools.isEnabled & groups.isEnabled & servers.isEnabled;

Expression<bool> _permittedResources(
  $ToolsTable tools,
  $ToolsGroupsTable groups,
) =>
    tools.permissions.isNotValue(PermissionAccess.denied.name) &
    groups.permissions.isNotValue(PermissionAccess.denied.name);

class const ScopedVerificationToolOption({
  required final String id,
  required final String serverId,
  required final String toolIdentifier,
  required final String label,
  required final bool canRunUnattended,
});
