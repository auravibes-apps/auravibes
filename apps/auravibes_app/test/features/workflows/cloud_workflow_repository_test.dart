import 'dart:convert';

import 'package:auravibes_app/features/workflows/adapters/cloud_workflow_repository.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads workflows with an empty optional description', () async {
    final store = CloudWorkspaceResourceStore.forTesting(
      watch: (_) => Stream.value([
        WorkspaceResource(
          workspaceId: 1,
          resourceKind: .workflow,
          resourceId: 'workflow-1',
          data: jsonEncode({
            'name': 'Workflow',
            'description': '',
            'definition': {
              'version': 1,
              'inputs': const <Object?>[],
              'outputs': const <Object?>[],
              'nodes': const <Object?>[],
              'connections': const <Object?>[],
            },
          }),
          revision: 1,
          createdAt: .utc(2026),
          updatedAt: .utc(2026),
        ),
      ]),
      patch: ({required requestId, required operations}) =>
          Future.error(StateError('Unexpected patch')),
      putSecret: (_) => Future.error(StateError('Unexpected secret write')),
      mutateCredential: (_) =>
          Future.error(StateError('Unexpected credential mutation')),
    );
    final repository = CloudWorkflowRepository(
      workspaceId: 'workspace-1',
      store: store,
    );

    final workflows = await repository.watchWorkflows('workspace-1').first;

    expect(workflows.single.name, 'Workflow');
    expect(workflows.single.description, isEmpty);
  });
}
