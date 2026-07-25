import 'dart:convert';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/tools/data/cloud_tools_repository.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('cloud MCP lifecycle uses only server repository operations', () async {
    final resources = <WorkspaceResource>[_serverResource()];
    final patchedKinds = <WorkspaceResourceKind>[];
    final createRequestIds = <String>[];
    var creates = 0;
    var discoveries = 0;
    final repository = CloudToolsRepository.forTesting(
      read: ({required pages}) async => ReadWorkspaceStateResponse(
        pages: [
          for (final page in pages)
            WorkspaceResourcePage(
              resourceKind: page.resourceKind,
              resources: resources
                  .where((item) => item.resourceKind == page.resourceKind)
                  .toList(),
            ),
        ],
        currentSequence: 1,
        events: const [],
        requiresSnapshot: false,
      ),
      patch: ({required requestId, required operations}) async {
        patchedKinds.addAll(operations.map((item) => item.resourceKind));
        final changed = <WorkspaceResource>[];
        for (final operation in operations) {
          resources.removeWhere(
            (item) =>
                item.resourceKind == operation.resourceKind &&
                item.resourceId == operation.resourceId,
          );
          if (operation.operation == WorkspacePatchOperationKind.delete) {
            continue;
          }
          final resource = WorkspaceResource(
            workspaceId: 7,
            resourceKind: operation.resourceKind,
            resourceId: operation.resourceId,
            data: operation.data ?? '{}',
            revision: 1,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          );
          resources.add(resource);
          changed.add(resource);
        }

        return PatchWorkspaceStateResponse(resources: changed, sequence: 1);
      },
      create:
          ({
            required requestId,
            required name,
            required url,
            required transport,
            required useHttp2,
            required description,
            required bearerToken,
          }) async {
            creates++;
            createRequestIds.add(requestId);
            const serverId = 'created-server';
            const groupId = 'created-group';
            final now = DateTime.utc(2026);
            resources.addAll([
              WorkspaceResource(
                workspaceId: 7,
                resourceKind: WorkspaceResourceKind.mcpServer,
                resourceId: serverId,
                data: jsonEncode({
                  'id': serverId,
                  'name': name,
                  'url': url,
                  'transport': {'type': transport, 'useHttp2': useHttp2},
                }),
                revision: 1,
                createdAt: now,
                updatedAt: now,
              ),
              WorkspaceResource(
                workspaceId: 7,
                resourceKind: WorkspaceResourceKind.toolGroup,
                resourceId: groupId,
                data: jsonEncode({
                  'id': groupId,
                  'name': name,
                  'mcpServerId': serverId,
                  'isEnabled': true,
                  'permissionMode': 'alwaysAsk',
                }),
                revision: 1,
                createdAt: now,
                updatedAt: now,
              ),
              WorkspaceResource(
                workspaceId: 7,
                resourceKind: WorkspaceResourceKind.tool,
                resourceId: 'created-tool',
                data: jsonEncode({
                  'toolId': 'sum',
                  'toolGroupId': groupId,
                  'mcpServerId': serverId,
                  'isEnabled': true,
                  'permissionMode': 'alwaysAsk',
                }),
                revision: 1,
                createdAt: now,
                updatedAt: now,
              ),
              WorkspaceResource(
                workspaceId: 7,
                resourceKind: WorkspaceResourceKind.toolPermission,
                resourceId: 'created-permission',
                data: jsonEncode({
                  'toolId': 'created-tool',
                  'toolGroupId': groupId,
                  'permissionMode': 'alwaysAsk',
                }),
                revision: 1,
                createdAt: now,
                updatedAt: now,
              ),
            ]);

            return CreateMcpServerResult(
              mcpServerId: serverId,
              createdAt: now,
              discovery: DiscoverMcpServerResult(
                health: McpServerHealth.healthy,
                tools: const [],
              ),
            );
          },
      delete: ({required mcpServerId}) async {
        resources.removeWhere((resource) {
          if (resource.resourceId == mcpServerId) return true;

          final data = jsonDecode(resource.data) as Map<String, dynamic>;

          return data['mcpServerId'] == mcpServerId ||
              data['toolGroupId'] == 'created-group' ||
              data['toolId'] == 'created-tool';
        });
      },
      discover: ({required mcpServerId}) async {
        discoveries++;

        return DiscoverMcpServerResult(
          health: McpServerHealth.healthy,
          tools: [
            DiscoveredMcpTool(
              name: 'sum',
              inputSchemaJson: jsonEncode({'type': 'object'}),
            ),
          ],
        );
      },
    );
    final container = ProviderContainer(
      overrides: [
        currentRouteWorkspaceIdProvider.overrideWithValue('workspace-1'),
        workspaceSessionProvider.overrideWithValue(
          const WorkspaceSession(
            CloudWorkspaceRef(
              localWorkspaceId: 'workspace-1',
              serverUrl: 'https://example.com',
              accountId: 'account',
              cloudWorkspaceId: 7,
            ),
          ),
        ),
        workspaceSessionForRouteProvider('workspace-1').overrideWithValue(
          const AsyncData(
            WorkspaceSession(
              CloudWorkspaceRef(
                localWorkspaceId: 'workspace-1',
                serverUrl: 'https://example.com',
                accountId: 'account',
                cloudWorkspaceId: 7,
              ),
            ),
          ),
        ),
        mcpServersRepositoryProvider.overrideWithValue(repository),
        toolsGroupsRepositoryProvider.overrideWithValue(repository),
        workspaceToolsRepositoryProvider.overrideWithValue(repository),
        mcpManagerServiceProvider.overrideWith(
          (_) => throw StateError('local MCP manager accessed'),
        ),
        serviceConnectionRepositoryProvider.overrideWith(
          (_) => throw StateError('local service credentials accessed'),
        ),
        oauthCredentialServiceProvider.overrideWith(
          (_) => throw StateError('local OAuth credentials accessed'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(mcpConnectionProvider, (_, _) {
      final _ = Object();
    });
    addTearDown(subscription.close);
    final notifier = container.read(mcpConnectionProvider.notifier);

    await notifier.reconnectMcpServer('server-1');
    expect(
      container.read(mcpConnectionProvider).single.status,
      McpConnectionStatus.connected,
    );
    expect(
      notifier.getToolSpec(mcpServerId: 'server-1', toolName: 'sum'),
      isNotNull,
    );

    await notifier.addMcpServer(
      const McpServerFormToCreate(
        name: 'Cloud MCP',
        url: 'https://mcp.example.com',
        transport: McpTransportTypeStreamableHttp(),
        authenticationType: McpAuthenticationTypeOptions.bearerToken,
        bearerToken: 'test-token',
      ),
      workspaceId: 'workspace-1',
    );

    expect(creates, 1);
    expect(createRequestIds.single, isNotEmpty);
    expect(patchedKinds, isEmpty);
    final group = resources
        .where((item) => item.resourceKind == WorkspaceResourceKind.toolGroup)
        .single;
    final groupId = group.resourceId;
    final groupServerId =
        (jsonDecode(group.data) as Map<String, dynamic>)['mcpServerId']
            as String;
    final grouped = container.read(
      groupedToolsProvider('workspace-1').notifier,
    );
    final _ = await container.read(
      groupedToolsProvider('workspace-1').future,
    );
    await grouped.setMcpGroupEnabled(groupId, isEnabled: false);
    await grouped.reconnectMcp('server-1');
    await grouped.deleteMcpGroup(groupId);

    expect(discoveries, 3);
    expect(
      resources.any((item) => item.resourceId == groupServerId),
      isFalse,
    );
    expect(
      resources.any(
        (item) =>
            item.resourceKind == WorkspaceResourceKind.toolGroup ||
            item.resourceKind == WorkspaceResourceKind.tool ||
            item.resourceKind == WorkspaceResourceKind.toolPermission,
      ),
      isFalse,
    );
    await expectLater(
      notifier.callTool(
        mcpServerId: 'server-1',
        toolIdentifier: 'sum',
        arguments: const {},
      ),
      throwsA(isA<UnsupportedWorkspaceCapabilityException>()),
    );
  });
}

WorkspaceResource _serverResource() => WorkspaceResource(
  workspaceId: 7,
  resourceKind: WorkspaceResourceKind.mcpServer,
  resourceId: 'server-1',
  data: jsonEncode({
    'id': 'server-1',
    'name': 'Server',
    'url': 'https://mcp.example.com',
    'transport': {'type': 'streamableHttp', 'useHttp2': false},
  }),
  revision: 1,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
