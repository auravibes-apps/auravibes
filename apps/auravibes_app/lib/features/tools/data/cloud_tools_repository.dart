import 'dart:convert';

import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/data/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_connection_test_summary.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/features/service_connections/models/mcp_server_for_edit.dart';
import 'package:auravibes_app/features/tools/services/cloud_mcp_gateway.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/tools/native_tool_service.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

abstract class _CloudToolsRepositoryBase {
  new(this._gatewayFuture)
    : _resourceStore = CloudWorkspaceResourceStore.deferred(_gatewayFuture),
      _readState = null,
      _patchState = null,
      _create = null,
      _verify = null,
      _delete = null,
      _discover = null;

  new _forTesting({
    required this._readState,
    required this._patchState,
    required this._create,
    required this._verify,
    required this._delete,
    required this._discover,
  }) : _gatewayFuture = Future.value(),
       _resourceStore = null;

  final Future<CloudWorkspaceStateGateway?> _gatewayFuture;
  final CloudWorkspaceResourceStore? _resourceStore;
  final Future<ReadWorkspaceStateResponse> Function({
    required List<WorkspaceResourcePageRequest> pages,
  })?
  _readState;
  final Future<PatchWorkspaceStateResponse> Function({
    required String requestId,
    required List<WorkspacePatchOperation> operations,
  })?
  _patchState;
  final Future<CreateMcpServerResult> Function({
    required String requestId,
    required String name,
    required String url,
    required String transport,
    required bool useHttp2,
    required String? description,
    required String? bearerToken,
    required String? verificationReceipt,
  })?
  _create;
  final Future<VerifyMcpServerResult> Function({
    required String requestId,
    required String url,
    required String transport,
    required bool useHttp2,
    required String? bearerToken,
  })?
  _verify;
  final Future<void> Function({required String mcpServerId})? _delete;
  final Future<DiscoverMcpServerResult> Function({required String mcpServerId})?
  _discover;

  Future<CloudWorkspaceStateGateway> get _gateway async =>
      await _gatewayFuture ??
      (throw const CloudAppException(
        localizationKey: LocaleKeys.cloud_errors_unavailable,
        context: .state,
        code: 'gatewayUnavailable',
      ));

  CloudWorkspaceResourceStore get _requiredResourceStore =>
      _resourceStore ??
      (throw StateError('Cloud workspace resource store unavailable'));

  Future<List<WorkspaceToolEntity>> getWorkspaceTools(String workspaceId);

  Future<DiscoverMcpServerResult> discoverMcpServer(String mcpServerId);

  Future<bool> removeMcpServer(String? mcpServerId);
}

class CloudToolsRepository extends _CloudToolsRepositoryBase
    with
        _WorkspaceToolOperations,
        _McpServerOperations,
        _McpServerSettingsOperations,
        _ToolsGroupOperations
    implements
        WorkspaceToolsRepositoryContract,
        ToolsGroupsRepositoryContract,
        McpServersRepositoryContract {
  new(super._gatewayFuture);

  new forTesting({
    required Future<ReadWorkspaceStateResponse> Function({
      required List<WorkspaceResourcePageRequest> pages,
    })
    read,
    required Future<PatchWorkspaceStateResponse> Function({
      required String requestId,
      required List<WorkspacePatchOperation> operations,
    })
    patch,
    required Future<CreateMcpServerResult> Function({
      required String requestId,
      required String name,
      required String url,
      required String transport,
      required bool useHttp2,
      required String? description,
      required String? bearerToken,
      required String? verificationReceipt,
    })
    create,
    required Future<VerifyMcpServerResult> Function({
      required String requestId,
      required String url,
      required String transport,
      required bool useHttp2,
      required String? bearerToken,
    })
    verify,
    required Future<void> Function({required String mcpServerId}) delete,
    required Future<DiscoverMcpServerResult> Function({
      required String mcpServerId,
    })
    discover,
  }) : super._forTesting(
         readState: read,
         patchState: patch,
         create: create,
         verify: verify,
         delete: delete,
         discover: discover,
       );

  @override
  Future<List<WorkspaceToolEntity>> getWorkspaceTools(String _) async =>
      (await _read(.tool)).where(_isCloudTool).map(_tool).toList();
}

mixin _WorkspaceToolOperations on _CloudToolsRepositoryBase {
  Future<WorkspaceToolEntity> setToolEnabledById(
    String id, {
    required bool isEnabled,
  }) => _patchTool(id, (data) => data['isEnabled'] = isEnabled);

  Future<void> syncMcpTools({
    required String mcpServerId,
    required List<McpToolInfo> currentTools,
  }) async {
    final _ = currentTools;
    final _ = await discoverMcpServer(mcpServerId);
  }

  Future<List<WorkspaceToolEntity>> getEnabledWorkspaceTools(
    String workspaceId,
  ) async =>
      (await getWorkspaceTools(workspaceId))
          .where((tool) => tool.isEnabled)
          .toList();

  Future<WorkspaceToolEntity?> getWorkspaceTool(String _, String id) async {
    final resource = await _find(.tool, id);

    return resource == null ? null : _tool(resource);
  }

  Future<WorkspaceToolEntity> setToolPermissionMode(
    String id, {
    required ToolPermissionMode permissionMode,
  }) async {
    final tool = await _patchTool(id, null);
    final permissions = await _read(.toolPermission);
    final existing = permissions
        .where((value) => _data(value)['toolId'] == id)
        .firstOrNull;
    await _saveToolPermission(existing, tool, (
      id: id,
      permissionMode: permissionMode,
    ));

    return tool.copyWith(permissionMode: permissionMode);
  }

  Future<List<WorkspaceToolEntity>> resetWorkspaceToolPermissions(
    String _,
  ) async {
    final tools = await _read(.tool);
    final permissions = await _read(.toolPermission);
    final resources = [...tools, ...permissions];

    if (resources.isNotEmpty) {
      final _ = await _patch(resources.map(_resetToolResource).toList());
    }

    return await getWorkspaceTools('');
  }

  Future<WorkspaceToolEntity> setWorkspaceToolEnabled(
    String _,
    String toolType, {
    required bool isEnabled,
  }) {
    final _ = (toolType: toolType, isEnabled: isEnabled);
    throw const UnsupportedWorkspaceCapabilityException();
  }

  Future<bool> removeWorkspaceToolById(String id) async {
    final resource = await _find(.tool, id);
    if (resource == null) return false;
    final _ = await _patch([
      WorkspacePatchOperation(
        operation: .delete,
        resourceKind: .tool,
        resourceId: id,
        fieldMask: const [],
        expectedRevision: resource.revision,
      ),
    ]);

    return true;
  }

  Future<List<WorkspaceToolEntity>> patchWorkspaceToolConfig(
    String _,
    String id,
    String? config,
  ) async => [await _patchTool(id, (data) => data['config'] = config)];
}

mixin _McpServerOperations on _CloudToolsRepositoryBase {
  // Null means a tool group has no associated MCP server.
  // ignore: unnecessary-nullable
  @override
  Future<bool> removeMcpServer(String? id) async {
    if (id == null) return false;
    final resource = await _find(.mcpServer, id);
    if (resource == null) return false;
    final delete = _delete;
    if (delete != null) {
      await delete(mcpServerId: id);
    } else {
      await CloudMcpGateway(await _gateway).deleteMcpServer(mcpServerId: id);
    }

    return true;
  }

  Future<bool> deleteMcpServer(String id) => removeMcpServer(id);

  Future<({McpServerEntity server, DiscoverMcpServerResult discovery})>
  createMcpServer({
    required String workspaceId,
    required McpServerFormToCreate server,
    required String requestId,
    required String verificationReceipt,
  }) async {
    _validateCloudMcpServer(server);
    final result = await _createCloudMcpServer(
      this,
      server,
      requestId,
      verificationReceipt,
    );

    return (
      server: _toMcpServerEntity(workspaceId, server, result),
      discovery: result.discovery,
    );
  }

  Future<
    ({
      DiscoverMcpServerResult discovery,
      String verificationReceipt,
      DateTime expiresAt,
    })
  >
  verifyMcpServer({
    required String workspaceId,
    required McpServerFormToCreate server,
  }) async {
    final _ = workspaceId;
    _validateCloudMcpServer(server);
    final result = await _verifyCloudMcpServer(this, server);

    return (
      discovery: result.discovery,
      verificationReceipt: result.verificationReceipt,
      expiresAt: result.expiresAt,
    );
  }

  @override
  Future<DiscoverMcpServerResult> discoverMcpServer(String id) async {
    final discover = _discover;
    if (discover != null) return await discover(mcpServerId: id);

    return await CloudMcpGateway(await _gateway)
        .discoverMcpServer(mcpServerId: id);
  }

  Future<McpServerEntity> addMcpServerWithTools({
    required String workspaceId,
    required McpServerToCreate serverToCreate,
    required List<McpToolInfo> tools,
  }) {
    final _ = (
      workspaceId: workspaceId,
      serverToCreate: serverToCreate,
      tools: tools,
    );
    throw const UnsupportedWorkspaceCapabilityException();
  }

  Future<List<McpServerEntity>> getEnabledMcpServersForWorkspace(
    String workspaceId,
  ) async =>
      (await getMcpServersForWorkspace(workspaceId))
          .where((server) => server.isEnabled)
          .toList();

  Future<List<McpServerEntity>> getMcpServersForWorkspace(String _) async =>
      (await _read(.mcpServer)).map(_server).toList();

  Future<McpServerEntity?> getMcpServerById(String id) async {
    final resource = await _find(.mcpServer, id);

    return resource == null ? null : _server(resource);
  }
}

mixin _McpServerSettingsOperations on _CloudToolsRepositoryBase {
  Future<McpServerForEdit?> getMcpServerForEdit(String id) async {
    final resource = await _find(.mcpServer, id);
    if (resource == null) return null;

    return _mcpServerForEdit(resource, _data(resource));
  }

  Future<void> saveMcpTestSummary({
    required String serverId,
    required McpConnectionTestSummary summary,
  }) async {
    final resource = await _find(.mcpServer, serverId);
    if (resource == null) throw StateError('Cloud MCP server not found.');
    final data = _data(resource)..['testSummaryJson'] = summary.toJson();
    final _ = await _update(resource, data);
  }

  Future<void> updateMcpServerSettings(McpServerSettingsUpdate update) async {
    final resource = await _requiredMcpServerResource(update.serverId);
    final mutation = _prepareCloudMcpSettingsMutation(
      resource,
      update,
      _data(resource),
    );
    await _persistCloudMcpSettingsMutation(update, mutation);
  }

  Future<WorkspaceResource> _requiredMcpServerResource(String serverId) async {
    final resource = await _find(.mcpServer, serverId);
    if (resource == null) throw StateError('Cloud MCP server not found.');

    return resource;
  }

  Future<void> _persistCloudMcpSettingsMutation(
    McpServerSettingsUpdate update,
    _CloudMcpSettingsMutation mutation,
  ) async {
    final _ = await _requiredResourceStore.updateMcpCredential(
      _cloudMcpCredentialMutationInput(update, mutation),
    );
  }
}

typedef _CloudMcpCredentialMutationInput = ({
  String id,
  Map<String, Object?> data,
  int? resourceRevision,
  String? secret,
  bool clearSecret,
  int? secretRevision,
});

_CloudMcpCredentialMutationInput _cloudMcpCredentialMutationInput(
  McpServerSettingsUpdate update,
  _CloudMcpSettingsMutation mutation,
) => (
  id: update.serverId,
  data: mutation.data,
  resourceRevision: _cloudMcpResourceRevision(update, mutation),
  secret: _cloudMcpSecret(update),
  clearSecret: update.secretChange == .clear,
  secretRevision: _cloudMcpSecretRevision(update, mutation),
);

int? _cloudMcpResourceRevision(
  McpServerSettingsUpdate update,
  _CloudMcpSettingsMutation mutation,
) => update.expectedRevision ?? mutation.resource.revision;

String? _cloudMcpSecret(McpServerSettingsUpdate update) =>
    update.secretChange == .replace ? update.secret : null;

int? _cloudMcpSecretRevision(
  McpServerSettingsUpdate update,
  _CloudMcpSettingsMutation mutation,
) => update.expectedSecretRevision ?? mutation.currentSecretRevision;

bool _requiresCatalogMcpRequest(McpServerFormToCreate server) =>
    server.catalogSnapshotJson != null ||
    server.httpHeaders != null ||
    server.oauthJson != null ||
    server.transport is! McpTransportTypeStreamableHttp;

Future<CreateMcpServerResult> _createCloudMcpServer(
  _CloudToolsRepositoryBase repository,
  McpServerFormToCreate server,
  String requestId,
  String verificationReceipt,
) async {
  if (_requiresCatalogMcpRequest(server)) {
    final gateway = await repository._gateway;

    return await CloudMcpGateway(gateway).createCatalogMcpServer(
      server,
      requestId: requestId,
      verificationReceipt: verificationReceipt,
    );
  }

  return await repository._createMcpServer(
    _createMcpRequest(
      server,
      requestId: requestId,
      verificationReceipt: verificationReceipt,
    ),
  );
}

Future<VerifyMcpServerResult> _verifyCloudMcpServer(
  _CloudToolsRepositoryBase repository,
  McpServerFormToCreate server,
) async {
  if (_requiresCatalogMcpRequest(server)) {
    final gateway = await repository._gateway;

    return await CloudMcpGateway(gateway).verifyCatalogMcpServer(server);
  }

  return await repository._verifyMcpServer(_verifyMcpRequest(server));
}

typedef _CloudMcpSettingsMutation = ({
  WorkspaceResource resource,
  Map<String, dynamic> data,
  int? currentSecretRevision,
});

typedef _CloudMcpCurrentSettings = ({
  String? authType,
  String? url,
  Object? transport,
  McpServerAuthMode authMode,
  bool hasSecret,
  int? secretRevision,
});

_CloudMcpSettingsMutation _prepareCloudMcpSettingsMutation(
  WorkspaceResource resource,
  McpServerSettingsUpdate update,
  Map<String, dynamic> data,
) {
  final current = _cloudMcpCurrentSettings(data);
  _validateCloudMcpSettings(resource, update, current);

  return _writeAndPrepareCloudMcpSettings(resource, update, data, current);
}

void _validateCloudMcpSettings(
  WorkspaceResource resource,
  McpServerSettingsUpdate update,
  _CloudMcpCurrentSettings current,
) {
  _validateCloudMcpRevision(resource, update, current.secretRevision);
  _validateMcpSettingsUpdate(update, current.authMode, current.hasSecret);
}

_CloudMcpSettingsMutation _writeAndPrepareCloudMcpSettings(
  WorkspaceResource resource,
  McpServerSettingsUpdate update,
  Map<String, dynamic> data,
  _CloudMcpCurrentSettings current,
) {
  final authType = _cloudMcpAuthType(update.authMode);
  final identityChanged = _cloudMcpIdentityChanged(update, current, authType);
  _writeCloudMcpSettings((
    data: data,
    update: update,
    current: current,
    authType: authType,
    identityChanged: identityChanged,
  ));

  return _cloudMcpSettingsMutation(resource, data, current);
}

_CloudMcpSettingsMutation _cloudMcpSettingsMutation(
  WorkspaceResource resource,
  Map<String, dynamic> data,
  _CloudMcpCurrentSettings current,
) => (
  resource: resource,
  data: data,
  currentSecretRevision: current.secretRevision,
);

_CloudMcpCurrentSettings _cloudMcpCurrentSettings(Map<String, dynamic> data) {
  final authMode = _mcpAuthMode(data['authType']);

  return (
    authType: data['authType'] as String?,
    url: data['url'] as String?,
    transport: data['transport'],
    authMode: authMode,
    hasSecret: data['hasSecret'] as bool? ?? authMode != .none,
    secretRevision: data['secretRevision'] as int?,
  );
}

McpServerForEdit _mcpServerForEdit(
  WorkspaceResource resource,
  Map<String, dynamic> data,
) {
  final identity = _cloudMcpEditIdentity(resource, data);
  final configuration = _cloudMcpEditConfiguration(resource, data);

  return (
    id: identity.id,
    name: identity.name,
    url: identity.url,
    transport: identity.transport,
    authMode: configuration.authMode,
    hasSecret: configuration.hasSecret,
    revision: configuration.revision,
    secretRevision: configuration.secretRevision,
  );
}

typedef _CloudMcpEditIdentity = ({
  String id,
  String name,
  String url,
  McpTransportType transport,
});

typedef _CloudMcpEditConfiguration = ({
  McpServerAuthMode authMode,
  bool hasSecret,
  int? revision,
  int? secretRevision,
});

_CloudMcpEditIdentity _cloudMcpEditIdentity(
  WorkspaceResource resource,
  Map<String, dynamic> data,
) => (
  id: resource.resourceId,
  name: data['name'] as String,
  url: data['url'] as String,
  transport: .fromJson(Map<String, dynamic>.from(data['transport'] as Map)),
);

_CloudMcpEditConfiguration _cloudMcpEditConfiguration(
  WorkspaceResource resource,
  Map<String, dynamic> data,
) {
  final authMode = _mcpAuthMode(data['authType']);

  return (
    authMode: authMode,
    hasSecret: data['hasSecret'] as bool? ?? authMode != .none,
    revision: resource.revision,
    secretRevision: data['secretRevision'] as int?,
  );
}

void _validateCloudMcpRevision(
  WorkspaceResource resource,
  McpServerSettingsUpdate update,
  int? currentSecretRevision,
) {
  if (update.expectedRevision != null &&
      update.expectedRevision != resource.revision) {
    throw StateError('Cloud MCP server changed. Reload settings and retry.');
  }
  if (update.expectedSecretRevision != null &&
      update.expectedSecretRevision != currentSecretRevision) {
    throw StateError(
      'Cloud MCP credential changed. Reload settings and retry.',
    );
  }
}

String _cloudMcpAuthType(McpServerAuthMode authMode) => switch (authMode) {
  .none => 'none',
  .bearerToken => 'bearerToken',
  .httpHeaders => 'httpHeaders',
  .oauth => 'oauth',
};

bool _cloudMcpIdentityChanged(
  McpServerSettingsUpdate update,
  _CloudMcpCurrentSettings current,
  String authType,
) =>
    current.authType != authType ||
    current.url != update.url ||
    jsonEncode(current.transport) != jsonEncode(update.transport.toJson());

typedef _CloudMcpSettingsWrite = ({
  Map<String, dynamic> data,
  McpServerSettingsUpdate update,
  _CloudMcpCurrentSettings current,
  String authType,
  bool identityChanged,
});

void _writeCloudMcpSettings(_CloudMcpSettingsWrite write) {
  _writeCloudMcpIdentity(write);
  _updateCloudMcpAuthStatus(write);
  if (write.update.secretChange != .preserve || write.identityChanged) {
    final _ = write.data.remove('testSummaryJson');
  }
}

void _writeCloudMcpIdentity(_CloudMcpSettingsWrite write) {
  final data = write.data;
  final update = write.update;
  final authType = write.authType;
  final transport = update.transport.toJson();
  data
    ..['name'] = update.name
    ..['url'] = update.url
    ..['transport'] = transport
    ..['authType'] = authType;
}

void _updateCloudMcpAuthStatus(_CloudMcpSettingsWrite write) {
  if (_clearCloudMcpAuthStatus(write)) {
    final _ = write.data.remove('authStatus');

    return;
  }
  if (_requiresCloudMcpReauth(write)) {
    write.data['authStatus'] = 'reauthRequired';

    return;
  }
  if (_preserveCloudMcpAuthStatus(write)) return;
  write.data['authStatus'] = 'active';
}

bool _clearCloudMcpAuthStatus(_CloudMcpSettingsWrite write) =>
    write.authType == 'none';

bool _requiresCloudMcpReauth(_CloudMcpSettingsWrite write) =>
    write.authType == 'oauth' && write.identityChanged;

bool _preserveCloudMcpAuthStatus(_CloudMcpSettingsWrite write) =>
    write.current.authType == write.authType &&
    write.update.secretChange != .replace;

McpServerAuthMode _mcpAuthMode(Object? authType) => switch (authType) {
  'bearerToken' => .bearerToken,
  'httpHeaders' => .httpHeaders,
  'oauth' => .oauth,
  _ => .none,
};

void _validateMcpSettingsUpdate(
  McpServerSettingsUpdate update,
  McpServerAuthMode currentAuthMode,
  bool hasSecret,
) {
  if (update.name.trim().isEmpty || update.url.trim().isEmpty) {
    throw const FormatException('MCP name and URL are required.');
  }
  _validateCloudMcpSecretTransition(update, currentAuthMode);
  _validateCloudMcpSecretAvailability(update, currentAuthMode, hasSecret);
}

void _validateCloudMcpSecretTransition(
  McpServerSettingsUpdate update,
  McpServerAuthMode currentAuthMode,
) {
  if (_invalidMcpSecretClear(update) ||
      _invalidMcpSecretNone(update) ||
      _invalidMcpSecretOAuth(update, currentAuthMode)) {
    throw const FormatException('MCP authentication settings are invalid.');
  }
}

bool _invalidMcpSecretClear(McpServerSettingsUpdate update) =>
    update.secretChange == .clear && update.authMode != .none;

bool _invalidMcpSecretNone(McpServerSettingsUpdate update) =>
    update.authMode == .none && update.secretChange == .replace;

bool _invalidMcpSecretOAuth(
  McpServerSettingsUpdate update,
  McpServerAuthMode currentAuthMode,
) =>
    update.authMode == .oauth &&
    (currentAuthMode != .oauth || update.secretChange != .preserve);

void _validateCloudMcpSecretAvailability(
  McpServerSettingsUpdate update,
  McpServerAuthMode currentAuthMode,
  bool hasSecret,
) {
  if (update.authMode == .none || update.authMode == .oauth) return;
  if (_missingPreservedMcpSecret(update, currentAuthMode, hasSecret) ||
      _missingReplacementMcpSecret(update)) {
    throw const FormatException('MCP authentication settings are invalid.');
  }
}

bool _missingPreservedMcpSecret(
  McpServerSettingsUpdate update,
  McpServerAuthMode currentAuthMode,
  bool hasSecret,
) =>
    update.secretChange == .preserve &&
    (update.authMode != currentAuthMode || !hasSecret);

bool _missingReplacementMcpSecret(McpServerSettingsUpdate update) =>
    update.secretChange == .replace && update.secret?.trim().isNotEmpty != true;

mixin _ToolsGroupOperations on _CloudToolsRepositoryBase {
  Future<List<ToolsGroupEntity>> getToolsGroupsForWorkspace(String _) async =>
      (await _read(.toolGroup)).map(_group).toList();

  Future<WorkspaceToolEntity?> getWorkspaceToolByToolName({
    required String toolGroupId,
    required String toolName,
  }) async => (await getWorkspaceTools(''))
      .where(
        (tool) =>
            tool.workspaceToolsGroupId == toolGroupId &&
            tool.toolId == toolName,
      )
      .firstOrNull;

  Future<bool> deleteToolsGroup(String id) async {
    final value = await getToolsGroupById(id);
    if (value == null) return false;

    return await removeMcpServer(value.mcpServerId);
  }

  Future<bool> setToolsGroupEnabled(
    String id, {
    required bool isEnabled,
  }) async {
    final resource = await _find(.toolGroup, id);
    if (resource == null) return false;
    final data = _data(resource)..['isEnabled'] = isEnabled;
    final _ = await _update(resource, data);

    return true;
  }

  Future<ToolsGroupEntity?> getToolsGroupById(String id) async {
    final resource = await _find(.toolGroup, id);

    return resource == null ? null : _group(resource);
  }

  Future<ToolsGroupEntity?> getToolsGroupByMcpServerId(String id) async =>
      (await getToolsGroupsForWorkspace(''))
          .where((group) => group.mcpServerId == id)
          .firstOrNull;
}

extension on _CloudToolsRepositoryBase {
  void _validateCloudMcpServer(McpServerFormToCreate server) {
    WorkspaceCapabilities.cloud
      ..require(
        supported:
            server.transport is McpTransportTypeStreamableHttp ||
            server.transport is McpTransportTypeSSE,
      )
      ..require(
        supported:
            server.authenticationType != McpAuthenticationTypeOptions.oauth ||
            server.oauthJson != null && server.bearerToken?.isNotEmpty == true,
      );
  }

  Future<void> _saveToolPermission(
    WorkspaceResource? existing,
    WorkspaceToolEntity tool,
    ({String id, ToolPermissionMode permissionMode}) options,
  ) async {
    final data = _toolPermissionData(tool, options);
    if (existing == null) {
      final _ = await _patch([_createToolPermissionOperation(data)]);

      return;
    }
    final _ = await _update(existing, data);
  }

  Map<String, dynamic> _toolPermissionData(
    WorkspaceToolEntity tool,
    ({String id, ToolPermissionMode permissionMode}) options,
  ) => {
    'toolId': options.id,
    'toolGroupId': tool.workspaceToolsGroupId,
    'isEnabled': tool.isEnabled,
    'permissionMode': options.permissionMode.name,
  };

  WorkspacePatchOperation _createToolPermissionOperation(
    Map<String, dynamic> data,
  ) => WorkspacePatchOperation(
    operation: .create,
    resourceKind: .toolPermission,
    resourceId: const UuidV7().generate(),
    data: jsonEncode(data),
    fieldMask: const [],
  );

  ToolsGroupEntity _group(WorkspaceResource resource) {
    final data = _data(resource);

    return ToolsGroupEntity(
      id: resource.resourceId,
      workspaceId: '${resource.workspaceId}',
      name: data['name'] as String,
      isEnabled: data['isEnabled'] != false,
      permissions: _access(data['permissionMode']),
      createdAt: resource.createdAt,
      updatedAt: resource.updatedAt,
      mcpServerId: data['mcpServerId'] as String?,
    );
  }

  McpServerEntity _server(WorkspaceResource resource) =>
      _toMcpServer(resource, _data(resource));

  Future<WorkspaceToolEntity> _patchTool(
    String id,
    void Function(Map<String, dynamic>)? patch,
  ) async {
    final resource = await _find(.tool, id);
    if (resource == null) throw StateError('Cloud tool not found: $id');
    final data = _data(resource);
    patch?.call(data);

    return _tool(await _update(resource, data));
  }

  WorkspaceToolEntity _tool(WorkspaceResource resource) =>
      _toWorkspaceTool(resource, _data(resource));

  Future<WorkspaceResource> _update(
    WorkspaceResource resource,
    Map<String, dynamic> data,
  ) async => (await _patch([
    WorkspacePatchOperation(
      operation: .update,
      resourceKind: resource.resourceKind,
      resourceId: resource.resourceId,
      data: jsonEncode(data),
      fieldMask: const [],
      expectedRevision: resource.revision,
    ),
  ])).resources.single;

  WorkspacePatchOperation _resetToolResource(WorkspaceResource resource) {
    final data = _data(resource)
      ..['isEnabled'] = true
      ..['permissionMode'] = ToolPermissionMode.alwaysAsk.name;

    return WorkspacePatchOperation(
      operation: .update,
      resourceKind: resource.resourceKind,
      resourceId: resource.resourceId,
      data: jsonEncode(data),
      fieldMask: const [],
      expectedRevision: resource.revision,
    );
  }

  Future<WorkspaceResource?> _find(
    WorkspaceResourceKind kind,
    String id,
  ) async =>
      (await _read(kind)).where((value) => value.resourceId == id).firstOrNull;

  Map<String, dynamic> _data(WorkspaceResource value) =>
      CloudResourceMapper.decode(value);
}

extension on _CloudToolsRepositoryBase {
  Future<CreateMcpServerResult> _createMcpServer(
    ({
      String requestId,
      String name,
      String url,
      String transport,
      bool useHttp2,
      String? description,
      String? bearerToken,
      String? verificationReceipt,
    })
    request,
  ) async {
    final create = _create;
    if (create != null) return await _callCreate(create, request);

    return await CloudMcpGateway(await _gateway).createMcpServer(request);
  }

  Future<CreateMcpServerResult> _callCreate(
    Future<CreateMcpServerResult> Function({
      required String requestId,
      required String name,
      required String url,
      required String transport,
      required bool useHttp2,
      required String? description,
      required String? bearerToken,
      required String? verificationReceipt,
    })
    create,
    ({
      String requestId,
      String name,
      String url,
      String transport,
      bool useHttp2,
      String? description,
      String? bearerToken,
      String? verificationReceipt,
    })
    request,
  ) => create(
    requestId: request.requestId,
    name: request.name,
    url: request.url,
    transport: request.transport,
    useHttp2: request.useHttp2,
    description: request.description,
    bearerToken: request.bearerToken,
    verificationReceipt: request.verificationReceipt,
  );

  Future<VerifyMcpServerResult> _verifyMcpServer(
    ({
      String requestId,
      String url,
      String transport,
      bool useHttp2,
      String? bearerToken,
    })
    request,
  ) async {
    final verify = _verify;
    if (verify != null) {
      return await verify(
        requestId: request.requestId,
        url: request.url,
        transport: request.transport,
        useHttp2: request.useHttp2,
        bearerToken: request.bearerToken,
      );
    }

    return await CloudMcpGateway(await _gateway).verifyMcpServer(request);
  }

  Future<List<WorkspaceResource>> _read(WorkspaceResourceKind kind) async {
    final resources = <WorkspaceResource>[];
    String? afterResourceId;
    do {
      final pages = (await _readPage(kind, afterResourceId)).pages;
      if (pages.isEmpty) break;
      final page = pages.single;
      resources.addAll(page.resources);
      afterResourceId = page.nextResourceId;
    } while (afterResourceId != null);

    return resources;
  }

  Future<ReadWorkspaceStateResponse> _readPage(
    WorkspaceResourceKind kind,
    String? afterResourceId,
  ) => _readPages([
    WorkspaceResourcePageRequest(
      resourceKind: kind,
      afterResourceId: afterResourceId,
      limit: 100,
    ),
  ]);

  Future<PatchWorkspaceStateResponse> _patch(
    List<WorkspacePatchOperation> operations,
  ) async {
    final requestId = const UuidV7().generate();
    final patch = _patchState;
    if (patch != null) {
      return await patch(requestId: requestId, operations: operations);
    }

    return await _requiredResourceStore.patch(
      requestId: requestId,
      operations: operations,
    );
  }

  Future<ReadWorkspaceStateResponse> _readPages(
    List<WorkspaceResourcePageRequest> pages,
  ) async {
    final read = _readState;
    if (read != null) return await read(pages: pages);

    return await _requiredResourceStore.read(pages: pages);
  }

  PermissionAccess _access(Object? value) =>
      switch (CloudResourceMapper.permission(value)) {
        .alwaysAsk => .ask,
        .alwaysAllow => .granted,
        .alwaysDeny => .denied,
      };
}

bool _isCloudTool(WorkspaceResource resource) {
  final data = CloudResourceMapper.decode(resource);
  final id = (data['toolId'] ?? data['name'] ?? data['fullName']) as String?;

  return id != null && !NativeToolService.hasTypeString(id);
}

McpServerEntity _toMcpServer(
  WorkspaceResource resource,
  Map<String, dynamic> data,
) {
  final identity = _mcpServerIdentity(resource, data);
  final metadata = _mcpServerMetadata(resource, data);

  return _createMcpServerEntity(identity, metadata);
}

McpServerEntity _createMcpServerEntity(
  ({
    String id,
    String workspaceId,
    String name,
    String url,
    McpTransportType transport,
  })
  identity,
  ({
    DateTime createdAt,
    DateTime updatedAt,
    String? description,
    String? catalogSnapshotJson,
    String? testSummaryJson,
    bool isEnabled,
  })
  metadata,
) {
  final server = McpServerEntity(
    id: identity.id,
    workspaceId: identity.workspaceId,
    name: identity.name,
    url: identity.url,
    transport: identity.transport,
    authenticationType: const McpAuthenticationType.none(),
    createdAt: metadata.createdAt,
    updatedAt: metadata.updatedAt,
  );

  return _withMcpServerMetadata(server, metadata);
}

McpServerEntity _withMcpServerMetadata(
  McpServerEntity server,
  ({
    DateTime createdAt,
    DateTime updatedAt,
    String? description,
    String? catalogSnapshotJson,
    String? testSummaryJson,
    bool isEnabled,
  })
  metadata,
) => server.copyWith(
  description: metadata.description,
  catalogSnapshotJson: metadata.catalogSnapshotJson,
  lastTestSummary: McpConnectionTestSummary.fromJson(metadata.testSummaryJson),
  isEnabled: metadata.isEnabled,
);

({
  String id,
  String workspaceId,
  String name,
  String url,
  McpTransportType transport,
})
_mcpServerIdentity(WorkspaceResource resource, Map<String, dynamic> data) => (
  id: resource.resourceId,
  workspaceId: '${resource.workspaceId}',
  name: data['name'] as String,
  url: data['url'] as String,
  transport: .fromJson(Map<String, dynamic>.from(data['transport'] as Map)),
);

({
  DateTime createdAt,
  DateTime updatedAt,
  String? description,
  String? catalogSnapshotJson,
  String? testSummaryJson,
  bool isEnabled,
})
_mcpServerMetadata(WorkspaceResource resource, Map<String, dynamic> data) => (
  createdAt: resource.createdAt,
  updatedAt: resource.updatedAt,
  description: data['description'] as String?,
  catalogSnapshotJson: data['catalogSnapshotJson'] as String?,
  testSummaryJson: data['testSummaryJson'] as String?,
  isEnabled: data['isEnabled'] != false,
);

WorkspaceToolEntity _toWorkspaceTool(
  WorkspaceResource resource,
  Map<String, dynamic> data,
) => _createWorkspaceToolEntity(
  _workspaceToolRequiredFields(resource, data),
  _workspaceToolOptionalFields(data),
);

({
  String id,
  String workspaceId,
  String toolId,
  bool isEnabled,
  ToolPermissionMode permissionMode,
  DateTime createdAt,
  DateTime updatedAt,
})
_workspaceToolRequiredFields(
  WorkspaceResource resource,
  Map<String, dynamic> data,
) => (
  id: resource.resourceId,
  workspaceId: '${resource.workspaceId}',
  toolId: CloudResourceMapper.string(data, 'toolId'),
  isEnabled: CloudResourceMapper.boolean(data, 'isEnabled'),
  permissionMode: CloudResourceMapper.permission(data['permissionMode']),
  createdAt: resource.createdAt,
  updatedAt: resource.updatedAt,
);

({
  String? config,
  String? description,
  String? inputSchema,
  String? workspaceToolsGroupId,
})
_workspaceToolOptionalFields(Map<String, dynamic> data) => (
  config: data['config'] is String ? data['config'] as String : null,
  description: data['description'] as String?,
  inputSchema: _inputSchema(data['inputSchema']),
  workspaceToolsGroupId: data['toolGroupId'] as String?,
);

WorkspaceToolEntity _createWorkspaceToolEntity(
  ({
    String id,
    String workspaceId,
    String toolId,
    bool isEnabled,
    ToolPermissionMode permissionMode,
    DateTime createdAt,
    DateTime updatedAt,
  })
  requiredFields,
  ({
    String? config,
    String? description,
    String? inputSchema,
    String? workspaceToolsGroupId,
  })
  optionalFields,
) => WorkspaceToolEntity(
  id: requiredFields.id,
  workspaceId: requiredFields.workspaceId,
  toolId: requiredFields.toolId,
  isEnabled: requiredFields.isEnabled,
  permissionMode: requiredFields.permissionMode,
  createdAt: requiredFields.createdAt,
  updatedAt: requiredFields.updatedAt,
  config: optionalFields.config,
  description: optionalFields.description,
  inputSchema: optionalFields.inputSchema,
  workspaceToolsGroupId: optionalFields.workspaceToolsGroupId,
);

String? _inputSchema(Object? value) => switch (value) {
  final String schema => schema,
  null => null,
  final schema => jsonEncode(schema),
};

McpServerEntity _toMcpServerEntity(
  String workspaceId,
  McpServerFormToCreate server,
  CreateMcpServerResult result,
) => McpServerEntity(
  id: result.mcpServerId,
  workspaceId: workspaceId,
  name: server.name.trim(),
  url: server.url.trim(),
  transport: server.transport,
  authenticationType: const McpAuthenticationType.none(),
  createdAt: result.createdAt,
  updatedAt: result.createdAt,
  description: server.description?.trim(),
  catalogSnapshotJson: server.catalogSnapshotJson,
);

({
  String requestId,
  String name,
  String url,
  String transport,
  bool useHttp2,
  String? description,
  String? bearerToken,
  String verificationReceipt,
})
_createMcpRequest(
  McpServerFormToCreate server, {
  required String requestId,
  required String verificationReceipt,
}) => (
  requestId: requestId,
  name: server.name.trim(),
  url: server.url.trim(),
  transport: 'streamableHttp',
  useHttp2: _mcpUseHttp2(server.transport),
  description: server.description?.trim(),
  verificationReceipt: verificationReceipt,
  bearerToken: _mcpBearerToken(server),
);

({
  String requestId,
  String url,
  String transport,
  bool useHttp2,
  String? bearerToken,
})
_verifyMcpRequest(McpServerFormToCreate server) => (
  requestId: const UuidV7().generate(),
  url: server.url.trim(),
  transport: 'streamableHttp',
  useHttp2: _mcpUseHttp2(server.transport),
  bearerToken: _mcpBearerToken(server),
);

bool _mcpUseHttp2(McpTransportType transport) => switch (transport) {
  McpTransportTypeStreamableHttp(:final useHttp2) => useHttp2,
  McpTransportTypeSSE() => false,
};

String? _mcpBearerToken(McpServerFormToCreate server) =>
    server.authenticationType == McpAuthenticationTypeOptions.bearerToken
    ? server.bearerToken
    : null;
