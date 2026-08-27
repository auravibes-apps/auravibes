import 'dart:async';
import 'dart:convert';

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
        Future.value(
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
      Future.value(
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

WorkspaceResource _resource(String id, Map<String, Object?> data) =>
    WorkspaceResource(
      workspaceId: 7,
      resourceKind: WorkspaceResourceKind.tool,
      resourceId: id,
      data: jsonEncode(data),
      revision: 1,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
