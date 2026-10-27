import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:auravibes_server/src/features/conversations/engine/workspace_prompt_projection.dart';
import 'package:auravibes_server/src/features/conversations/engine/workspace_conversation_commands.dart';
import 'package:auravibes_server/src/features/conversations/engine/workspace_conversation_file.dart';
import 'package:auravibes_server/src/features/objects/object_store.dart';
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
                'workspaceContextSelection': selection?.toJson(),
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

      final object = await WorkspaceObject.db.insertRow(
        session,
        WorkspaceObject(
          workspaceId: workspace.id!,
          objectKey: 'synthetic',
          purpose: 'file',
          displayName: 'Note.txt',
          mimeType: 'text/plain',
          sizeBytes: 5,
          checksumSha256: '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
          status: 'active',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await WorkspaceResource.db.insertRow(
        session,
        WorkspaceResource(
          workspaceId: workspace.id!,
          resourceKind: .file,
          resourceId: 'note',
          data: jsonEncode({'name': 'Note', 'assetId': '${object.id}'}),
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final fileSelection = WorkspaceContextSelection(
        workspaceId: '${workspace.id}',
        conversationId: conversation.stableId,
        itemId: 'note',
        kind: 'file',
      );
      await select(fileSelection);
      final fileCommand = WorkspaceConversationCommands(
        fileReader: WorkspaceConversationFile(
          store: const _FileStore(),
          fetch: (_, _) async => utf8.encode('hello'),
        ),
      );
      final file = await fileCommand.call(session, turn, 'read-file', {
        'action': 'read',
        'id': 'note',
      }) as Map;
      expect(file['content'], 'hello');
      expect(file['truncated'], isFalse);
      expect(jsonEncode(file), isNot(contains('https://')));
      var lateFetch = false;
      final slowSigner = WorkspaceConversationCommands(
        fileReader: WorkspaceConversationFile(
          store: const _SlowFileStore(),
          deadline: const Duration(milliseconds: 50),
          fetch: (_, _) async {
            lateFetch = true;
            return utf8.encode('hello');
          },
        ),
      );
      await expectLater(
        slowSigner.call(session, turn, 'slow-file-signing', {
          'action': 'read',
          'id': 'note',
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'File storage is unavailable.',
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(lateFetch, isFalse);
      for (final invalid in [
        object.copyWith(sizeBytes: WorkspaceConversationFile.maxBytes + 1),
        object.copyWith(mimeType: 'image/png'),
        object.copyWith(checksumSha256: 'invalid'),
      ]) {
        await WorkspaceObject.db.updateRow(session, invalid);
        await expectLater(
          fileCommand.call(session, turn, 'invalid-file', {
            'action': 'read',
            'id': 'note',
          }),
          throwsFormatException,
        );
      }
      await WorkspaceObject.db.updateRow(session, object);
      await expectLater(
        fileCommand.call(session, turn, 'read-unshared-file', {
          'action': 'read',
          'id': 'other',
        }),
        throwsA(isA<CloudWorkspaceException>()),
      );
      final revokedDuringFetch = WorkspaceConversationCommands(
        fileReader: WorkspaceConversationFile(
          store: const _FileStore(),
          fetch: (_, _) async {
            await select(null);
            return utf8.encode('hello');
          },
        ),
      );
      await expectLater(
        revokedDuringFetch.call(session, turn, 'read-revoked-during-fetch', {
          'action': 'read',
          'id': 'note',
        }),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await select(null);
      await expectLater(
        fileCommand.call(session, turn, 'read-revoked-file', {
          'action': 'read',
          'id': 'note',
        }),
        throwsA(isA<CloudWorkspaceException>()),
      );

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
        throwsA(
          isA<AgentToolExecutionFailure>().having(
            (failure) => failure.responseRaw,
            'safe message',
            contains('unavailable'),
          ),
        ),
      );
      await select(selection, trusted: false);
      await expectLater(
        run('forged-user-denied', {'action': 'read', 'tableId': 'items'}),
        throwsA(
          isA<AgentToolExecutionFailure>().having(
            (failure) => failure.responseRaw,
            'safe message',
            contains('unavailable'),
          ),
        ),
      );
      await select(selection);
      final read = await run('read', {'action': 'read', 'tableId': 'items'});
      expect(jsonEncode(read), contains('selected'));
      expect(jsonEncode(read), isNot(contains('unselected')));
      final selectedRecord = await run('read-selected-record', {
        'action': 'read',
        'tableId': 'items',
        'id': 'selected',
      }) as Map;
      expect((selectedRecord['records'] as List), hasLength(1));
      expect((selectedRecord['records'] as List).single['id'], 'selected');
      await expectLater(
        run('read-unselected-record', {
          'action': 'read',
          'tableId': 'items',
          'id': 'unselected',
        }),
        throwsA(isA<CloudWorkspaceException>()),
      );
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
      final aiRevision = (await WorkspaceRevision.db.find(
        session,
        where: (row) =>
            row.workspaceId.equals(workspace.id!) &
            row.resourceKind.equals(.tableRecord) &
            row.resourceId.equals('selected') &
            row.revision.equals(2),
      )).single;
      expect(aiRevision.actorUserId, userId);
      expect(aiRevision.aiInvolved, isTrue);
      expect(aiRevision.operation, 'update');
      expect(aiRevision.conversationId, 'chat-one');
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
        throwsA(
          isA<AgentToolExecutionFailure>().having(
            (failure) => failure.responseRaw,
            'safe message',
            contains('unavailable'),
          ),
        ),
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
        throwsA(
          isA<AgentToolExecutionFailure>().having(
            (failure) => failure.responseRaw,
            'safe message',
            contains('unavailable'),
          ),
        ),
      );

      final assistant = await ConversationMessage.db.insertRow(
        session,
        ConversationMessage(
          workspaceId: workspace.id!,
          conversationId: conversation.id!,
          stableId: 'assistant-workspace-tools',
          role: 'assistant',
          kind: 'text',
          status: 'sent',
          content: '',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final runtime = ServerToolRuntime(
        executor: const ServerToolExecutorService().call,
      );
      await select(
        WorkspaceContextSelection(
          workspaceId: '${workspace.id}',
          conversationId: conversation.stableId,
          itemId: '',
          kind: 'directory',
        ),
      );
      final root = await const WorkspaceConversationCommands().call(
        session,
        turn,
        'read-directory-root',
        {'action': 'read'},
      );
      expect(root, {'kind': 'directory', 'id': '', 'parentId': null});
      await expectLater(
        const WorkspaceConversationCommands().call(
          session,
          turn,
          'read-unshared-table',
          {'action': 'read', 'tableId': 'items'},
        ),
        throwsA(isA<Object>()),
      );
      final pending = await runtime.handle(
        session,
        turn: turn,
        messageId: assistant.id!,
        request: const ServerToolRequest(
          id: 'pending-create',
          name: workspaceCommandToolName,
          arguments: {
            'action': 'createTable',
            'name': 'Needs approval',
            'labelName': 'Title',
          },
        ),
      );
      expect(pending, ServerToolDisposition.awaitingApproval);
      final before = await endpoints.workspaceState.read(
        authenticated,
        ReadWorkspaceStateRequest(
          workspaceId: workspace.id!,
          pages: [
            WorkspaceResourcePageRequest(resourceKind: .table, limit: 100),
          ],
          eventLimit: 0,
        ),
      );
      expect(before.pages.single.resources, hasLength(1));
      final _ = await Conversation.db.updateRow(
        session,
        conversation.copyWith(toolAccessMode: 'allow_all'),
      );
      final created = await runtime.handle(
        session,
        turn: turn,
        messageId: assistant.id!,
        request: const ServerToolRequest(
          id: 'created-table',
          name: workspaceCommandToolName,
          arguments: {
            'action': 'createTable',
            'name': 'Created table',
            'labelName': 'Title',
          },
        ),
      );
      expect(created, ServerToolDisposition.completed);
      final tableCall = (await ConversationToolCall.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspace.id) &
            row.stableId.equals('created-table'),
      ))!;
      expect(tableCall.status, 'success');
      final tableId =
          (jsonDecode(tableCall.resultJson!) as Map)['id'] as String;
      final tableRead = await run('read-created', {
        'action': 'read',
        'tableId': tableId,
      }) as Map;
      final label = (tableRead['columns'] as List).first['id'] as String;
      final added = await runtime.handle(
        session,
        turn: turn,
        messageId: assistant.id!,
        request: ServerToolRequest(
          id: 'created-record',
          name: workspaceCommandToolName,
          arguments: {
            'action': 'createRecord',
            'tableId': tableId,
            'revision': 1,
            'schemaRevision': 1,
            'values': {label: 'Current selected value'},
          },
        ),
      );
      expect(added, ServerToolDisposition.completed);
      final rowCall = (await ConversationToolCall.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspace.id) &
            row.stableId.equals('created-record'),
      ))!;
      expect(rowCall.status, 'success');
      final unrelatedAdded = await runtime.handle(
        session,
        turn: turn,
        messageId: assistant.id!,
        request: ServerToolRequest(
          id: 'unrelated-record',
          name: workspaceCommandToolName,
          arguments: {
            'action': 'createRecord',
            'tableId': tableId,
            'revision': 1,
            'schemaRevision': 1,
            'values': {label: 'Unrelated selected value'},
          },
        ),
      );
      expect(unrelatedAdded, ServerToolDisposition.completed);
      Future<Map<String, dynamic>> command(
        String id,
        Map<String, dynamic> arguments,
      ) async {
        final _ = await runtime.handle(
          session,
          turn: turn,
          messageId: assistant.id!,
          request: ServerToolRequest(
            id: id,
            name: workspaceCommandToolName,
            arguments: arguments,
          ),
        );
        final call = (await ConversationToolCall.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(workspace.id) & row.stableId.equals(id),
        ))!;
        expect(call.status, 'success', reason: call.resultJson);

        return jsonDecode(call.resultJson!) as Map<String, dynamic>;
      }

      await command('cloud-column', {
        'action': 'saveColumn',
        'tableId': tableId,
        'revision': 1,
        'schemaRevision': 1,
        'column': {'id': '', 'name': 'Amount', 'type': 'number'},
      });
      final changedTable = await run('read-columns', {
        'action': 'read',
        'tableId': tableId,
      }) as Map;
      final amount = (changedTable['columns'] as List).singleWhere(
        (column) => column['name'] == 'Amount',
      )['id'];
      final view = await command('cloud-view', {
        'action': 'createView',
        'tableId': tableId,
        'revision': 2,
        'schemaRevision': 2,
        'name': 'Overview',
        'columnIds': [label],
      });
      final editedView = await command('cloud-view-edit', {
        'action': 'saveView',
        'id': view['id'],
        'revision': 1,
        'schemaRevision': 2,
        'name': 'Updated overview',
        'bindings': {'amount': amount},
        'definition': {
          'version': 1,
          'components': [
            {
              'id': 'root',
              'component': 'Text',
              'text': 'Updated cloud surface',
            },
          ],
        },
      });
      expect(editedView['revision'], 2);
      expect(
        (await run('view-read', {
          'action': 'read',
          'id': view['id'],
        })).toString(),
        contains('Updated cloud surface'),
      );
      await command('cloud-table-rename', {
        'action': 'renameTable',
        'tableId': tableId,
        'revision': 2,
        'schemaRevision': 2,
        'name': 'Updated table',
      });
      final folder = await command('cloud-folder', {
        'action': 'createFolder',
        'name': 'Group',
      });
      await command('cloud-folder-rename', {
        'action': 'renameFolder',
        'id': folder['id'],
        'revision': 1,
        'name': 'Updated group',
      });
      final createdItems = await run('list-created', {
        'action': 'listCreated',
      }) as Map;
      final listed = (createdItems['items'] as List).cast<Map>();
      expect(
        listed.map((item) => item['id']),
        containsAll([tableId, view['id'], folder['id']]),
      );
      expect(
        listed.singleWhere((item) => item['id'] == folder['id'])['name'],
        'Updated group',
      );
      expect(listed.map((item) => item['id']), isNot(contains('items')));
      expect(listed.every((item) => !item.containsKey('parentId')), isTrue);
      expect(createdItems['nextCursor'], isNull);
      final pagingCalls = <ConversationToolCall>[];
      for (var index = 0; index < 101; index++) {
        pagingCalls.add(
          await ConversationToolCall.db.insertRow(
            session,
            ConversationToolCall(
              workspaceId: workspace.id!,
              conversationId: conversation.id!,
              turnId: turn.id!,
              messageId: assistant.id!,
              stableId: '000-page-${index.toString().padLeft(3, '0')}',
              name: workspaceCommandToolName,
              argumentsJson: '{"action":"read"}',
              argumentsDigest: 'fixture',
              status: 'success',
              resultJson: '{}',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          ),
        );
      }
      try {
        final page = await run('list-first-page', {
          'action': 'listCreated',
        }) as Map;
        expect(page['items'], isEmpty);
        expect(page['nextCursor'], '000-page-099');
        final nextPage = await run('list-second-page', {
          'action': 'listCreated',
          'cursor': page['nextCursor'],
        }) as Map;
        expect(
          (nextPage['items'] as List).map((item) => (item as Map)['id']),
          containsAll([tableId, view['id'], folder['id']]),
        );
        expect(nextPage['nextCursor'], isNull);
      } finally {
        for (final call in pagingCalls) {
          await ConversationToolCall.db.deleteRow(session, call);
        }
      }
      final beyondEnd = await run('list-created-cursor', {
        'action': 'listCreated',
        'cursor': 'zzzzzzzzzzzzzzzz',
      }) as Map;
      expect(beyondEnd['items'], isEmpty);
      expect(beyondEnd['nextCursor'], isNull);
      await expectLater(
        run('list-created-invalid-cursor', {
          'action': 'listCreated',
          'cursor': '',
        }),
        throwsA(
          isA<AgentToolExecutionFailure>().having(
            (failure) => failure.responseRaw,
            'safe message',
            contains('invalid'),
          ),
        ),
      );
      final owner = (await WorkspaceMember.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspace.id!) & row.userId.equals(userId),
      ))!;
      final revokeDuringRead = WorkspaceConversationCommands(
        beforeReadVerification: () async {
          await WorkspaceMember.db.updateRow(
            session,
            owner.copyWith(removedAt: DateTime.now().toUtc()),
          );
        },
      );
      try {
        await expectLater(
          revokeDuringRead.call(session, turn, 'list-revoked-during-read', {
            'action': 'listCreated',
          }),
          throwsA(isA<CloudWorkspaceException>()),
        );
      } finally {
        await WorkspaceMember.db.updateRow(session, owner);
      }
      final history = <Map<String, dynamic>>[
        {'role': 'user', 'content': 'Create a record'},
        {
          'role': 'assistant',
          'tool_calls': [
            {
              'id': 'created-record',
              'type': 'function',
              'function': {
                'name': workspaceCommandToolName,
                'arguments': '{"values":"Raw argument secret"}',
              },
            },
          ],
        },
        {
          'role': 'tool',
          'tool_call_id': 'created-record',
          'content': 'Archived unselected value',
        },
      ];
      final fresh = await const WorkspacePromptProjection().call(
        session,
        turn,
        history,
      );
      expect(jsonEncode(fresh), contains('Current selected value'));
      final createResult = jsonDecode(rowCall.resultJson!) as Map;
      final projectedResult = jsonDecode(fresh[2]['content'] as String) as Map;
      final projectedCurrent = projectedResult['current'] as Map;
      final projectedRecords = (projectedCurrent['records'] as List)
          .cast<Map>();
      expect(projectedRecords, hasLength(1));
      expect(projectedRecords.single['id'], createResult['id']);
      expect(
        projectedRecords.single['values'][label],
        'Current selected value',
      );
      expect(
        jsonEncode(projectedRecords),
        isNot(contains('Unrelated selected value')),
      );
      final projectedCall = (fresh[1]['tool_calls'] as List).single as Map;
      expect(
        jsonDecode((projectedCall['function'] as Map)['arguments'] as String),
        {'action': 'createRecord'},
      );
      expect(jsonDecode(fresh[2]['content'] as String)['outcome'], 'success');
      expect(jsonEncode(fresh), isNot(contains('Archived unselected value')));
      expect(jsonEncode(fresh), isNot(contains('Raw argument secret')));
      await ConversationToolCall.db.updateRow(
        session,
        rowCall.copyWith(
          status: 'executionError',
          resultJson: jsonEncode({'code': 'conflict', 'error': 'secret'}),
        ),
      );
      final failedProjection = await const WorkspacePromptProjection().call(
        session,
        turn,
        history,
      );
      expect(failedProjection[2]['content'], contains('Read it again'));
      expect(failedProjection[2]['content'], isNot(contains('secret')));
      await ConversationToolCall.db.updateRow(session, rowCall);
      final old = await const WorkspacePromptProjection().call(
        session,
        turn,
        [
          ...history,
          {'role': 'user', 'content': 'Later'},
        ],
      );
      final oldCall = (old[1]['tool_calls'] as List).single as Map;
      expect(
        jsonDecode((oldCall['function'] as Map)['arguments'] as String),
        {'action': 'read'},
      );
      await select(null);
      await expectLater(
        run('list-created-revoked', {'action': 'listCreated'}),
        throwsA(isA<AgentToolExecutionFailure>()),
      );
      final revoked = await const WorkspacePromptProjection().call(
        session,
        turn,
        history,
      );
      expect(jsonEncode(revoked), isNot(contains('Current selected value')));
      expect(jsonEncode(revoked), contains(workspaceContextUnavailable));

      for (final replace in [false, true]) {
        await select(selection);
        final beforeRace = (await WorkspaceResource.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(workspace.id!) &
              row.resourceKind.equals(WorkspaceResourceKind.table) &
              row.resourceId.equals('items'),
        ))!;
        final command = WorkspaceConversationCommands(
          beforeMutation: () async {
            await select(
              replace
                  ? WorkspaceContextSelection(
                      workspaceId: '${workspace.id}',
                      conversationId: conversation.stableId,
                      itemId: 'items',
                      kind: 'table',
                    )
                  : null,
            );
          },
        );
        await expectLater(
          command.call(session, turn, 'selection-race-$replace', {
            'action': 'renameTable',
            'tableId': 'items',
            'id': 'items',
            'revision': beforeRace.revision,
            'schemaRevision':
                (jsonDecode(beforeRace.data) as Map)['schemaRevision'],
            'name': 'Unauthorized race edit',
          }),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.permissionDenied,
            ),
          ),
        );
        final afterRace = await WorkspaceResource.db.findById(
          session,
          beforeRace.id!,
        );
        expect(afterRace!.revision, beforeRace.revision);
        expect(afterRace.data, beforeRace.data);
      }

      for (final replace in [false, true]) {
        final beforeView = (await WorkspaceView.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(workspace.id!) &
              row.stableId.equals(view['id'] as String),
        ))!;
        await select(
          WorkspaceContextSelection(
            workspaceId: '${workspace.id}',
            conversationId: conversation.stableId,
            itemId: beforeView.stableId,
            kind: 'view',
          ),
        );
        final command = WorkspaceConversationCommands(
          beforeMutation: () async {
            await select(replace ? selection : null);
          },
        );
        await expectLater(
          command.call(session, turn, 'view-race-$replace', {
            'action': 'saveView',
            'id': beforeView.stableId,
            'revision': beforeView.revision,
            'schemaRevision': 2,
            'name': 'Denied race edit',
            'bindings': {'amount': amount},
            'definition': {
              'version': 1,
              'components': [
                {'id': 'root', 'component': 'Text', 'text': 'Denied race'},
              ],
            },
          }),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.permissionDenied,
            ),
          ),
        );
        final afterView = await WorkspaceView.db.findById(
          session,
          beforeView.id!,
        );
        expect(afterView!.revision, beforeView.revision);
        expect(afterView.data, beforeView.data);
      }

      final rootSelection = WorkspaceContextSelection(
        workspaceId: '${workspace.id}',
        conversationId: conversation.stableId,
        itemId: '',
        kind: 'directory',
      );
      await select(rootSelection);
      const cachedCreate = {'action': 'createFolder', 'name': 'Cached folder'};
      final originalCreate = await const WorkspaceConversationCommands().call(
        session,
        turn,
        'cached-protected-write',
        cachedCreate,
      ) as Map;
      await select(rootSelection);
      final cachedReplay = WorkspaceConversationCommands(
        beforeMutation: () async {
          await select(null);
        },
      );
      await expectLater(
        cachedReplay.call(
          session,
          turn,
          'cached-protected-write',
          cachedCreate,
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.permissionDenied,
          ),
        ),
      );
      final originalFolder = (await WorkspaceResource.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspace.id!) &
            row.resourceKind.equals(WorkspaceResourceKind.folder) &
            row.resourceId.equals(originalCreate['id'] as String),
      ))!;
      expect(originalFolder.revision, 1);

      final memberId = const Uuid().v4().toString();
      final memberAuth = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          memberId,
          const {},
        ),
      );
      await AuthUser.db.insertRow(
        session,
        AuthUser(id: UuidValue.fromString(memberId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        session,
        EmailAccount(
          authUserId: UuidValue.fromString(memberId),
          email: '$memberId@example.com',
          passwordHash: 'unused',
        ),
      );
      final _ = await WorkspaceMember.db.insertRow(
        session,
        WorkspaceMember(
          workspaceId: workspace.id!,
          userId: memberId,
          role: 'member',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      Future<void> setAccess(String? access) async {
        final table = (await WorkspaceResource.db.findFirstRow(
          session,
          where: (row) =>
              row.workspaceId.equals(workspace.id) &
              row.resourceKind.equals(WorkspaceResourceKind.table) &
              row.resourceId.equals('items'),
        ))!;
        final data = jsonDecode(table.data) as Map<String, dynamic>;
        data['memberAccess'] = {memberId: ?access};
        await patch([
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .table,
            resourceId: 'items',
            expectedRevision: table.revision,
            data: jsonEncode(data),
            fieldMask: [],
          ),
        ]);
      }

      await setAccess('edit');
      final memberTurn = await ConversationTurn.db.insertRow(
        session,
        ConversationTurn(
          workspaceId: workspace.id!,
          conversationId: conversation.id!,
          requestId: 'member-turn',
          requestHash: 'fixture',
          initiatorUserId: memberId,
          status: 'running',
          revision: 1,
          acceptedSequence: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      Future<Object?> memberRun(String id, Map<String, dynamic> arguments) =>
          const ServerToolExecutorService().call(
            session,
            memberTurn,
            tool,
            ServerToolRequest(
              id: id,
              name: workspaceCommandToolName,
              arguments: arguments,
              isCancelled: () async => false,
            ),
          );
      await expectLater(
        memberRun('no-inherited-consent', {
          'action': 'read',
          'tableId': 'items',
        }),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.permissionDenied,
          ),
        ),
      );
      final _ = await endpoints.workspaceContext.save(
        memberAuth,
        workspace.id!,
        conversation.stableId,
        'member-selection',
        jsonEncode(selection.toJson()),
      );
      expect(
        (await memberRun('member-read', {
          'action': 'read',
          'tableId': 'items',
        })).toString(),
        contains('Edited'),
      );
      final memberEdit = {
        'action': 'updateRecord',
        'tableId': 'items',
        'id': 'selected',
        'revision': 2,
        'schemaRevision': 1,
        'values': {'title': 'Member edit'},
      };
      await memberRun('member-edit', memberEdit);
      await setAccess('read');
      await expectLater(
        memberRun('member-edit', memberEdit),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.permissionDenied,
          ),
        ),
      );
      expect(
        (await memberRun('readonly-read', {
          'action': 'read',
          'tableId': 'items',
        })).toString(),
        contains('Member edit'),
      );
      await setAccess(null);
      await expectLater(
        memberRun('revoked-read', {'action': 'read', 'tableId': 'items'}),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.permissionDenied,
          ),
        ),
      );
      await endpoints.cloudWorkspace.removeMember(
        authenticated,
        RemoveWorkspaceMemberRequest(
          workspaceId: workspace.id!,
          userId: memberId,
          requestId: 'remove-member',
          expectedMemberRevision: 1,
        ),
      );
      await expectLater(
        memberRun('removed-member', {'action': 'read', 'tableId': 'items'}),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.permissionDenied,
          ),
        ),
      );
      await patch([
        WorkspacePatchOperation(
          operation: .create,
          resourceKind: .table,
          resourceId: 'ref-target',
          fieldMask: [],
          data: jsonEncode({
            'name': 'Target',
            'labelColumnId': 'target-title',
            'schemaRevision': 1,
            'columns': [
              {'id': 'target-title', 'name': 'Title', 'type': 'text'},
            ],
          }),
        ),
      ]);
      await patch([
        for (final id in ['ref-retained', 'ref-guessed'])
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .tableRecord,
            resourceId: id,
            fieldMask: [],
            data: jsonEncode({
              'tableId': 'ref-target',
              'schemaRevision': 1,
              'values': {'target-title': 'Hidden target'},
            }),
          ),
      ]);
      await patch([
        WorkspacePatchOperation(
          operation: .create,
          resourceKind: .table,
          resourceId: 'ref-source',
          fieldMask: [],
          data: jsonEncode({
            'name': 'Source',
            'labelColumnId': 'source-title',
            'schemaRevision': 1,
            'columns': [
              {'id': 'source-title', 'name': 'Title', 'type': 'text'},
              {
                'id': 'link',
                'name': 'Related',
                'type': 'reference',
                'targetTableId': 'ref-target',
                'defaultValue': 'ref-retained',
              },
            ],
          }),
        ),
      ]);
      await patch([
        WorkspacePatchOperation(
          operation: .create,
          resourceKind: .tableRecord,
          resourceId: 'ref-selected',
          fieldMask: [],
          data: jsonEncode({
            'tableId': 'ref-source',
            'schemaRevision': 1,
            'values': {'source-title': 'Selected', 'link': 'ref-retained'},
          }),
        ),
      ]);
      await select(
        WorkspaceContextSelection(
          workspaceId: '${workspace.id}',
          conversationId: conversation.stableId,
          itemId: 'ref-source',
          kind: 'table',
          recordIds: ['ref-selected'],
        ),
      );
      final scopedReferences = await run('read-reference-scope', {
        'action': 'read',
        'tableId': 'ref-source',
      });
      expect(scopedReferences.toString(), isNot(contains('ref-retained')));
      expect(scopedReferences.toString(), isNot(contains('ref-target')));
      expect(scopedReferences.toString(), isNot(contains('Hidden target')));
      final _ = await ConversationToolCall.db.insertRow(
        session,
        ConversationToolCall(
          workspaceId: workspace.id!,
          conversationId: conversation.id!,
          turnId: turn.id!,
          messageId: assistant.id!,
          stableId: 'archived-reference-read',
          name: workspaceCommandToolName,
          argumentsJson: '{"action":"read","tableId":"ref-source"}',
          argumentsDigest: 'fixture',
          status: 'success',
          resultJson: jsonEncode({
            'records': [
              {'link': 'ref-retained', 'label': 'Hidden target'},
            ],
          }),
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final referenceHistory = <Map<String, dynamic>>[
        {
          'role': 'assistant',
          'tool_calls': [
            {
              'id': 'archived-reference-read',
              'type': 'function',
              'function': {
                'name': workspaceCommandToolName,
                'arguments': '{"secret":"Hidden target"}',
              },
            },
          ],
        },
        {
          'role': 'tool',
          'tool_call_id': 'archived-reference-read',
          'content': 'ref-retained Hidden target',
        },
      ];
      final referencePrompt = await const WorkspacePromptProjection().call(
        session,
        turn,
        referenceHistory,
      );
      expect(jsonEncode(referencePrompt), contains('Selected'));
      expect(jsonEncode(referencePrompt), isNot(contains('ref-retained')));
      expect(jsonEncode(referencePrompt), isNot(contains('Hidden target')));
      await select(null);
      final revokedReferencePrompt = await const WorkspacePromptProjection()
          .call(session, turn, referenceHistory);
      expect(
        jsonEncode(revokedReferencePrompt),
        contains(workspaceContextUnavailable),
      );
      expect(jsonEncode(revokedReferencePrompt), isNot(contains('Selected')));
      await select(
        WorkspaceContextSelection(
          workspaceId: '${workspace.id}',
          conversationId: conversation.stableId,
          itemId: 'ref-source',
          kind: 'table',
          recordIds: ['ref-selected'],
        ),
      );
      final otherWorkspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'Other workspace',
            ownerUserId: userId,
            now: now,
          );
      await endpoints.workspaceState.patch(
        authenticated,
        PatchWorkspaceStateRequest(
          workspaceId: otherWorkspace.id!,
          requestId: 'foreign-reference-table',
          operations: [
            WorkspacePatchOperation(
              operation: .create,
              resourceKind: .table,
              resourceId: 'foreign-target',
              fieldMask: [],
              data: jsonEncode({
                'name': 'Foreign target',
                'labelColumnId': 'foreign-title',
                'schemaRevision': 1,
                'columns': [
                  {'id': 'foreign-title', 'name': 'Title', 'type': 'text'},
                ],
              }),
            ),
          ],
        ),
      );
      await endpoints.workspaceState.patch(
        authenticated,
        PatchWorkspaceStateRequest(
          workspaceId: otherWorkspace.id!,
          requestId: 'foreign-reference-record',
          operations: [
            WorkspacePatchOperation(
              operation: .create,
              resourceKind: .tableRecord,
              resourceId: 'foreign-record',
              fieldMask: [],
              data: jsonEncode({
                'tableId': 'foreign-target',
                'schemaRevision': 1,
                'values': {'foreign-title': 'Foreign workspace secret'},
              }),
            ),
          ],
        ),
      );

      var referenceSequence = 0;
      for (final input in [
        {
          'action': 'saveColumn',
          'column': {
            'id': '',
            'name': 'Guessed',
            'type': 'reference',
            'targetTableId': 'ref-target',
          },
        },
        {
          'action': 'saveColumn',
          'column': {
            'id': '',
            'name': 'Foreign workspace',
            'type': 'reference',
            'targetTableId': 'foreign-target',
          },
        },
        {
          'action': 'saveColumn',
          'column': {
            'id': 'link',
            'name': 'Related',
            'type': 'reference',
            'defaultValue': 'ref-guessed',
          },
        },
        {
          'action': 'createRecord',
          'values': {'source-title': 'Guess', 'link': 'ref-guessed'},
        },
        {
          'action': 'createRecord',
          'values': {'source-title': 'Default guess'},
        },
        {
          'action': 'createRecord',
          'values': {
            'source-title': 'Foreign workspace',
            'link': 'foreign-record',
          },
        },
        {
          'action': 'updateRecord',
          'id': 'ref-selected',
          'values': {
            'source-title': 'Guess',
            'link': 'ref-guessed',
          },
        },
      ]) {
        await expectLater(
          run('reject-reference-${referenceSequence++}', {
            'tableId': 'ref-source',
            'revision': 1,
            'schemaRevision': 1,
            ...input,
          }),
          throwsA(
            isA<AgentToolExecutionFailure>().having(
              (failure) => failure.responseRaw,
              'safe message',
              contains('unavailable'),
            ),
          ),
        );
      }
      final _ = await run('preserve-hidden-reference', {
        'action': 'updateRecord',
        'tableId': 'ref-source',
        'id': 'ref-selected',
        'revision': 1,
        'schemaRevision': 1,
        'values': {'source-title': 'Edited'},
      });
      final retainedRow = (await WorkspaceResource.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspace.id!) &
            row.resourceKind.equals(WorkspaceResourceKind.tableRecord) &
            row.resourceId.equals('ref-selected'),
      ))!;
      expect(
        (jsonDecode(retainedRow.data) as Map)['values']['link'],
        'ref-retained',
      );
      expect(retainedRow.revision, 2);
      final _ = await run('rename-retained-column', {
        'action': 'saveColumn',
        'tableId': 'ref-source',
        'revision': 1,
        'schemaRevision': 1,
        'column': {'id': 'link', 'name': 'Renamed', 'type': 'reference'},
      });
    });
  });
}

class _FileStore extends UnconfiguredObjectStore {
  const _FileStore();

  @override
  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
    String? registrationId,
  }) async => SignedObjectRequest(
    url: Uri.parse('https://example.invalid/private'),
    headers: const {},
    expiresAt: DateTime.now().toUtc().add(expiresIn),
  );
}

class _SlowFileStore extends _FileStore {
  const _SlowFileStore();

  @override
  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
    String? registrationId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return super.signGet(
      key: key,
      contentDisposition: contentDisposition,
      expiresIn: expiresIn,
      registrationId: registrationId,
    );
  }
}
