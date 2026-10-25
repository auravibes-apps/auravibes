import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Conversation workspace commands', (sessionBuilder, endpoints) {
    test('registered cloud command limits context and rejects revocation before replay', () async {
      final userId = const Uuid().v4().toString();
      final authenticated = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final session = authenticated.build();
      await AuthUser.db.insertRow(
        session,
        AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        session,
        EmailAccount(
          authUserId: UuidValue.fromString(userId),
          email: '$userId@example.com',
          passwordHash: 'unused',
        ),
      );
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'Items',
            ownerUserId: userId,
            now: DateTime.now().toUtc(),
          );
      Future<void> patch(List<WorkspacePatchOperation> operations) async {
        await endpoints.workspaceState.patch(
          authenticated,
          PatchWorkspaceStateRequest(
            workspaceId: workspace.id!,
            requestId: const Uuid().v4().toString(),
            operations: operations,
          ),
        );
      }

      await patch([
        WorkspacePatchOperation(
          operation: .create,
          resourceKind: .table,
          resourceId: 'items',
          data: jsonEncode({
            'name': 'Items',
            'labelColumnId': 'title',
            'schemaRevision': 1,
            'columns': [
              {'id': 'title', 'name': 'Title', 'type': 'text'},
            ],
          }),
          fieldMask: [],
        ),
      ]);
      await patch([
        for (final id in ['selected', 'unselected'])
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: id,
            data: jsonEncode({
              'tableId': 'items',
              'schemaRevision': 1,
              'values': {'title': id},
            }),
            fieldMask: [],
          ),
      ]);
      final now = DateTime.now().toUtc();
      final conversation = await Conversation.db.insertRow(
        session,
        Conversation(
          workspaceId: workspace.id!,
          stableId: 'chat-one',
          isPinned: false,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final turn = await ConversationTurn.db.insertRow(
        session,
        ConversationTurn(
          workspaceId: workspace.id!,
          conversationId: conversation.id!,
          requestId: 'turn-one',
          requestHash: 'fixture',
          initiatorUserId: userId,
          status: 'running',
          revision: 1,
          acceptedSequence: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      Future<void> select(
        WorkspaceContextSelection? selection, {
        String role = 'user',
        bool trusted = true,
      }) async {
        final _ = await ConversationMessage.db.insertRow(
          session,
          ConversationMessage(
            workspaceId: workspace.id!,
            conversationId: conversation.id!,
            stableId: const Uuid().v4().toString(),
            role: role,
            kind: 'text',
            status: 'sent',
            content: 'Selection',
            metadataJson: jsonEncode({
              'modelMetadata': {
                workspaceContextMetadataKey: selection?.toJson(),
              },
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        if (trusted && role == 'user') {
          final _ = await endpoints.workspaceContext.save(
            authenticated,
            workspace.id!,
            conversation.stableId,
            const Uuid().v4().toString(),
            selection == null ? null : jsonEncode(selection.toJson()),
          );
        }
      }

      final selection = WorkspaceContextSelection(
        workspaceId: '${workspace.id}',
        conversationId: 'chat-one',
        itemId: 'items',
        kind: 'table',
        recordIds: ['selected'],
      );
      final tool = ServerResolvedTool(
        descriptor: AgentResolvedToolName.builtIn(
          tableId: workspaceCommandTableId,
          toolIdentifier: workspaceCommandToolName,
        ),
        spec: workspaceCommandToolSpec(),
      );
      Future<Object?> run(String id, Map<String, dynamic> arguments) =>
          const ServerToolExecutorService().call(
            session,
            turn,
            tool,
            ServerToolRequest(
              id: id,
              name: workspaceCommandToolName,
              arguments: arguments,
              isCancelled: () async => false,
            ),
          );
      await select(selection, role: 'assistant');
      await expectLater(
        run('read-denied', {'action': 'read', 'tableId': 'items'}),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await select(selection, trusted: false);
      await expectLater(
        run('forged-user-denied', {'action': 'read', 'tableId': 'items'}),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await select(selection);
      final read = await run('read', {'action': 'read', 'tableId': 'items'});
      expect(jsonEncode(read), contains('selected'));
      expect(jsonEncode(read), isNot(contains('unselected')));
      final edit = {
        'action': 'updateRecord',
        'tableId': 'items',
        'id': 'selected',
        'revision': 1,
        'schemaRevision': 1,
        'values': {'title': 'Edited'},
      };
      await run('edit', edit);
      await run('edit', edit);
      final records = await endpoints.workspaceState.read(
        authenticated,
        ReadWorkspaceStateRequest(
          workspaceId: workspace.id!,
          pages: [
            WorkspaceResourcePageRequest(
              resourceKind: .tableRecord,
              limit: 100,
            ),
          ],
          eventLimit: 0,
        ),
      );
      final selected = records.pages.single.resources.singleWhere(
        (row) => row.resourceId == 'selected',
      );
      expect(selected.revision, 2);
      expect(jsonDecode(selected.data)['values']['title'], 'Edited');
      await select(null);
      await expectLater(
        run('edit', edit),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await select(
        WorkspaceContextSelection(
          workspaceId: '${workspace.id}',
          conversationId: 'another-chat',
          itemId: 'items',
          kind: 'table',
          recordIds: ['selected'],
        ),
        trusted: false,
      );
      await expectLater(
        run('fork-denied', {'action': 'read', 'tableId': 'items'}),
        throwsA(isA<CloudWorkspaceException>()),
      );
    });
  });
}
