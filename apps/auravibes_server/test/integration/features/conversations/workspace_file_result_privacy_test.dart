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
    test('history excludes file content while provider gets fresh authorized bytes', () async {
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
      final commands = WorkspaceConversationCommands(
        fileReader: WorkspaceConversationFile(
          store: const _Store(),
          fetch: (_, _) async => utf8.encode('hello'),
        ),
      );
      final runtime = ServerToolRuntime(
        executor: (session, turn, tool, request) =>
            commands.call(session, turn, request.id, request.arguments),
      );
      await runtime.handle(
        session,
        turn: turn,
        messageId: assistant.id!,
        request: const ServerToolRequest(
          id: 'private-file-read',
          name: workspaceCommandToolName,
          arguments: {'action': 'read', 'id': 'note'},
        ),
      );
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
          name: workspaceCommandToolName,
          arguments: {'action': 'read', 'id': 'note'},
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
              'function': {'name': workspaceCommandToolName, 'arguments': '{}'},
            },
          ],
        },
        {
          'role': 'tool',
          'tool_call_id': 'private-file-read',
          'content': call.resultJson,
        },
      ];
      final projection = WorkspacePromptProjection(commands: commands);
      expect(
        jsonEncode(await projection.call(session, turn, history)),
        contains('hello'),
      );
      await endpoints.workspaceContext.save(
        authenticated,
        workspace.id!,
        conversation.stableId,
        'revoke-$userId',
        null,
      );
      expect(
        jsonEncode(await projection.call(session, turn, history)),
        isNot(contains('hello')),
      );
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
