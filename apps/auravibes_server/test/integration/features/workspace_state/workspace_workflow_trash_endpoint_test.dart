import 'dart:convert';

import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Workflow trash', (builder, endpoints) {
    test(
      'trash and restore retain item identity and nested references',
      () async {
        final ownerId = const Uuid().v4().toString();
        final owner = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            ownerId,
            const {},
          ),
        );
        final session = owner.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(ownerId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(ownerId),
            email: '$ownerId@example.com',
            passwordHash: 'unused',
          ),
        );
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Workflow trash',
              ownerUserId: ownerId,
              now: DateTime.now().toUtc(),
            );
        final workspaceId = workspace.id!;

        Future<void> createWorkflow(
          String id,
          Map<String, Object?> data,
        ) async {
          await endpoints.workspaceState.patch(
            owner,
            PatchWorkspaceStateRequest(
              workspaceId: workspaceId,
              requestId: 'create-$id',
              operations: [
                WorkspacePatchOperation(
                  operation: .create,
                  resourceKind: .workflow,
                  resourceId: id,
                  data: jsonEncode(data),
                  fieldMask: const [],
                ),
              ],
            ),
          );
        }

        Map<String, Object?> definition({String? nestedWorkflowId}) => {
          'version': 2,
          'localConnectorSchemas': const <String, Object?>{},
          'nodes': [
            _workflowNode('inputs', 'inputs'),
            if (nestedWorkflowId != null)
              {
                'id': 'nested',
                'kind': 'workflow',
                'targetId': nestedWorkflowId,
                'canonicalName': nestedWorkflowId,
                'label': 'Nested workflow',
                'hasSampledOutputs': false,
                'x': 0,
                'y': 0,
                'inputFields': const <Object?>[],
                'outputFields': const <Object?>[],
                'inputBindings': const <String, Object?>{},
                'conditionMode': 'all',
                'conditionRules': const <Object?>[],
                'transformOutputs': const <Object?>[],
              },
            _workflowNode('outputs', 'outputs'),
          ],
          'connections': const [
            {'fromNodeId': 'inputs', 'toNodeId': 'outputs'},
          ],
        };

        await createWorkflow('child', {
          'name': 'Child',
          'description': '',
          'definition': definition(),
        });
        await createWorkflow('parent', {
          'name': 'Parent',
          'description': '',
          'definition': definition(nestedWorkflowId: 'child'),
        });

        final child = await WorkspaceResource.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(workspaceId) &
              row.resourceKind.equals(.workflow) &
              row.resourceId.equals('child'),
        );
        if (child == null) throw StateError('Missing child workflow');
        final target = jsonEncode({
          'kind': 'workflow',
          'id': child.resourceId,
          'revision': child.revision,
        });
        final plan = jsonDecode(
          await endpoints.workspaceTrash.preview(owner, workspaceId, target),
        ) as Map<String, dynamic>;
        final batch = jsonDecode(
          await endpoints.workspaceTrash.trash(
            owner,
            WorkspaceTrashRequest(
              workspaceId: workspaceId,
              requestId: 'trash-child',
              targetJson: target,
              planToken: plan['planToken'] as String,
            ),
          ),
        ) as Map<String, dynamic>;

        final trashedChild = await WorkspaceResource.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(workspaceId) &
              row.resourceKind.equals(.workflow) &
              row.resourceId.equals('child'),
        );
        final parent = await WorkspaceResource.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(workspaceId) &
              row.resourceKind.equals(.workflow) &
              row.resourceId.equals('parent'),
        );
        expect(trashedChild?.deletedAt, isNotNull);
        expect(trashedChild?.resourceId, child.resourceId);
        final parentNodes =
            jsonDecode(parent!.data)['definition']['nodes'] as List;
        expect(
          parentNodes
              .where((node) => (node as Map)['targetId'] == 'child'),
          hasLength(1),
        );

        await endpoints.workspaceTrash.restore(
          owner,
          workspaceId,
          batch['id'] as String,
        );
        final restoredChild = await WorkspaceResource.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(workspaceId) &
              row.resourceKind.equals(.workflow) &
              row.resourceId.equals('child'),
        );
        expect(restoredChild?.deletedAt, isNull);
        expect(restoredChild?.resourceId, child.resourceId);
        expect(restoredChild?.revision, child.revision + 2);
      },
    );
  });
}

Map<String, Object?> _workflowNode(String id, String kind) => {
  'id': id,
  'kind': kind,
  'targetId': kind,
  'canonicalName': kind,
  'label': kind,
  'hasSampledOutputs': false,
  'x': 0,
  'y': 0,
  'inputFields': const <Object?>[],
  'outputFields': const <Object?>[],
  'inputBindings': const <String, Object?>{},
  'conditionMode': 'all',
  'conditionRules': const <Object?>[],
  'transformOutputs': const <Object?>[],
};
