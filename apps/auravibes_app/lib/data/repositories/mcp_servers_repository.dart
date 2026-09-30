// Required: Existing test and UI helpers keep compact return flow.
import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/mcp_servers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/tools_groups_dao.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/database/drift/tables/mcp_servers.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/database/drift/tables/tools.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups.dart';
import 'package:auravibes_app/data/repositories/mcp_servers_repository_contract.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_connection_test_summary.dart';
import 'package:auravibes_app/domain/entities/mcp_server_settings_update.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:drift/drift.dart';

export 'mcp_servers_repository_contract.dart';

final _mcpServerTemplate = McpServerEntity(
  id: '',
  workspaceId: '',
  name: '',
  url: '',
  transport: const McpTransportTypeSSE(),
  authenticationType: const McpAuthenticationTypeNone(),
  createdAt: .new(0),
  updatedAt: .new(0),
);

class McpServersRepository implements McpServersRepositoryContract {
  /// Creates a new [McpServersRepository] instance.
  new(this._database, [this._serviceConnections])
    : _mcpServersDao = _database.mcpServersDao,
      _toolsGroupsDao = _database.toolsGroupsDao,
      _workspaceToolsDao = _database.workspaceToolsDao;

  final AppDatabase _database;
  final ServiceConnectionRepository? _serviceConnections;
  final McpServersDao _mcpServersDao;
  final ToolsGroupsDao _toolsGroupsDao;
  final WorkspaceToolsDao _workspaceToolsDao;

  @override
  Future<McpServerEntity> addMcpServerWithTools({
    required String workspaceId,
    required McpServerToCreate serverToCreate,
    required List<McpToolInfo> tools,
  }) async {
    try {
      // Use a transaction to ensure atomicity.
      return await _database.transaction(
        () => _addMcpServerWithTools(workspaceId, serverToCreate, tools),
      );
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        McpServersException('Failed to add MCP server with tools.', e),
        stackTrace,
      );
    }
  }

  @override
  Future<bool> deleteMcpServer(String serverId) async {
    try {
      return await _database.transaction(() => _deleteMcpServer(serverId));
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        McpServersException('Failed to delete MCP server.', e),
        stackTrace,
      );
    }
  }

  @override
  Future<void> syncMcpTools({
    required String mcpServerId,
    required List<McpToolInfo> currentTools,
  }) async {
    try {
      await _database.transaction(
        () => _syncMcpTools(mcpServerId, currentTools),
      );

      // Existing tool permissions and enablement remain unchanged.
    } on McpServerNotFoundException {
      rethrow;
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        McpServersException('Failed to sync MCP tools.', e),
        stackTrace,
      );
    }
  }

  @override
  Future<List<McpServerEntity>> getMcpServersForWorkspace(
    String workspaceId,
  ) async {
    try {
      final results = await _mcpServersDao.getMcpServersForWorkspace(
        workspaceId,
      );

      return results.map(_tableToEntity).toList();
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        McpServersException('Failed to get MCP servers for workspace.', e),
        stackTrace,
      );
    }
  }

  @override
  Future<List<McpServerEntity>> getEnabledMcpServersForWorkspace(
    String workspaceId,
  ) async {
    try {
      return await _getEnabledMcpServers(workspaceId);
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        McpServersException(
          'Failed to get enabled MCP servers for workspace.',
          e,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<McpServerEntity?> getMcpServerById(String serverId) async {
    try {
      final result = await _mcpServersDao.getMcpServerById(serverId);
      if (result == null) return null;

      return _tableToEntity(result);
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        McpServersException('Failed to get MCP server by ID.', e),
        stackTrace,
      );
    }
  }

  @override
  Future<void> saveMcpTestSummary({
    required String serverId,
    required McpConnectionTestSummary summary,
  }) async {
    final saved = await _mcpServersDao.saveTestSummary(
      serverId,
      summary.toJson(),
    );
    if (!saved) throw McpServerNotFoundException(serverId);
  }

  @override
  Future<void> updateMcpServerSettings(McpServerSettingsUpdate update) =>
      _updateMcpServerSettings(this, update);
}

typedef _McpServerSettingsMutation = ({
  McpServersRepository repository,
  McpServerEntity server,
  McpServerSettingsUpdate update,
  McpServerAuthMode currentAuthMode,
});

Future<void> _updateMcpServerSettings(
  McpServersRepository repository,
  McpServerSettingsUpdate update,
) async {
  final mutation = await _prepareMcpServerSettingsMutation(repository, update);
  await repository._database.transaction(
    () => _applyMcpServerSettings(mutation),
  );
}

Future<_McpServerSettingsMutation> _prepareMcpServerSettingsMutation(
  McpServersRepository repository,
  McpServerSettingsUpdate update,
) async {
  final server = await repository.getMcpServerById(update.serverId);
  if (server == null) throw McpServerNotFoundException(update.serverId);
  final currentAuthMode = await _localAuthMode(
    repository._serviceConnections,
    server.serviceConnectionId,
  );
  _validateMcpSettingsUpdate(update, currentAuthMode);

  return (
    repository: repository,
    server: server,
    update: update,
    currentAuthMode: currentAuthMode,
  );
}

Future<void> _applyMcpServerSettings(
  _McpServerSettingsMutation mutation,
) async {
  final identityChanged = _mcpSettingsAffectIdentity(mutation);
  final nextConnectionId = await _updateMcpCredential(mutation);
  await _writeMcpServerSettings(mutation, nextConnectionId, identityChanged);
  await _updateMcpToolGroup(mutation, identityChanged);
}

Future<void> _updateMcpToolGroup(
  _McpServerSettingsMutation mutation,
  bool identityChanged,
) async {
  final repository = mutation.repository;
  final group = await repository._toolsGroupsDao.getToolsGroupByMcpServerId(
    mutation.update.serverId,
  );
  if (group == null) return;
  await _updateMcpToolGroupName(repository, group, mutation.update);
  if (identityChanged) {
    await _resetMcpToolGroupPermissions(repository, group.id);
  }
}

bool _mcpSettingsAffectIdentity(_McpServerSettingsMutation mutation) {
  final server = mutation.server;
  final update = mutation.update;

  return server.url != update.url ||
      !_sameTransport(server.transport, update.transport) ||
      update.authMode != mutation.currentAuthMode ||
      update.secretChange != .preserve;
}

Future<String?> _updateMcpCredential(
  _McpServerSettingsMutation mutation,
) async {
  final connectionId = mutation.server.serviceConnectionId;
  final nextConnectionId = await _replaceMcpCredential(mutation, connectionId);
  await _markMcpOAuthReauthIfNeeded(mutation, connectionId);

  return nextConnectionId;
}

Future<String?> _replaceMcpCredential(
  _McpServerSettingsMutation mutation,
  String? connectionId,
) async {
  final update = mutation.update;
  if (update.secretChange == .preserve) return connectionId;

  return await _requiredServiceConnectionRepository(
    mutation.repository._serviceConnections,
  ).updateMcpAuthentication(
    connectionId: connectionId,
    workspaceId: mutation.server.workspaceId,
    name: update.name,
    authenticationType: _updatedAuthentication(update),
  );
}

Future<void> _markMcpOAuthReauthIfNeeded(
  _McpServerSettingsMutation mutation,
  String? connectionId,
) async {
  if (connectionId == null ||
      mutation.currentAuthMode != .oauth ||
      !_mcpSettingsAffectIdentity(mutation)) {
    return;
  }
  await _requiredServiceConnectionRepository(
    mutation.repository._serviceConnections,
  ).markReauthRequired(connectionId);
}

ServiceConnectionRepository _requiredServiceConnectionRepository(
  ServiceConnectionRepository? repository,
) {
  if (repository == null) {
    throw StateError('MCP credential repository is unavailable.');
  }

  return repository;
}

Future<void> _writeMcpServerSettings(
  _McpServerSettingsMutation mutation,
  String? connectionId,
  bool clearSummary,
) async {
  final update = mutation.update;
  final updatedServers = await _persistMcpServerSettings(
    mutation.repository,
    update,
    connectionId,
    clearSummary,
  );
  if (updatedServers != 1) {
    throw McpServerNotFoundException(update.serverId);
  }
}

Future<int> _persistMcpServerSettings(
  McpServersRepository repository,
  McpServerSettingsUpdate update,
  String? connectionId,
  bool clearSummary,
) =>
    (repository._database.update(repository._database.mcpServers)
          ..where((row) => row.id.equals(update.serverId)))
        .write(_mcpServerSettingsCompanion(update, connectionId, clearSummary));

McpServersCompanion _mcpServerSettingsCompanion(
  McpServerSettingsUpdate update,
  String? connectionId,
  bool clearSummary,
) => McpServersCompanion(
  updatedAt: .new(DateTime.now()),
  name: .new(update.name),
  url: .new(update.url),
  transport: .new(update.transport),
  serviceConnectionId: .new(connectionId),
  testSummaryJson: clearSummary ? const .new(null) : const .absent(),
);

Future<void> _updateMcpToolGroupName(
  McpServersRepository repository,
  ToolsGroupsTable group,
  McpServerSettingsUpdate update,
) async {
  if (group.name == update.name) return;
  final _ =
      await (repository._database.update(repository._database.toolsGroups)
            ..where((row) => row.id.equals(group.id)))
          .write(_toolsGroupNameCompanion(update.name));
}

ToolsGroupsCompanion _toolsGroupNameCompanion(String name) =>
    ToolsGroupsCompanion(updatedAt: .new(DateTime.now()), name: .new(name));

Future<void> _resetMcpToolGroupPermissions(
  McpServersRepository repository,
  String groupId,
) async {
  await _resetMcpToolGroupPermission(repository, groupId);
  await _resetMcpToolsPermissions(repository, groupId);
}

Future<void> _resetMcpToolGroupPermission(
  McpServersRepository repository,
  String groupId,
) async {
  final _ =
      await (repository._database.update(
        repository._database.toolsGroups,
      )..where((row) => row.id.equals(groupId))).write(
        const ToolsGroupsCompanion(permissions: .new(PermissionAccess.ask)),
      );
}

Future<void> _resetMcpToolsPermissions(
  McpServersRepository repository,
  String groupId,
) async {
  final _ =
      await (repository._database.update(
        repository._database.tools,
      )..where((row) => row.workspaceToolsGroupId.equals(groupId))).write(
        ToolsCompanion(
          updatedAt: .new(DateTime.now()),
          permissions: const .new(PermissionAccess.ask),
        ),
      );
}

bool _sameTransport(McpTransportType first, McpTransportType second) {
  if (first is McpTransportTypeSSE && second is McpTransportTypeSSE) {
    return true;
  }
  if (first is McpTransportTypeStreamableHttp &&
      second is McpTransportTypeStreamableHttp) {
    return first.useHttp2 == second.useHttp2;
  }

  return false;
}

Future<McpServerAuthMode> _localAuthMode(
  ServiceConnectionRepository? repository,
  String? connectionId,
) async {
  if (connectionId == null) return .none;
  if (repository == null) {
    throw StateError('MCP credential repository is unavailable.');
  }
  final secret = await repository.readSecret(connectionId);

  return switch (secret) {
    ServiceConnectionSecretBearerToken() ||
    ServiceConnectionSecretApiKey() => .bearerToken,
    ServiceConnectionSecretHttpHeaders() => .httpHeaders,
    ServiceConnectionSecretOAuth2() => .oauth,
  };
}

void _validateMcpSettingsUpdate(
  McpServerSettingsUpdate update,
  McpServerAuthMode currentAuthMode,
) {
  _validateMcpSettingsNameAndUrl(update);
  _validateMcpAuthTransition(update, currentAuthMode);
  _validateMcpSecretChange(update);
}

void _validateMcpSettingsNameAndUrl(McpServerSettingsUpdate update) {
  if (update.name.trim().isEmpty || update.url.trim().isEmpty) {
    throw const FormatException('MCP name and URL are required.');
  }
}

void _validateMcpAuthTransition(
  McpServerSettingsUpdate update,
  McpServerAuthMode currentAuthMode,
) {
  if (update.secretChange == .preserve && update.authMode != currentAuthMode) {
    throw const FormatException('New MCP authentication requires a secret.');
  }
  if (update.authMode == .oauth &&
      (update.secretChange != .preserve || currentAuthMode != .oauth)) {
    throw const FormatException('Use reconnect to configure MCP OAuth.');
  }
}

void _validateMcpSecretChange(McpServerSettingsUpdate update) {
  if (update.authMode == .none && update.secretChange == .replace) {
    throw const FormatException('MCP authentication secret is not required.');
  }
  if (update.secretChange == .clear && update.authMode != .none) {
    throw const FormatException(
      'MCP credentials can only be cleared with no authentication.',
    );
  }
  _validateReplacementMcpSecret(update);
}

void _validateReplacementMcpSecret(McpServerSettingsUpdate update) {
  if (update.secretChange != .replace ||
      update.authMode == .none ||
      update.authMode == .oauth) {
    return;
  }
  if (update.secret?.trim().isNotEmpty != true) {
    throw const FormatException('MCP authentication secret is required.');
  }
}

McpAuthenticationType _updatedAuthentication(McpServerSettingsUpdate update) {
  if (update.secretChange == .clear) return const McpAuthenticationType.none();
  final secret = update.secret;
  if (secret == null || secret.isEmpty) {
    throw const FormatException('MCP authentication secret is required.');
  }

  return switch (update.authMode) {
    .none => const .none(),
    .bearerToken => McpAuthenticationType.bearerToken(bearerToken: secret),
    .httpHeaders => McpAuthenticationType.httpHeaders(
      headers: _decodeHeaders(secret),
    ),
    .oauth => throw const FormatException(
      'Use reconnect to configure MCP OAuth.',
    ),
  };
}

Map<String, String> _decodeHeaders(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (_, stackTrace) {
    Error.throwWithStackTrace(
      const FormatException('MCP headers must be valid JSON.'),
      stackTrace,
    );
  }
  if (decoded is! Map<String, dynamic> || decoded.isEmpty) {
    throw const FormatException('MCP headers must be a non-empty object.');
  }

  return _validatedMcpHeaders(decoded);
}

Map<String, String> _validatedMcpHeaders(Map<String, dynamic> decoded) => {
  for (final entry in decoded.entries)
    entry.key: _requiredMcpHeaderValue(entry.value),
};

String _requiredMcpHeaderValue(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value;
  throw const FormatException('MCP header values must be non-empty text.');
}

extension McpServersRepositoryOperations on McpServersRepository {
  Future<List<McpServerEntity>> _getEnabledMcpServers(
    String workspaceId,
  ) async {
    final servers = await _mcpServersDao.getEnabledMcpServersForWorkspace(
      workspaceId,
    );
    final enabledServers = <McpServersTable>[];

    for (final server in servers) {
      final group = await _toolsGroupsDao.getToolsGroupByMcpServerId(server.id);
      if (group?.isEnabled ?? false) enabledServers.add(server);
    }

    return enabledServers.map(_tableToEntity).toList();
  }

  Future<McpServersTable> _insertMcpServer(
    String workspaceId,
    McpServerToCreate serverToCreate,
  ) {
    return _mcpServersDao.insertMcpServer(
      .insert(
        workspaceId: workspaceId,
        name: serverToCreate.name,
        url: serverToCreate.url,
        transport: serverToCreate.transport,
        serviceConnectionId: Value(serverToCreate.serviceConnectionId),
        description: Value(serverToCreate.description),
        catalogSnapshotJson: Value(serverToCreate.catalogSnapshotJson),
      ),
    );
  }

  Future<McpServerEntity> _addMcpServerWithTools(
    String workspaceId,
    McpServerToCreate serverToCreate,
    List<McpToolInfo> tools,
  ) async {
    final mcpServer = await _insertMcpServer(workspaceId, serverToCreate);
    final toolsGroup = await _insertToolsGroup(mcpServer, serverToCreate);
    await _insertTools(workspaceId, toolsGroup.id, tools);

    return _tableToEntity(mcpServer);
  }

  Future<bool> _deleteMcpServer(String serverId) async {
    final server = await _mcpServersDao.getMcpServerById(serverId);
    if (server == null) return false;

    final deleted = await _mcpServersDao.deleteMcpServer(serverId);
    await _deleteServiceConnection(server, deleted);

    return deleted;
  }

  Future<void> _deleteServiceConnection(
    McpServersTable server,
    bool serverDeleted,
  ) async {
    final serviceConnectionId = server.serviceConnectionId;
    if (!serverDeleted || serviceConnectionId == null) return;

    await _deleteServiceConnectionById(serviceConnectionId);
  }

  Future<void> _deleteServiceConnectionById(String serviceConnectionId) async {
    final statement = _database.delete(_database.serviceConnections)
      ..where((tbl) => _isMcpServiceConnection(tbl, serviceConnectionId));
    final _ = await statement.go();
  }

  Expression<bool> _isMcpServiceConnection(
    ServiceConnections table,
    String serviceConnectionId,
  ) {
    return table.id.equals(serviceConnectionId) &
        table.kind.equals(ServiceConnectionKindTable.mcpServer.name);
  }

  Future<void> _syncMcpTools(
    String mcpServerId,
    List<McpToolInfo> currentTools,
  ) async {
    final group = await _toolsGroupsDao.getToolsGroupByMcpServerId(mcpServerId);
    if (group == null) throw McpServerNotFoundException(mcpServerId);

    await _syncToolsForGroup(group, currentTools);
  }
}

extension on McpServersRepository {
  Future<ToolsGroupsTable> _insertToolsGroup(
    McpServersTable server,
    McpServerToCreate serverToCreate,
  ) {
    return _toolsGroupsDao.insertToolsGroup(
      .insert(
        workspaceId: server.workspaceId,
        mcpServerId: Value(server.id),
        name: serverToCreate.name,
        permissions: PermissionAccess.ask,
      ),
    );
  }

  Future<void> _insertTools(
    String workspaceId,
    String toolsGroupId,
    List<McpToolInfo> tools,
  ) async {
    if (tools.isEmpty) return;

    await _workspaceToolsDao.insertToolsBatch(
      _toolCompanions(workspaceId, toolsGroupId, tools),
    );
  }

  List<ToolsCompanion> _toolCompanions(
    String workspaceId,
    String toolsGroupId,
    List<McpToolInfo> tools,
  ) {
    return tools
        .map((tool) => _toolCompanion(workspaceId, toolsGroupId, tool))
        .toList();
  }

  ToolsCompanion _toolCompanion(
    String workspaceId,
    String toolsGroupId,
    McpToolInfo tool,
  ) {
    return ToolsCompanion.insert(
      workspaceId: workspaceId,
      workspaceToolsGroupId: .new(toolsGroupId),
      toolId: tool.toolName,
      description: .new(tool.description),
      inputSchema: .new(jsonEncode(tool.inputSchema)),
      outputSchema: .new(
        tool.outputSchema == null ? null : jsonEncode(tool.outputSchema),
      ),
      isEnabled: const Value(true),
      permissions: const Value(PermissionAccess.ask),
    );
  }

  Future<void> _syncToolsForGroup(
    ToolsGroupsTable group,
    List<McpToolInfo> currentTools,
  ) async {
    final existingTools = await _workspaceToolsDao.getToolsByGroupId(group.id);
    final toolsToAdd = _toolsToAdd(existingTools, currentTools);
    final toolsToRemove = _toolsToRemove(existingTools, currentTools);
    await _updateExistingToolMetadata(existingTools, currentTools);

    await _insertTools(group.workspaceId, group.id, toolsToAdd);
    await _removeTools(toolsToRemove);
  }

  Future<void> _updateExistingToolMetadata(
    List<ToolsTable> existingTools,
    List<McpToolInfo> currentTools,
  ) async {
    final currentById = {for (final tool in currentTools) tool.toolName: tool};

    for (final existing in existingTools) {
      final current = currentById[existing.toolId];
      if (current == null) continue;
      await _updateToolMetadata(existing, current);
    }
  }

  Future<void> _updateToolMetadata(
    ToolsTable existing,
    McpToolInfo current,
  ) async {
    final schemas = _serializedToolSchemas(current);
    if (_hasCurrentToolMetadata(existing, current, schemas)) return;
    await _workspaceToolsDao.updateToolMetadata(
      id: existing.id,
      description: current.description,
      inputSchema: schemas.inputSchema,
      outputSchema: .new(schemas.outputSchema),
    );
  }

  ({String inputSchema, String? outputSchema}) _serializedToolSchemas(
    McpToolInfo tool,
  ) => (
    inputSchema: jsonEncode(tool.inputSchema),
    outputSchema: tool.outputSchema == null
        ? null
        : jsonEncode(tool.outputSchema),
  );

  bool _hasCurrentToolMetadata(
    ToolsTable existing,
    McpToolInfo current,
    ({String inputSchema, String? outputSchema}) schemas,
  ) =>
      existing.description == current.description &&
      existing.inputSchema == schemas.inputSchema &&
      existing.outputSchema == schemas.outputSchema;

  List<McpToolInfo> _toolsToAdd(
    List<ToolsTable> existingTools,
    List<McpToolInfo> currentTools,
  ) {
    final existingToolIds = existingTools.map((tool) => tool.toolId).toSet();

    return currentTools
        .where((tool) => !existingToolIds.contains(tool.toolName))
        .toList();
  }

  List<ToolsTable> _toolsToRemove(
    List<ToolsTable> existingTools,
    List<McpToolInfo> currentTools,
  ) {
    final currentToolIds = currentTools.map((tool) => tool.toolName).toSet();

    return existingTools
        .where((tool) => !currentToolIds.contains(tool.toolId))
        .toList();
  }

  Future<void> _removeTools(List<ToolsTable> tools) async {
    for (final tool in tools) {
      final _ = await _workspaceToolsDao.deleteWorkspaceToolById(tool.id);
    }
  }
}

extension on McpServersRepository {
  /// Convert a database table row to an entity.
  McpServerEntity _tableToEntity(McpServersTable table) {
    return _copyServerDetails(table);
  }

  McpServerEntity _copyServerDetails(McpServersTable table) {
    return _copyServerDates(
      _mcpServerTemplate.copyWith(
        id: table.id,
        workspaceId: table.workspaceId,
        name: table.name,
        url: table.url,
        transport: table.transport,
      ),
      table,
    );
  }

  McpServerEntity _copyServerDates(
    McpServerEntity entity,
    McpServersTable table,
  ) {
    return entity.copyWith(
      createdAt: table.createdAt,
      updatedAt: table.updatedAt,
      serviceConnectionId: table.serviceConnectionId,
      description: table.description,
      catalogSnapshotJson: table.catalogSnapshotJson,
      lastTestSummary: McpConnectionTestSummary.fromJson(table.testSummaryJson),
      isEnabled: table.isEnabled,
    );
  }
}

/// Base exception for MCP servers-related operations.
class McpServersException implements Exception {
  // Cause is optional because not all domain failures wrap an exception.
  // ignore: unnecessary-nullable
  /// Creates a new McpServersException.
  const new(this.message, [this.cause]);

  /// Error message describing the exception.
  final String message;

  /// Optional original exception that caused this exception.
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: ${cause.runtimeType})' : '';

    return 'McpServersException: $message$causedBy';
  }
}

/// Exception thrown when an MCP server is not found.
class McpServerNotFoundException extends McpServersException {
  /// Creates a new McpServerNotFoundException.
  const new(this.serverId, [Exception? cause])
    : super('MCP server "$serverId" not found', cause);

  /// ID of the MCP server that was not found.
  final String serverId;

  @override
  String toString() => StringBuffer(super.toString()).toString();
}
