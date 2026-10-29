import 'dart:convert';

import 'package:auravibes_app/features/workflows/adapters/cloud_workflow_repository.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
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

  test(
    'cloud workflow metadata scopes Directory rows and saves by revision',
    () async {
      final now = DateTime.utc(2026, 10, 29);
      final patches = <WorkspacePatchOperation>[];
      final store = CloudWorkspaceResourceStore.forTesting(
        watch: (_) => Stream.value([
          WorkspaceResource(
            workspaceId: 1,
            resourceKind: .workflow,
            resourceId: 'workflow-1',
            data: jsonEncode({
              'name': 'Workflow',
              'description': 'Test',
              'parentId': 'folder-1',
              'canManageWorkflow': true,
              'definition': {
                'version': 1,
                'inputs': const <Object?>[],
                'outputs': const <Object?>[],
                'nodes': const <Object?>[],
                'connections': const <Object?>[],
              },
            }),
            revision: 4,
            createdAt: now,
            updatedAt: now,
          ),
          WorkspaceResource(
            workspaceId: 1,
            resourceKind: .workflow,
            resourceId: 'workflow-deleted',
            data: jsonEncode({
              'name': 'Deleted',
              'description': '',
              'definition': {
                'version': 1,
                'inputs': const <Object?>[],
                'outputs': const <Object?>[],
                'nodes': const <Object?>[],
                'connections': const <Object?>[],
              },
            }),
            revision: 2,
            createdAt: now,
            updatedAt: now,
            deletedAt: now,
          ),
        ]),
        patch: ({required requestId, required operations}) async {
          patches.addAll(operations);

          return PatchWorkspaceStateResponse(resources: [], sequence: 1);
        },
        putSecret: (_) => Future.error(StateError('Unexpected secret write')),
        mutateCredential: (_) =>
            Future.error(StateError('Unexpected credential mutation')),
      );
      final repository = CloudWorkflowRepository(
        workspaceId: 'workspace-1',
        store: store,
      );

      final inFolder = await repository
          .watchDirectory('workspace-1', 'folder-1')
          .first;
      expect(inFolder.single.id, 'workflow-1');
      expect(inFolder.single.canManage, isTrue);
      expect(
        await repository.watchDirectory('workspace-1', null).first,
        isEmpty,
      );
      expect(await repository.getWorkflow('workflow-deleted'), isNull);

      await repository.saveWorkflow(inFolder.single.copyWith(name: 'Renamed'));
      expect(patches.single.operation, WorkspacePatchOperationKind.update);
      expect(patches.single.resourceKind, WorkspaceResourceKind.workflow);
      expect(patches.single.resourceId, 'workflow-1');
      expect(patches.single.expectedRevision, 4);
      final data = jsonDecode(patches.single.data!) as Map<String, dynamic>;
      expect(data['name'], 'Renamed');
      expect(data['parentId'], 'folder-1');
      expect(data['definition'], isA<Map<String, dynamic>>());
    },
  );

  test(
    'cloud workflow save rejects resources the member cannot manage',
    () async {
      final now = DateTime.utc(2026, 10, 29);
      var patchCalled = false;
      final store = CloudWorkspaceResourceStore.forTesting(
        watch: (_) => Stream.value([
          WorkspaceResource(
            workspaceId: 1,
            resourceKind: .workflow,
            resourceId: 'workflow-1',
            data: jsonEncode({
              'name': 'Workflow',
              'description': '',
              'canManageWorkflow': false,
              'definition': {
                'version': 1,
                'inputs': const <Object?>[],
                'outputs': const <Object?>[],
                'nodes': const <Object?>[],
                'connections': const <Object?>[],
              },
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        ]),
        patch: ({required requestId, required operations}) async {
          patchCalled = true;

          return PatchWorkspaceStateResponse(resources: [], sequence: 1);
        },
        putSecret: (_) => Future.error(StateError('Unexpected secret write')),
        mutateCredential: (_) =>
            Future.error(StateError('Unexpected credential mutation')),
      );
      final repository = CloudWorkflowRepository(
        workspaceId: 'workspace-1',
        store: store,
      );
      final workflow = await repository.getWorkflow('workflow-1');

      await expectLater(
        repository.saveWorkflow(workflow!),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect(patchCalled, isFalse);
    },
  );

  test('cloud workflow save cannot recreate a trashed workflow', () async {
    final now = DateTime.utc(2026, 10, 29);
    var patchCalled = false;
    final store = CloudWorkspaceResourceStore.forTesting(
      watch: (_) => Stream.value([
        WorkspaceResource(
          workspaceId: 1,
          resourceKind: .workflow,
          resourceId: 'workflow-deleted',
          data: jsonEncode({
            'name': 'Deleted',
            'description': '',
            'canManageWorkflow': true,
            'definition': {
              'version': 1,
              'inputs': const <Object?>[],
              'outputs': const <Object?>[],
              'nodes': const <Object?>[],
              'connections': const <Object?>[],
            },
          }),
          revision: 2,
          createdAt: now,
          updatedAt: now,
          deletedAt: now,
        ),
      ]),
      patch: ({required requestId, required operations}) async {
        patchCalled = true;

        return PatchWorkspaceStateResponse(resources: [], sequence: 1);
      },
      putSecret: (_) => Future.error(StateError('Unexpected secret write')),
      mutateCredential: (_) =>
          Future.error(StateError('Unexpected credential mutation')),
    );
    final repository = CloudWorkflowRepository(
      workspaceId: 'workspace-1',
      store: store,
    );
    final staleWorkflow = WorkspaceWorkflow.create(
      id: 'workflow-deleted',
      workspaceId: 'workspace-1',
      name: 'Deleted',
      description: '',
      createdAt: now,
      updatedAt: now,
    );

    await expectLater(
      repository.saveWorkflow(staleWorkflow),
      throwsA(isA<WorkspaceTableException>()),
    );
    expect(patchCalled, isFalse);
  });
}
