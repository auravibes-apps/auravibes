import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:auravibes_server/src/features/conversations/engine/workspace_conversation_commands.dart';
import 'package:auravibes_server/src/features/conversations/engine/workspace_conversation_file.dart';
import 'package:auravibes_server/src/features/conversations/engine/workspace_prompt_projection.dart';
import 'package:auravibes_server/src/features/objects/object_store.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Workspace file tool result privacy', (builder, endpoints) {
    test('prompt projection never refetches archived file content', () async {
      final userId = const Uuid().v4().toString();
      final authenticated = builder.copyWith(
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
          email: '$userId@example.invalid',
          passwordHash: 'unused',
        ),
      );
      final now = DateTime.now().toUtc();
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'Files',
            ownerUserId: userId,
            now: now,
          );
      final conversation = await Conversation.db.insertRow(
        session,
        Conversation(
          workspaceId: workspace.id!,
          stableId: 'file-privacy-$userId',
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
          requestId: 'turn-$userId',
          requestHash: 'fixture',
          initiatorUserId: userId,
          status: 'running',
          revision: 1,
          acceptedSequence: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final assistant = await ConversationMessage.db.insertRow(
        session,
        ConversationMessage(
          workspaceId: workspace.id!,
          conversationId: conversation.id!,
          stableId: 'assistant-$userId',
          role: 'assistant',
          kind: 'text',
          status: 'sent',
          content: '',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
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
      final selection = WorkspaceContextSelection(
        workspaceId: '${workspace.id}',
        conversationId: conversation.stableId,
        itemId: 'note',
        kind: 'file',
      );
      await endpoints.workspaceContext.save(
        authenticated,
        workspace.id!,
        conversation.stableId,
        'select-$userId',
        jsonEncode(selection.toJson()),
      );
      var fileFetches = 0;
      final commands = WorkspaceConversationCommands(
        fileReader: WorkspaceConversationFile(
          store: const _Store(),
          fetch: (_, _) async {
            fileFetches++;
            return utf8.encode('hello');
          },
        ),
      );
      final runtime = ServerToolRuntime(
        executor: (session, turn, tool, request) => commands.call(
          session,
          turn,
          request.id,
          workspaceToolArgumentsForExecution(
            tool.descriptor.toolIdentifier,
            request.arguments,
          ),
        ),
      );
      await runtime.handle(
        session,
        turn: turn,
        messageId: assistant.id!,
        request: const ServerToolRequest(
          id: 'private-file-read',
          name: workspaceReadItemToolName,
          arguments: {'itemId': 'note'},
        ),
      );
      expect(fileFetches, 1);
      final call = (await ConversationToolCall.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspace.id!) &
            row.stableId.equals('private-file-read'),
      ))!;
      expect(call.status, 'success');
      expect(call.resultJson, isNot(contains('hello')));
      final unexpected = ServerToolRuntime(
        executor: (_, _, _, _) async => {
          'unexpected': 'private body',
          'name': {'content': 'nested private body'},
        },
      );
      await unexpected.handle(
        session,
        turn: turn,
        messageId: assistant.id!,
        request: const ServerToolRequest(
          id: 'unexpected-file-read',
          name: workspaceReadItemToolName,
          arguments: {'itemId': 'note'},
        ),
      );
      final unexpectedCall = (await ConversationToolCall.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspace.id!) &
            row.stableId.equals('unexpected-file-read'),
      ))!;
      expect(unexpectedCall.resultJson, isNot(contains('private body')));
      final history = <Map<String, dynamic>>[
        {'role': 'user', 'content': 'Read file'},
        {
          'role': 'assistant',
          'tool_calls': [
            {
              'id': 'private-file-read',
              'type': 'function',
              'function': {
                'name': workspaceReadItemToolName,
                'arguments': jsonEncode({'itemId': 'note'}),
              },
            },
          ],
        },
        {
          'role': 'tool',
          'tool_call_id': 'private-file-read',
          'content': call.resultJson,
        },
      ];
      final projection = const WorkspacePromptProjection();
      expect(
        jsonEncode(await projection.call(session, turn, history)),
        isNot(contains('hello')),
      );
      expect(fileFetches, 1);
      await endpoints.workspaceContext.save(
        authenticated,
        workspace.id!,
        conversation.stableId,
        'revoke-$userId',
        null,
      );
      final archived = await projection.call(session, turn, [
        ...history,
        {'role': 'user', 'content': 'A later request.'},
      ]);
      expect(jsonEncode(archived), isNot(contains('hello')));
      await ConversationMessage.db.updateRow(
        session,
        assistant.copyWith(turnId: turn.id),
      );
      for (final status in ['success', 'pending']) {
        await ConversationToolCall.db.insertRow(
          session,
          ConversationToolCall(
            workspaceId: workspace.id!,
            conversationId: conversation.id!,
            turnId: turn.id!,
            messageId: assistant.id!,
            stableId: 'mutation-$status',
            name: workspaceUpdateRecordToolName,
            argumentsJson:
                '{"tableId":"secret-table","values":{"title":"secret-value"}}',
            argumentsDigest: 'fixture',
            status: status,
            resultJson: '{"id":"secret-record"}',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      final snapshot = await endpoints.conversation.getConversationSnapshot(
        authenticated,
        GetConversationRequest(
          workspaceId: workspace.id!,
          conversationId: conversation.stableId,
        ),
      );
      final completed = snapshot.toolCalls.singleWhere(
        (value) => value.id == 'mutation-success',
      );
      expect(completed.argumentsJson, '{}');
      expect(completed.resultJson, '{}');
      final pending = snapshot.toolCalls.singleWhere(
        (value) => value.id == 'mutation-pending',
      );
      expect(pending.argumentsJson, contains('secret-value'));
    });
  });
}

class _Store extends UnconfiguredObjectStore {
  const _Store();
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
