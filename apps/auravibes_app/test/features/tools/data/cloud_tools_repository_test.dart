import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/tools/data/cloud_tools_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'maps cloud tools and excludes client-native tools without Drift',
    () async {
      final repository = CloudToolsRepository(
        .value(
          _gateway([
            _resource('mcp-tool', {
              'toolId': 'lookup',
              'toolGroupId': 'group-1',
              'description': 'Lookup',
              'inputSchema': {'type': 'object'},
              'isEnabled': true,
              'permissionMode': 'alwaysAsk',
            }),
            _resource('native-tool', {
              'toolId': 'url',
              'isEnabled': true,
              'permissionMode': 'alwaysAsk',
            }),
          ]),
        ),
      );

      final tools = await repository.getWorkspaceTools('local-workspace');

      expect(tools, hasLength(1));
      expect(tools.single.id, 'mcp-tool');
      expect(tools.single.workspaceToolsGroupId, 'group-1');
      expect(tools.single.inputSchema, jsonEncode({'type': 'object'}));
    },
  );

  test(
    'rejects client-native tool creation before any cloud or Drift call',
    () {
      final repository = CloudToolsRepository(
        Completer<CloudWorkspaceStateGateway>().future,
      );

      expect(
        () => repository.setWorkspaceToolEnabled(
          'workspace',
          'url',
          isEnabled: true,
        ),
        throwsA(isA<UnsupportedWorkspaceCapabilityException>()),
      );
    },
  );

  test('returns no tools when cloud returns no resource page', () async {
    final repository = CloudToolsRepository(
      .value(
        CloudWorkspaceStateGateway.forTesting(
          workspace: const CloudWorkspaceRef(
            localWorkspaceId: 'workspace',
            serverUrl: 'https://example.com',
            accountId: 'account',
            cloudWorkspaceId: 7,
          ),
          readState: (_) async => ReadWorkspaceStateResponse(
            pages: [],
            currentSequence: 1,
            events: [],
            requiresSnapshot: false,
          ),
          subscribe: (_) => const Stream.empty(),
        ),
      ),
    );

    expect(await repository.getWorkspaceTools('workspace'), isEmpty);
  });

  test('updates MCP settings through workspace credential mutation', () async {
    final server = _resource(
      'mcp-1',
      {
        'name': 'Catalog',
        'url': 'https://old.example.com/mcp',
        'transport': const McpTransportTypeSSE().toJson(),
        'authType': 'bearerToken',
        'hasSecret': true,
        'secretRevision': 4,
        'authStatus': 'active',
        'testSummaryJson': '{"status":"success"}',
      },
      kind: .mcpServer,
      revision: 9,
    );
    MutateWorkspaceCredentialRequest? savedRequest;
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: const CloudWorkspaceRef(
        localWorkspaceId: 'local-workspace',
        serverUrl: 'https://example.com',
        accountId: 'account',
        cloudWorkspaceId: 7,
      ),
      readState: (request) async => ReadWorkspaceStateResponse(
        pages: [
          WorkspaceResourcePage(
            resourceKind: request.pages.single.resourceKind,
            resources: [server],
          ),
        ],
        currentSequence: 10,
        events: const [],
        requiresSnapshot: false,
      ),
      subscribe: (_) => const Stream.empty(),
      mutateCredential: (request) async {
        savedRequest = request;

        return MutateWorkspaceCredentialResponse(
          resource: server,
          configured: true,
          secretRevision: 4,
          sequence: 11,
        );
      },
    );
    final repository = CloudToolsRepository(.value(gateway));
    final current = await repository.getMcpServerForEdit('mcp-1');

    expect(current?.revision, 9);
    expect(current?.secretRevision, 4);
    expect(current?.hasSecret, isTrue);

    await repository.updateMcpServerSettings(
      .new(
        serverId: 'mcp-1',
        name: 'Renamed Catalog',
        url: 'https://new.example.com/mcp',
        transport: const McpTransportTypeSSE(),
        authMode: .bearerToken,
        secretChange: .preserve,
        secret: null,
        expectedRevision: current?.revision,
        expectedSecretRevision: current?.secretRevision,
      ),
    );

    final request = savedRequest ?? fail('Expected credential mutation');
    final operation = request.resourceOperation;
    final data = jsonDecode(
      operation.data ?? fail('Expected MCP resource data'),
    ) as Map<String, dynamic>;
    expect(request.workspaceId, 7);
    expect(
      request.resourceOperation.operation,
      WorkspacePatchOperationKind.update,
    );
    expect(
      request.resourceOperation.resourceKind,
      WorkspaceResourceKind.mcpServer,
    );
    expect(request.resourceOperation.expectedRevision, 9);
    expect(request.secretKind, WorkspaceSecretKind.mcp);
    expect(request.scope, WorkspaceSecretScope.workspace);
    expect(request.secret, isNull);
    expect(request.clearSecret, isFalse);
    expect(request.expectedSecretRevision, 4);
    expect(data['name'], 'Renamed Catalog');
    expect(data['url'], 'https://new.example.com/mcp');
    expect(data['hasSecret'], isTrue);
    expect(data['secretRevision'], 4);
    expect(data.containsKey('testSummaryJson'), isFalse);
    expect(data.containsKey('secret'), isFalse);
  });

  test('persists only normalized MCP test summary fields to cloud', () async {
    final serverData = <String, Object?>{
      'name': 'Catalog',
      'url': 'https://example.com/mcp',
      'transport': const McpTransportTypeSSE().toJson(),
      'authType': 'none',
    };
    final server = _resource('mcp-summary', serverData, kind: .mcpServer);
    WorkspacePatchOperation? savedOperation;
    final repository = CloudToolsRepository.forTesting(
      read: ({required pages}) async => ReadWorkspaceStateResponse(
        pages: [
          WorkspaceResourcePage(
            resourceKind: pages.single.resourceKind,
            resources: [server],
          ),
        ],
        currentSequence: 1,
        events: const [],
        requiresSnapshot: false,
      ),
      patch: ({required requestId, required operations}) async {
        savedOperation = operations.single;
        final operation = operations.single;

        return PatchWorkspaceStateResponse(
          resources: [
            WorkspaceResource(
              workspaceId: server.workspaceId,
              resourceKind: server.resourceKind,
              resourceId: server.resourceId,
              data: operation.data ?? fail('Expected patched resource data'),
              revision: server.revision + 1,
              createdAt: server.createdAt,
              updatedAt: .utc(2026, 9, 29),
            ),
          ],
          sequence: 2,
        );
      },
      create: ({
        required requestId,
        required name,
        required url,
        required transport,
        required useHttp2,
        required description,
        required bearerToken,
        required verificationReceipt,
      }) async => throw UnimplementedError(),
      verify: ({
        required requestId,
        required url,
        required transport,
        required useHttp2,
        required bearerToken,
      }) async => throw UnimplementedError(),
      delete: ({required mcpServerId}) => Future<void>.value(),
      discover: ({required mcpServerId}) async => throw UnimplementedError(),
    );

    await repository.saveMcpTestSummary(
      serverId: server.resourceId,
      summary: .new(
        status: 'network',
        testedAt: .utc(2026, 9, 29, 12),
        transport: const McpTransportTypeSSE(),
        toolCount: 0,
        durationMilliseconds: 240,
      ),
    );

    final operation = savedOperation ?? fail('Expected cloud summary patch');
    final data = jsonDecode(
      operation.data ?? fail('Expected patched resource data'),
    ) as Map<String, dynamic>;
    final summary = jsonDecode(data['testSummaryJson'] as String);
    expect(summary, {
      'status': 'network',
      'testedAt': '2026-09-29T12:00:00.000Z',
      'transport': const McpTransportTypeSSE().toJson(),
      'toolCount': 0,
      'durationMilliseconds': 240,
    });
    expect(summary, isNot(contains('errorDetails')));
  });
}

CloudWorkspaceStateGateway _gateway(List<WorkspaceResource> resources) =>
    CloudWorkspaceStateGateway.forTesting(
      workspace: const CloudWorkspaceRef(
        localWorkspaceId: 'local-workspace',
        serverUrl: 'https://example.com',
        accountId: 'account',
        cloudWorkspaceId: 7,
      ),
      readState: (request) async => ReadWorkspaceStateResponse(
        pages: [
          WorkspaceResourcePage(
            resourceKind: request.pages.single.resourceKind,
            resources: resources,
          ),
        ],
        currentSequence: 1,
        events: const [],
        requiresSnapshot: false,
      ),
      subscribe: (_) => const Stream.empty(),
    );

WorkspaceResource _resource(
  String id,
  Map<String, Object?> data, {
  WorkspaceResourceKind kind = .tool,
  int revision = 1,
}) => WorkspaceResource(
  workspaceId: 7,
  resourceKind: kind,
  resourceId: id,
  data: jsonEncode(data),
  revision: revision,
  createdAt: .utc(2026),
  updatedAt: .utc(2026),
);
