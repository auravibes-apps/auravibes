import 'dart:convert';

import 'package:auravibes_app/data/repositories/cloud_workspace_directory_move_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_directory_move_item.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart' as cloud;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'cloud moves send one revision-checked patch preserving metadata',
    () async {
      final now = DateTime.utc(2026);
      var revision = 1;
      var permitted = true;
      final sent = <cloud.PatchWorkspaceStateRequest>[];
      final repository = CloudWorkspaceDirectoryMoveRepository.forTesting(
        ({required pages, required eventLimit, afterSequence}) async =>
            cloud.ReadWorkspaceStateResponse(
              pages: [
                for (final page in pages)
                  cloud.WorkspaceResourcePage(
                    resourceKind: page.resourceKind,
                    resources: [
                      cloud.WorkspaceResource(
                        workspaceId: 3,
                        resourceKind: page.resourceKind,
                        resourceId: 'shared',
                        data: jsonEncode({
                          'name': 'Current',
                          'parentId': null,
                          if (page.resourceKind == .workflow) ...{
                            'description': 'Workflow',
                            'definition': {
                              'version': 1,
                              'inputs': const <Object?>[],
                              'outputs': const <Object?>[],
                              'nodes': const <Object?>[],
                              'connections': const <Object?>[],
                            },
                            'canManageWorkflow': permitted,
                          } else if (page.resourceKind == .table) ...{
                            'labelColumnId': 'label',
                            'schemaRevision': 1,
                            'columns': [
                              {'id': 'label', 'name': 'Title', 'type': 'text'},
                            ],
                            'memberAccess': {'reader': 'read'},
                            'canManageTable': permitted,
                          } else
                            'canManageFolder': permitted,
                        }),
                        revision: revision,
                        createdAt: now,
                        updatedAt: now,
                      ),
                    ],
                  ),
              ],
              currentSequence: 0,
              events: [],
              requiresSnapshot: false,
            ),
        ({required requestId, required operations, viewMoves}) async {
          sent.add(
            cloud.PatchWorkspaceStateRequest(
              workspaceId: 3,
              requestId: requestId,
              operations: operations,
              viewMoves: viewMoves,
            ),
          );

          return cloud.PatchWorkspaceStateResponse(resources: [], sequence: 1);
        },
      );
      const items = [
        WorkspaceDirectoryMoveItem(
          key: (kind: .folder, id: 'shared'),
          name: 'Old folder',
          revision: 1,
          canManage: true,
        ),
        WorkspaceDirectoryMoveItem(
          key: (kind: .table, id: 'shared'),
          name: 'Old table',
          revision: 1,
          canManage: true,
        ),
        WorkspaceDirectoryMoveItem(
          key: (kind: .workflow, id: 'shared'),
          name: 'Workflow',
          revision: 1,
          canManage: true,
        ),
        WorkspaceDirectoryMoveItem(
          key: (kind: .view, id: 'view'),
          name: 'Overview',
          revision: 7,
          canManage: true,
          metadataName: 'Renamed overview',
        ),
      ];
      await repository.move(items, 'destination');
      expect(sent, hasLength(1));
      expect(
        sent.single.operations.map((operation) => operation.resourceKind),
        [
          cloud.WorkspaceResourceKind.folder,
          cloud.WorkspaceResourceKind.table,
          cloud.WorkspaceResourceKind.workflow,
        ],
      );
      final raw = sent.single.operations[1].data;
      if (raw == null) throw StateError('Missing patch data');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      expect(data['memberAccess'], {'reader': 'read'});
      expect(data['columns'], hasLength(1));
      expect(data['name'], 'Current');
      expect(data['parentId'], 'destination');
      expect(data.containsKey('canManageTable'), isFalse);
      final workflowData =
          jsonDecode(sent.single.operations[2].data!) as Map<String, dynamic>;
      expect(workflowData['parentId'], 'destination');
      expect(workflowData.containsKey('canManageWorkflow'), isFalse);
      expect(
        sent.single.operations.every(
          (operation) =>
              operation.expectedRevision == 1 && operation.fieldMask.isEmpty,
        ),
        isTrue,
      );
      expect((sent.single.viewMoves ?? []).single.id, 'view');
      expect((sent.single.viewMoves ?? []).single.expectedRevision, 7);
      expect((sent.single.viewMoves ?? []).single.parentId, 'destination');
      expect((sent.single.viewMoves ?? []).single.name, 'Renamed overview');
      revision = 2;
      await expectLater(
        repository.move(items, null),
        throwsA(
          isA<WorkspaceTableException>().having(
            (error) => error.conflict,
            'conflict',
            true,
          ),
        ),
      );
      expect(sent, hasLength(1));
      revision = 1;
      permitted = false;
      await expectLater(
        repository.move(items, null),
        throwsA(
          isA<WorkspaceTableException>().having(
            (error) => error.denied,
            'denied',
            true,
          ),
        ),
      );
      expect(sent, hasLength(1));
    },
  );
}
