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
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/tools/native_tool_service.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

class CloudToolsRepository
    implements
        WorkspaceToolsRepositoryContract,
        ToolsGroupsRepositoryContract,
        McpServersRepositoryContract {
  CloudToolsRepository(this._gatewayFuture)
    : _readState = null,
      _patchState = null,
      _create = null,
      _delete = null,
      _discover = null;

  CloudToolsRepository.forTesting({
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
    this._create,
    required Future<void> Function({required String mcpServerId}) this._delete,
    required Future<DiscoverMcpServerResult> Function({
      required String mcpServerId,
    })
    this._discover,
  }) : _gatewayFuture = null,
       _readState = read,
       _patchState = patch;

  final Future<CloudWorkspaceStateGateway?>? _gatewayFuture;
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
        context: CloudOperationContext.state,
        code: 'gatewayUnavailable',
      ));

  @override
  Future<WorkspaceToolEntity> setToolEnabledById(
    String id, {
    required bool isEnabled,
  }) => _patchTool(id, (data) => data['isEnabled'] = isEnabled);

  @override
  Future<void> syncMcpTools({
    required String mcpServerId,
    required List<McpToolInfo> currentTools,
  }) async {
    final _ = await discoverMcpServer(mcpServerId);
  }

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

  @override
  Future<bool> deleteMcpServer(String id) => removeMcpServer(id);

  Future<({McpServerEntity server, DiscoverMcpServerResult discovery})>
  createMcpServer({
    required String workspaceId,
    required McpServerFormToCreate server,
  }) async {
    WorkspaceCapabilities.cloud
      ..require(supported: server.transport is McpTransportTypeStreamableHttp)
      ..require(
        supported:
            server.authenticationType != McpAuthenticationTypeOptions.oauth,
      );
    final result = await _createMcpServer(
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

    return (
      server: McpServerEntity(
        id: result.mcpServerId,
        workspaceId: workspaceId,
        name: server.name.trim(),
        url: server.url.trim(),
        transport: server.transport,
        authenticationType: const McpAuthenticationType.none(),
        createdAt: result.createdAt,
        updatedAt: result.createdAt,
        description: server.description?.trim(),
      ),
      discovery: result.discovery,
    );
  }

  Future<DiscoverMcpServerResult> discoverMcpServer(String id) async {
    final discover = _discover;
    if (discover != null) return await discover(mcpServerId: id);

    return await CloudMcpGateway(
      await _gateway,
    ).discoverMcpServer(mcpServerId: id);
  }

  @override
  Future<McpServerEntity> addMcpServerWithTools({
    required String workspaceId,
    required McpServerToCreate serverToCreate,
    required List<McpToolInfo> tools,
  }) => throw const UnsupportedWorkspaceCapabilityException();
  @override
  Future<List<McpServerEntity>> getEnabledMcpServersForWorkspace(
    String workspaceId,
  ) async => (await getMcpServersForWorkspace(
    workspaceId,
  )).where((server) => server.isEnabled).toList();

  @override
  Future<List<WorkspaceToolEntity>> getWorkspaceTools(String _) async =>
      (await _read(.tool))
          .where((resource) {
            final data = _data(resource);
            final id =
                (data['toolId'] ?? data['name'] ?? data['fullName']) as String?;

            return id != null && !NativeToolService.hasTypeString(id);
          })
          .map(_tool)
          .toList();

  @override
  Future<List<WorkspaceToolEntity>> getEnabledWorkspaceTools(
    String workspaceId,
  ) async => (await getWorkspaceTools(
    workspaceId,
  )).where((tool) => tool.isEnabled).toList();

  @override
  Future<WorkspaceToolEntity?> getWorkspaceTool(String _, String id) async {
    final resource = await _find(.tool, id);

    return resource == null ? null : _tool(resource);
  }

  @override
  Future<List<McpServerEntity>> getMcpServersForWorkspace(String _) async =>
      (await _read(.mcpServer)).map(_server).toList();

  @override
  Future<List<ToolsGroupEntity>> getToolsGroupsForWorkspace(String _) async =>
      (await _read(.toolGroup)).map(_group).toList();

  @override
  Future<WorkspaceToolEntity> setToolPermissionMode(
    String id, {
    required ToolPermissionMode permissionMode,
  }) async {
    final tool = await _patchTool(id, null);
    final permissions = await _read(.toolPermission);
    final existing = permissions
        .where((value) => _data(value)['toolId'] == id)
        .firstOrNull;
    final data = <String, dynamic>{
      'toolId': id,
      'toolGroupId': tool.workspaceToolsGroupId,
      'isEnabled': tool.isEnabled,
      'permissionMode': permissionMode.name,
    };
    if (existing == null) {
      final _ = await _patch([
        WorkspacePatchOperation(
          operation: .create,
          resourceKind: .toolPermission,
          resourceId: const UuidV7().generate(),
          data: jsonEncode(data),
          fieldMask: const [],
        ),
      ]);
    } else {
      final _ = await _update(existing, data);
    }

    return tool.copyWith(permissionMode: permissionMode);
  }

  @override
  Future<WorkspaceToolEntity> setWorkspaceToolEnabled(
    String _,
    String toolType, {
    required bool isEnabled,
  }) => throw const UnsupportedWorkspaceCapabilityException();
  @override
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

  @override
  Future<List<WorkspaceToolEntity>> patchWorkspaceToolConfig(
    String _,
    String id,
    String? config,
  ) async => [await _patchTool(id, (data) => data['config'] = config)];
  @override
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

  @override
  Future<bool> deleteToolsGroup(String id) async {
    final value = await getToolsGroupById(id);
    if (value == null) return false;

    return await removeMcpServer(value.mcpServerId);
  }

  @override
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

  @override
  Future<ToolsGroupEntity?> getToolsGroupById(String id) async {
    final resource = await _find(.toolGroup, id);

    return resource == null ? null : _group(resource);
  }

  @override
  Future<ToolsGroupEntity?> getToolsGroupByMcpServerId(String id) async =>
      (await getToolsGroupsForWorkspace(
        '',
      )).where((group) => group.mcpServerId == id).firstOrNull;
  @override
  Future<McpServerEntity?> getMcpServerById(String id) async {
    final resource = await _find(.mcpServer, id);

    return resource == null ? null : _server(resource);
  }

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

  McpServerEntity _server(WorkspaceResource resource) {
    final data = _data(resource);

    return McpServerEntity(
      id: resource.resourceId,
      workspaceId: '${resource.workspaceId}',
      name: data['name'] as String,
      url: data['url'] as String,
      transport: McpTransportType.fromJson(
        Map<String, dynamic>.from(data['transport'] as Map),
      ),
      authenticationType: const McpAuthenticationType.none(),
      createdAt: resource.createdAt,
      updatedAt: resource.updatedAt,
      description: data['description'] as String?,
      isEnabled: data['isEnabled'] != false,
    );
  }

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

  WorkspaceToolEntity _tool(WorkspaceResource resource) {
    final data = _data(resource);

    return WorkspaceToolEntity(
      id: resource.resourceId,
      workspaceId: '${resource.workspaceId}',
      toolId: CloudResourceMapper.string(data, 'toolId'),
      isEnabled: CloudResourceMapper.boolean(data, 'isEnabled'),
      permissionMode: CloudResourceMapper.permission(data['permissionMode']),
      createdAt: resource.createdAt,
      updatedAt: resource.updatedAt,
      config: data['config'] is String ? data['config'] as String : null,
      description: data['description'] as String?,
      inputSchema: switch (data['inputSchema']) {
        final String value => value,
        null => null,
        final value => jsonEncode(value),
      },
      workspaceToolsGroupId: data['toolGroupId'] as String?,
    );
  }

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

  Future<CreateMcpServerResult> _createMcpServer({
    required String requestId,
    required String name,
    required String url,
    required String transport,
    required bool useHttp2,
    required String? description,
    required String? bearerToken,
  }) async {
    final create = _create;
    if (create != null) {
      return await create(
        requestId: requestId,
        name: name,
        url: url,
        transport: transport,
        useHttp2: useHttp2,
        description: description,
        bearerToken: bearerToken,
      );
    }

    return await CloudMcpGateway(await _gateway).createMcpServer(
      requestId: requestId,
      name: name,
      url: url,
      transport: transport,
      useHttp2: useHttp2,
      description: description,
      bearerToken: bearerToken,
    );
  }

  Future<List<WorkspaceResource>> _read(WorkspaceResourceKind kind) async {
    final resources = <WorkspaceResource>[];
    String? afterResourceId;
    do {
      final page = (await _readPages([
        WorkspaceResourcePageRequest(
          resourceKind: kind,
          afterResourceId: afterResourceId,
          limit: 100,
        ),
      ])).pages.single;
      resources.addAll(page.resources);
      afterResourceId = page.nextResourceId;
    } while (afterResourceId != null);

    return resources;
  }

  Future<PatchWorkspaceStateResponse> _patch(
    List<WorkspacePatchOperation> operations,
  ) async {
    final requestId = const UuidV7().generate();
    final patch = _patchState;
    if (patch != null) {
      return await patch(requestId: requestId, operations: operations);
    }

    return await (await _gateway).patch(
      requestId: requestId,
      operations: operations,
    );
  }

  Future<ReadWorkspaceStateResponse> _readPages(
    List<WorkspaceResourcePageRequest> pages,
  ) async {
    final read = _readState;
    if (read != null) return await read(pages: pages);

    return await (await _gateway).read(pages: pages);
  }

  PermissionAccess _access(Object? value) =>
      switch (CloudResourceMapper.permission(value)) {
        .alwaysAsk => .ask,
        .alwaysAllow => .granted,
        .alwaysDeny => .denied,
      };
}
