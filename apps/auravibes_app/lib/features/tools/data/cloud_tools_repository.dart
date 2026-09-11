import 'dart:convert';

import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/data/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
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
      _delete = null,
      _discover = null;

  new _forTesting({
    required this._readState,
    required this._patchState,
    required this._create,
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
  })?
  _create;
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
    with _WorkspaceToolOperations, _McpServerOperations, _ToolsGroupOperations
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
    })
    create,
    required Future<void> Function({required String mcpServerId}) delete,
    required Future<DiscoverMcpServerResult> Function({
      required String mcpServerId,
    })
    discover,
  }) : super._forTesting(
         readState: read,
         patchState: patch,
         create: create,
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
  }) async {
    _validateCloudMcpServer(server);
    final result = await _createMcpServer(_createMcpRequest(server));

    return (
      server: _toMcpServerEntity(workspaceId, server, result),
      discovery: result.discovery,
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
      ..require(supported: server.transport is McpTransportTypeStreamableHttp)
      ..require(
        supported:
            server.authenticationType != McpAuthenticationTypeOptions.oauth,
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
    })
    request,
  ) async {
    final create = _create;
    if (create != null) {
      return await create(
        requestId: request.requestId,
        name: request.name,
        url: request.url,
        transport: request.transport,
        useHttp2: request.useHttp2,
        description: request.description,
        bearerToken: request.bearerToken,
      );
    }

    return await CloudMcpGateway(await _gateway).createMcpServer(request);
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

  return server.copyWith(
    description: metadata.description,
    isEnabled: metadata.isEnabled,
  );
}

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

({DateTime createdAt, DateTime updatedAt, String? description, bool isEnabled})
_mcpServerMetadata(WorkspaceResource resource, Map<String, dynamic> data) => (
  createdAt: resource.createdAt,
  updatedAt: resource.updatedAt,
  description: data['description'] as String?,
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
);

({
  String requestId,
  String name,
  String url,
  String transport,
  bool useHttp2,
  String? description,
  String? bearerToken,
})
_createMcpRequest(McpServerFormToCreate server) => (
  requestId: const UuidV7().generate(),
  name: server.name.trim(),
  url: server.url.trim(),
  transport: 'streamableHttp',
  useHttp2: switch (server.transport) {
    McpTransportTypeStreamableHttp(:final useHttp2) => useHttp2,
    McpTransportTypeSSE() => false,
  },
  description: server.description?.trim(),
  bearerToken:
      server.authenticationType == McpAuthenticationTypeOptions.bearerToken
      ? server.bearerToken
      : null,
);
