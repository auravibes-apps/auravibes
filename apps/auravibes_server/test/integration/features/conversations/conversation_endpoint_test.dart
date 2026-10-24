import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/domain/conversation_values.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  // Template execution opens a separate session that must see committed rows.
  withServerpod('ConversationAutoApproval', (sessionBuilder, endpoints) {
    Future<
      ({
        TestSessionBuilder session,
        Session database,
        int workspaceId,
        String userId,
      })
    >
    prepare() async {
      final userId = const Uuid().v4().toString();
      final session = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final database = session.build();
      await AuthUser.db.insertRow(
        database,
        AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        database,
        EmailAccount(
          authUserId: UuidValue.fromString(userId),
          email: '$userId@example.com',
          passwordHash: 'unused',
        ),
      );
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            database,
            name: 'Auto approval',
            ownerUserId: userId,
            now: DateTime.now().toUtc(),
          );
      return (
        session: session,
        database: database,
        workspaceId: workspace.id!,
        userId: userId,
      );
    }

    test(
      'persists mode through create, update, projection and root/child forks',
      () async {
        final fixture = await prepare();
        final root = await endpoints.conversation.create(
          fixture.session,
          CreateConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'create-root',
            conversationId: 'root',
            title: 'Root',
            isPinned: true,
            toolAccessMode: 'allow_all',
          ),
        );
        expect(root.toolAccessMode, 'allow_all');
        final child = await endpoints.conversation.create(
          fixture.session,
          CreateConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'create-child',
            toolAccessMode: 'future_mode',
            conversationId: 'child',
            title: 'Child',
            isPinned: false,
            parentConversationId: root.id,
          ),
        );
        expect(child.toolAccessMode, 'default');
        final now = DateTime.now().toUtc();
        for (final summary in [root, child]) {
          final row = (await Conversation.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.stableId.equals(summary.id),
          ))!;
          await ConversationMessage.db.insertRow(
            fixture.database,
            ConversationMessage(
              workspaceId: fixture.workspaceId,
              conversationId: row.id!,
              stableId: '${summary.id}-message',
              role: 'assistant',
              kind: 'text',
              status: ConversationStatuses.completed,
              content: 'Finished',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
          final fork = await endpoints.conversation.fork(
            fixture.session,
            ForkConversationRequest(
              workspaceId: fixture.workspaceId,
              requestId: 'fork-${summary.id}',
              sourceConversationId: summary.id,
              forkConversationId: '${summary.id}-fork',
              throughMessageId: '${summary.id}-message',
            ),
          );
          expect(fork.toolAccessMode, 'allow_all');
        }
        final updated = await endpoints.conversation.update(
          fixture.session,
          UpdateConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'disable-root',
            conversationId: root.id,
            expectedRevision: root.revision,
            toolAccessMode: 'default',
            clearModel: false,
            clearAgent: false,
            clearReasoningConfig: false,
            clearParent: false,
          ),
        );
        expect(updated.toolAccessMode, 'default');
        expect(updated.title, root.title);
        expect(updated.isPinned, root.isPinned);
        expect(updated.modelId, root.modelId);
        expect(updated.agentId, root.agentId);
        final renamed = await endpoints.conversation.update(
          fixture.session,
          UpdateConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'rename-root-fork',
            conversationId: 'root-fork',
            expectedRevision: 1,
            title: 'Renamed',
            clearModel: false,
            clearAgent: false,
            clearReasoningConfig: false,
            clearParent: false,
          ),
        );
        expect(renamed.toolAccessMode, 'allow_all');
        expect(
          (await endpoints.conversation.get(
            fixture.session,
            GetConversationRequest(
              workspaceId: fixture.workspaceId,
              conversationId: 'root-fork',
            ),
          )).toolAccessMode,
          'allow_all',
        );
        expect(
          (await endpoints.conversation.getConversationSnapshot(
            fixture.session,
            GetConversationRequest(
              workspaceId: fixture.workspaceId,
              conversationId: 'root-fork',
            ),
          )).conversation.toolAccessMode,
          'allow_all',
        );
        final page = await endpoints.conversation.listPage(
          fixture.session,
          ListConversationsRequest(workspaceId: fixture.workspaceId, limit: 10),
        );
        expect(
          page.conversations
              .singleWhere((row) => row.id == root.id)
              .toolAccessMode,
          'default',
        );
        expect(
          page.conversations
              .singleWhere((row) => row.id == renamed.id)
              .toolAccessMode,
          'allow_all',
        );
        final unknown = await endpoints.conversation.update(
          fixture.session,
          UpdateConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'unknown-mode-root-fork',
            conversationId: renamed.id,
            expectedRevision: renamed.revision,
            toolAccessMode: 'future_mode',
            clearModel: false,
            clearAgent: false,
            clearReasoningConfig: false,
            clearParent: false,
          ),
        );
        expect(unknown.toolAccessMode, 'default');
        expect(unknown.title, renamed.title);
      },
    );

    test(
      'server mode honors current root, denial priority and pending calls',
      () async {
        final fixture = await prepare();
        final now = DateTime.now().toUtc();
        Future<Conversation> conversation(
          String id, {
          String? parent,
          String mode = 'default',
        }) => Conversation.db.insertRow(
          fixture.database,
          Conversation(
            workspaceId: fixture.workspaceId,
            stableId: id,
            title: id,
            isPinned: false,
            parentConversationStableId: parent,
            toolAccessMode: mode,
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final root = await conversation('root');
        var child = await conversation(
          'child',
          parent: root.stableId,
          mode: 'allow_all',
        );
        final turn = await ConversationTurn.db.insertRow(
          fixture.database,
          ConversationTurn(
            workspaceId: fixture.workspaceId,
            conversationId: child.id!,
            requestId: 'turn',
            requestHash: 'hash',
            initiatorUserId: fixture.userId,
            status: 'running',
            revision: 1,
            acceptedSequence: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final message = await ConversationMessage.db.insertRow(
          fixture.database,
          ConversationMessage(
            workspaceId: fixture.workspaceId,
            conversationId: child.id!,
            turnId: turn.id,
            stableId: 'message',
            role: 'assistant',
            kind: 'text',
            status: 'running',
            content: '',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        var executions = 0;
        final runtime = ServerToolRuntime(
          executor: (_, _, _, _) async {
            executions++;
            return 'ok';
          },
        );
        Future<String> call(
          String id, {
          String name = listConnectorConnectionsToolName,
          Map<String, dynamic> arguments = const {},
        }) async {
          await runtime.handle(
            fixture.database,
            turn: turn,
            messageId: message.id!,
            request: ServerToolRequest(
              id: id,
              name: name,
              arguments: arguments,
            ),
          );
          return (await ConversationToolCall.db.findFirstRow(
            fixture.database,
            where: (table) =>
                table.workspaceId.equals(fixture.workspaceId) &
                table.stableId.equals(id),
          ))!.status;
        }

        Future<void> resource(
          WorkspaceResourceKind kind,
          String id,
          Map<String, Object?> data,
        ) async {
          await WorkspaceResource.db.insertRow(
            fixture.database,
            WorkspaceResource(
              workspaceId: fixture.workspaceId,
              resourceKind: kind,
              resourceId: id,
              data: jsonEncode(data),
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }

        expect(await call('pending-before-mode'), 'pending');
        await endpoints.conversation.update(
          fixture.session,
          UpdateConversationRequest(
            workspaceId: fixture.workspaceId,
            requestId: 'enable-root',
            conversationId: root.stableId,
            expectedRevision: 1,
            toolAccessMode: 'allow_all',
            clearModel: false,
            clearAgent: false,
            clearReasoningConfig: false,
            clearParent: false,
          ),
        );
        expect(await call('pending-before-mode'), 'pending');
        expect(executions, 0);
        expect(await call('new-after-mode'), 'success');
        expect(executions, 1);
        expect(await call('unknown', name: 'missing_tool'), 'toolNotFound');
        expect(executions, 1);
        child = await Conversation.db.updateRow(
          fixture.database,
          child.copyWith(agentId: 'agent'),
        );
        await resource(WorkspaceResourceKind.agentAssociation, 'deny-agent', {
          'agentId': 'agent',
          'toolId': listConnectorConnectionsToolName,
          'permissionMode': 'alwaysDeny',
        });
        expect(await call('agent-deny-no-workspace'), 'disabledInWorkspace');
        await resource(
          WorkspaceResourceKind.conversationToolSelection,
          'conversation-policy',
          {
            'conversationId': child.stableId,
            'toolId': listConnectorConnectionsToolName,
            'permissionMode': 'alwaysAsk',
          },
        );
        expect(
          await call('agent-deny-conversation-ask'),
          'disabledInWorkspace',
        );
        final policy = (await WorkspaceResource.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.resourceId.equals('conversation-policy'),
        ))!;
        await WorkspaceResource.db.updateRow(
          fixture.database,
          policy.copyWith(
            data: jsonEncode({
              'conversationId': child.stableId,
              'toolId': listConnectorConnectionsToolName,
              'permissionMode': 'alwaysAllow',
            }),
          ),
        );
        expect(
          await call('explicit-conversation-grant-agent-deny'),
          'disabledInWorkspace',
        );
        expect(executions, 1);
        final deniedAgentPolicy = (await WorkspaceResource.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.resourceId.equals('deny-agent'),
        ))!;
        await WorkspaceResource.db.updateRow(
          fixture.database,
          deniedAgentPolicy.copyWith(
            data: jsonEncode({
              'agentId': 'agent',
              'toolId': listConnectorConnectionsToolName,
              'permissionMode': 'alwaysAsk',
            }),
          ),
        );
        expect(await call('explicit-conversation-grant'), 'success');
        expect(executions, 2);
        await resource(
          WorkspaceResourceKind.toolPermission,
          'disabled-tool-config',
          {
            'toolId': listConnectorConnectionsToolName,
            'isEnabled': false,
            'permissionMode': 'alwaysAllow',
          },
        );
        final disabledConfig = (await WorkspaceResource.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.resourceId.equals('disabled-tool-config'),
        ))!;
        var currentRoot = (await Conversation.db.findById(
          fixture.database,
          root.id!,
        ))!;
        for (final mode in ['default', 'allow_all']) {
          currentRoot = await Conversation.db.updateRow(
            fixture.database,
            currentRoot.copyWith(toolAccessMode: mode),
          );
          expect(
            await call('disabled-config-conversation-grant-$mode'),
            'disabledInWorkspace',
          );
          expect(executions, 2);
        }
        await WorkspaceResource.db.updateRow(
          fixture.database,
          disabledConfig.copyWith(deletedAt: now),
        );
        await WorkspaceResource.db.updateRow(
          fixture.database,
          policy.copyWith(
            data: jsonEncode({
              'conversationId': child.stableId,
              'toolId': listConnectorConnectionsToolName,
              'permissionMode': 'alwaysDeny',
            }),
          ),
        );
        expect(await call('explicit-conversation-deny'), 'disabledInWorkspace');
        await WorkspaceResource.db.updateRow(
          fixture.database,
          policy.copyWith(deletedAt: now),
        );
        final agentPolicy = (await WorkspaceResource.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.resourceId.equals('deny-agent'),
        ))!;
        await WorkspaceResource.db.updateRow(
          fixture.database,
          agentPolicy.copyWith(deletedAt: now),
        );
        await resource(
          WorkspaceResourceKind.conversationToolSelection,
          'parent-conversation-deny',
          {
            'conversationId': root.stableId,
            'toolId': listConnectorConnectionsToolName,
            'permissionMode': 'alwaysDeny',
          },
        );
        expect(
          await call('parent-conversation-deny'),
          'disabledInWorkspace',
        );
        expect(executions, 2);
        final parentDeny = (await WorkspaceResource.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.resourceId.equals('parent-conversation-deny'),
        ))!;
        await WorkspaceResource.db.updateRow(
          fixture.database,
          parentDeny.copyWith(deletedAt: now),
        );
        await resource(
          WorkspaceResourceKind.toolPermission,
          'workspace-policy',
          {
            'toolId': listConnectorConnectionsToolName,
            'permissionMode': 'alwaysDeny',
          },
        );
        expect(await call('workspace-deny'), 'disabledInWorkspace');
        final workspacePolicy = (await WorkspaceResource.db.findFirstRow(
          fixture.database,
          where: (table) =>
              table.workspaceId.equals(fixture.workspaceId) &
              table.resourceId.equals('workspace-policy'),
        ))!;
        await WorkspaceResource.db.updateRow(
          fixture.database,
          workspacePolicy.copyWith(deletedAt: now),
        );
        child = await Conversation.db.updateRow(
          fixture.database,
          child.copyWith(parentConversationStableId: 'missing'),
        );
        expect(await call('missing-parent'), 'pending');
        await Conversation.db.updateRow(
          fixture.database,
          child.copyWith(parentConversationStableId: child.stableId),
        );
        expect(await call('cyclic-parent'), 'pending');
        expect(executions, 2);
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);

  withServerpod('ConversationEndpoint', (sessionBuilder, endpoints) {
    test('persists stable IDs and rejects stale mutations', () async {
      final userId = const Uuid().v4().toString();
      final session = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final databaseSession = session.build();
      await AuthUser.db.insertRow(
        databaseSession,
        AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        databaseSession,
        EmailAccount(
          authUserId: UuidValue.fromString(userId),
          email: 'conversation@example.com',
          passwordHash: 'unused',
        ),
      );
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            databaseSession,
            name: 'Conversation workspace',
            ownerUserId: userId,
            now: DateTime.now().toUtc(),
          );
      final workspaceId = workspace.id!;

      await expectLater(
        endpoints.conversation.create(
          session,
          CreateConversationRequest(
            workspaceId: workspaceId,
            requestId: 'create-oversized-reasoning',
            conversationId: 'oversized-reasoning',
            title: 'Oversized reasoning',
            isPinned: false,
            reasoningConfigJson: '{"effort":"${'x' * 5000}"}',
          ),
        ),
        throwsA(
          isA<ConversationException>().having(
            (error) => error.code,
            'code',
            ConversationErrorCode.validationFailed,
          ),
        ),
      );

      final created = await endpoints.conversation.create(
        session,
        CreateConversationRequest(
          workspaceId: workspaceId,
          requestId: 'create-1',
          conversationId: 'conversation-1',
          title: 'Original',
          isPinned: false,
        ),
      );
      expect(created.id, 'conversation-1');
      expect(created.revision, 1);
      final replayed = await endpoints.conversation.create(
        session,
        CreateConversationRequest(
          workspaceId: workspaceId,
          requestId: 'create-1',
          conversationId: 'conversation-1',
          title: 'Original',
          isPinned: false,
        ),
      );
      expect(replayed.id, created.id);
      expect(
        await WorkspaceEvent.db.find(
          databaseSession,
          where: (table) => table.workspaceId.equals(workspaceId),
        ),
        hasLength(1),
      );
      expect(
        await WorkspaceAuditRecord.db.find(
          databaseSession,
          where: (table) => table.workspaceId.equals(workspaceId),
        ),
        hasLength(1),
      );
      expect(
        await WorkspaceMutationReceipt.db.find(
          databaseSession,
          where: (table) => table.workspaceId.equals(workspaceId),
        ),
        hasLength(1),
      );
      await expectLater(
        endpoints.conversation.create(
          session,
          CreateConversationRequest(
            workspaceId: workspaceId,
            requestId: 'create-1',
            conversationId: 'conversation-1',
            title: 'Changed body',
            isPinned: false,
          ),
        ),
        throwsA(isA<ConversationException>()),
      );

      final listed = await endpoints.conversation.list(
        session,
        ListConversationsRequest(workspaceId: workspaceId, limit: 20),
      );
      expect(listed.single.id, created.id);

      final updated = await endpoints.conversation.update(
        session,
        UpdateConversationRequest(
          workspaceId: workspaceId,
          requestId: 'update-1',
          conversationId: created.id,
          expectedRevision: created.revision,
          title: 'Renamed',
          clearModel: false,
          clearAgent: false,
          clearReasoningConfig: false,
          clearParent: false,
        ),
      );
      expect(updated.title, 'Renamed');
      expect(updated.revision, 2);

      await expectLater(
        endpoints.conversation.startTurn(
          session,
          StartTurnRequest(
            workspaceId: workspaceId,
            requestId: 'turn-stale',
            conversationId: created.id,
            expectedConversationRevision: created.revision,
            clientMessageId: 'message-stale',
            content: 'Stale',
            attachmentIds: const [],
          ),
        ),
        throwsA(isA<ConversationException>()),
      );

      await expectLater(
        endpoints.conversation.delete(
          session,
          DeleteConversationRequest(
            workspaceId: workspaceId,
            requestId: 'delete-stale',
            conversationId: created.id,
            expectedRevision: created.revision,
          ),
        ),
        throwsA(isA<ConversationException>()),
      );
      await endpoints.conversation.delete(
        session,
        DeleteConversationRequest(
          workspaceId: workspaceId,
          requestId: 'delete-1',
          conversationId: created.id,
          expectedRevision: updated.revision,
        ),
      );
      await expectLater(
        endpoints.conversation.get(
          session,
          GetConversationRequest(
            workspaceId: workspaceId,
            conversationId: created.id,
          ),
        ),
        throwsA(isA<ConversationException>()),
      );

      final otherWorkspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            databaseSession,
            name: 'Other workspace',
            ownerUserId: userId,
            now: DateTime.now().toUtc(),
          );
      final liveConversation = await endpoints.conversation.create(
        session,
        CreateConversationRequest(
          workspaceId: workspaceId,
          requestId: 'create-2',
          conversationId: 'conversation-2',
          title: 'Live',
          isPinned: false,
        ),
      );
      final laterConversation = await endpoints.conversation.create(
        session,
        CreateConversationRequest(
          workspaceId: workspaceId,
          requestId: 'create-3',
          conversationId: 'conversation-3',
          title: 'Later',
          isPinned: false,
        ),
      );
      final firstPage = await endpoints.conversation.listPage(
        session,
        ListConversationsRequest(workspaceId: workspaceId, limit: 1),
      );
      final secondPage = await endpoints.conversation.listPage(
        session,
        ListConversationsRequest(
          workspaceId: workspaceId,
          limit: 1,
          cursor: firstPage.nextCursor,
        ),
      );
      expect(firstPage.nextCursor, isNotNull);
      expect(firstPage.conversations.single.id, laterConversation.id);
      expect(secondPage.conversations.single.id, liveConversation.id);
      final searchedPage = await endpoints.conversation.list(
        session,
        ListConversationsRequest(
          workspaceId: workspaceId,
          limit: 1,
          search: 'later',
        ),
      );
      final searchedOffsetPage = await endpoints.conversation.list(
        session,
        ListConversationsRequest(
          workspaceId: workspaceId,
          limit: 1,
          search: 'later',
          offset: 1,
        ),
      );
      expect(searchedPage.single.id, laterConversation.id);
      expect(searchedOffsetPage, isEmpty);

      for (
        var index = 0;
        index < ConversationLimits.maxPinnedPerWorkspace;
        index++
      ) {
        await endpoints.conversation.create(
          session,
          CreateConversationRequest(
            workspaceId: workspaceId,
            requestId: 'create-pinned-$index',
            conversationId: 'pinned-$index',
            title: 'Pinned $index',
            isPinned: true,
          ),
        );
      }
      final pinCandidate = await endpoints.conversation.create(
        session,
        CreateConversationRequest(
          workspaceId: workspaceId,
          requestId: 'create-pin-candidate',
          conversationId: 'pin-candidate',
          title: 'Pin candidate',
          isPinned: false,
        ),
      );
      await expectLater(
        endpoints.conversation.update(
          session,
          UpdateConversationRequest(
            workspaceId: workspaceId,
            requestId: 'pin-eleventh',
            conversationId: pinCandidate.id,
            expectedRevision: pinCandidate.revision,
            isPinned: true,
            clearModel: false,
            clearAgent: false,
            clearReasoningConfig: false,
            clearParent: false,
          ),
        ),
        throwsA(
          isA<ConversationException>().having(
            (error) => error.code,
            'code',
            ConversationErrorCode.validationFailed,
          ),
        ),
      );
      final newerUnpinned = await endpoints.conversation.create(
        session,
        CreateConversationRequest(
          workspaceId: workspaceId,
          requestId: 'create-newer-unpinned',
          conversationId: 'newer-unpinned',
          title: 'Newer unpinned',
          isPinned: false,
        ),
      );
      final pinnedPage = await endpoints.conversation.listPage(
        session,
        ListConversationsRequest(
          workspaceId: workspaceId,
          limit: ConversationLimits.maxPinnedPerWorkspace,
        ),
      );
      final afterPinnedPage = await endpoints.conversation.listPage(
        session,
        ListConversationsRequest(
          workspaceId: workspaceId,
          limit: 1,
          cursor: pinnedPage.nextCursor,
        ),
      );
      expect(
        pinnedPage.conversations,
        everyElement(
          predicate<ConversationSummary>((summary) => summary.isPinned),
        ),
      );
      expect(afterPinnedPage.conversations.single.id, newerUnpinned.id);

      await expectLater(
        endpoints.conversation.get(
          session,
          GetConversationRequest(
            workspaceId: otherWorkspace.id!,
            conversationId: liveConversation.id,
          ),
        ),
        throwsA(isA<ConversationException>()),
      );

      final outsiderId = const Uuid().v4().toString();
      final outsiderSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          outsiderId,
          const {},
        ),
      );
      await AuthUser.db.insertRow(
        databaseSession,
        AuthUser(id: UuidValue.fromString(outsiderId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        databaseSession,
        EmailAccount(
          authUserId: UuidValue.fromString(outsiderId),
          email: 'outsider@example.com',
          passwordHash: 'unused',
        ),
      );
      await expectLater(
        endpoints.conversation.list(
          outsiderSession,
          ListConversationsRequest(workspaceId: workspaceId, limit: 20),
        ),
        throwsA(isA<ConversationException>()),
      );

      final member = await WorkspaceMember.db.findFirstRow(
        databaseSession,
        where: (table) =>
            table.workspaceId.equals(workspaceId) & table.userId.equals(userId),
      );
      await WorkspaceMember.db.updateRow(
        databaseSession,
        member!.copyWith(removedAt: DateTime.now().toUtc()),
      );
      await expectLater(
        endpoints.conversation.list(
          session,
          ListConversationsRequest(workspaceId: workspaceId, limit: 20),
        ),
        throwsA(isA<ConversationException>()),
      );
    });

    test(
      'restores cloud checkpoints only for idle conversation history',
      () async {
        final userId = const Uuid().v4().toString();
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final databaseSession = session.build();
        await AuthUser.db.insertRow(
          databaseSession,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          databaseSession,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: 'checkpoint@example.com',
            passwordHash: 'unused',
          ),
        );
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              databaseSession,
              name: 'Checkpoint workspace',
              ownerUserId: userId,
              now: DateTime.now().toUtc(),
            );
        final workspaceId = workspace.id!;
        for (final conversationId in ['conversation-checkpoint', 'other']) {
          await endpoints.conversation.create(
            session,
            CreateConversationRequest(
              workspaceId: workspaceId,
              requestId: 'create-$conversationId',
              conversationId: conversationId,
              title: conversationId,
              isPinned: false,
            ),
          );
        }
        final conversations = await Conversation.db.find(
          databaseSession,
          where: (table) => table.workspaceId.equals(workspaceId),
        );
        final now = DateTime.now().toUtc();
        final checkpoint = await ConversationMessage.db.insertRow(
          databaseSession,
          ConversationMessage(
            workspaceId: workspaceId,
            conversationId: conversations
                .singleWhere((row) => row.stableId == 'conversation-checkpoint')
                .id!,
            stableId: 'checkpoint-1',
            role: 'system',
            kind: 'system',
            status: 'sent',
            content: 'Summary',
            metadataJson: jsonEncode({'isCompactionSummary': true}),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await ConversationMessage.db.insertRow(
          databaseSession,
          ConversationMessage(
            workspaceId: workspaceId,
            conversationId: conversations
                .singleWhere((row) => row.stableId == 'other')
                .id!,
            stableId: 'checkpoint-other',
            role: 'system',
            kind: 'system',
            status: 'sent',
            content: 'Other summary',
            metadataJson: jsonEncode({'isCompactionSummary': true}),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final restored = await endpoints.conversation
            .restoreCompactionCheckpoint(
              session,
              RestoreConversationCheckpointRequest(
                workspaceId: workspaceId,
                requestId: 'restore-1',
                conversationId: 'conversation-checkpoint',
                checkpointMessageId: checkpoint.stableId,
                expectedConversationRevision: 1,
              ),
            );
        expect(
          restored.conversation.activeCompactionCheckpointId,
          checkpoint.stableId,
        );
        expect(restored.conversation.projectionRevision, 2);
        expect(
          await ConversationMessage.db.count(
            databaseSession,
            where: (table) =>
                table.workspaceId.equals(workspaceId) &
                table.conversationId.equals(checkpoint.conversationId),
          ),
          1,
        );

        await expectLater(
          endpoints.conversation.restoreCompactionCheckpoint(
            session,
            RestoreConversationCheckpointRequest(
              workspaceId: workspaceId,
              requestId: 'restore-cross-conversation',
              conversationId: 'conversation-checkpoint',
              checkpointMessageId: 'checkpoint-other',
              expectedConversationRevision:
                  restored.conversation.projectionRevision,
            ),
          ),
          throwsA(isA<ConversationException>()),
        );
        await expectLater(
          endpoints.conversation.restoreCompactionCheckpoint(
            session,
            RestoreConversationCheckpointRequest(
              workspaceId: workspaceId,
              requestId: 'restore-stale',
              conversationId: 'conversation-checkpoint',
              checkpointMessageId: checkpoint.stableId,
              expectedConversationRevision: 1,
            ),
          ),
          throwsA(isA<ConversationException>()),
        );
        final current = await Conversation.db.findById(
          databaseSession,
          checkpoint.conversationId,
        );
        await Conversation.db.updateRow(
          databaseSession,
          current!.copyWith(
            executionState: ConversationStatuses.running,
            revision: current.revision + 1,
          ),
        );
        await expectLater(
          endpoints.conversation.restoreCompactionCheckpoint(
            session,
            RestoreConversationCheckpointRequest(
              workspaceId: workspaceId,
              requestId: 'restore-busy',
              conversationId: 'conversation-checkpoint',
              checkpointMessageId: checkpoint.stableId,
              expectedConversationRevision: current.revision + 1,
            ),
          ),
          throwsA(isA<ConversationException>()),
        );
        final unchanged = await Conversation.db.findById(
          databaseSession,
          checkpoint.conversationId,
        );
        expect(
          unchanged?.activeCompactionCheckpointId,
          checkpoint.stableId,
        );
      },
    );

    test(
      'rejects another member\'s active attachment without a reference',
      () async {
        final ownerId = const Uuid().v4().toString();
        final memberId = const Uuid().v4().toString();
        final ownerSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            ownerId,
            const {},
          ),
        );
        final databaseSession = sessionBuilder.build();
        final now = DateTime.now().toUtc();
        for (final (id, email) in [
          (ownerId, 'attachment-owner@example.com'),
          (memberId, 'attachment-member@example.com'),
        ]) {
          await AuthUser.db.insertRow(
            databaseSession,
            AuthUser(id: UuidValue.fromString(id), scopeNames: const {}),
          );
          await EmailAccount.db.insertRow(
            databaseSession,
            EmailAccount(
              authUserId: UuidValue.fromString(id),
              email: email,
              passwordHash: 'unused',
            ),
          );
        }
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              databaseSession,
              name: 'Attachment workspace',
              ownerUserId: ownerId,
              now: now,
            );
        final workspaceId = workspace.id!;
        await WorkspaceMember.db.insertRow(
          databaseSession,
          WorkspaceMember(
            workspaceId: workspaceId,
            userId: memberId,
            role: 'member',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final conversation = await endpoints.conversation.create(
          ownerSession,
          CreateConversationRequest(
            workspaceId: workspaceId,
            requestId: 'create-attachment',
            conversationId: 'attachment-conversation',
            title: 'Attachment',
            isPinned: false,
          ),
        );
        final object = await WorkspaceObject.db.insertRow(
          databaseSession,
          WorkspaceObject(
            workspaceId: workspaceId,
            objectKey: 'foreign-attachment',
            purpose: 'chatAttachment',
            displayName: 'foreign.txt',
            mimeType: 'text/plain',
            sizeBytes: 1,
            checksumSha256: '0' * 64,
            status: 'active',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await ObjectUpload.db.insertRow(
          databaseSession,
          ObjectUpload(
            workspaceId: workspaceId,
            objectId: object.id!,
            actorUserId: memberId,
            requestId: 'foreign-upload',
            requestHash: 'foreign-upload',
            expiresAt: now.add(const Duration(minutes: 10)),
            completedAt: now,
            createdAt: now,
          ),
        );

        await expectLater(
          endpoints.conversation.startTurn(
            ownerSession,
            StartTurnRequest(
              workspaceId: workspaceId,
              requestId: 'foreign-attachment-turn',
              conversationId: conversation.id,
              expectedConversationRevision: conversation.revision,
              clientMessageId: 'foreign-attachment-message',
              content: 'Use this attachment',
              attachmentIds: [object.id!.toString()],
            ),
          ),
          throwsA(
            isA<ConversationException>().having(
              (error) => error.code,
              'code',
              ConversationErrorCode.validationFailed,
            ),
          ),
        );
        expect(
          await ObjectReference.db.find(
            databaseSession,
            where: (table) => table.objectId.equals(object.id),
          ),
          isEmpty,
        );
      },
    );
  });
}
