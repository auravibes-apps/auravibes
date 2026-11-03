import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('ConversationLabelsEndpoint', (sessionBuilder, endpoints) {
    test('scopes CRUD and OR filtering to the requested workspace', () async {
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
      final workspaceA = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            database,
            name: 'A',
            ownerUserId: userId,
            now: DateTime.utc(2026, 11, 1),
          );
      final workspaceB = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            database,
            name: 'B',
            ownerUserId: userId,
            now: DateTime.utc(2026, 11, 2),
          );
      final olderMatch = await endpoints.conversation.create(
        session,
        CreateConversationRequest(
          workspaceId: workspaceA.id!,
          requestId: 'create-older',
          conversationId: 'older-match',
          title: 'Older match',
          isPinned: false,
        ),
      );
      final unlabelled = await endpoints.conversation.create(
        session,
        CreateConversationRequest(
          workspaceId: workspaceA.id!,
          requestId: 'create-unlabelled',
          conversationId: 'unlabelled',
          title: 'Unlabelled',
          isPinned: false,
        ),
      );
      final newerMatch = await endpoints.conversation.create(
        session,
        CreateConversationRequest(
          workspaceId: workspaceA.id!,
          requestId: 'create-newer',
          conversationId: 'newer-match',
          title: 'Newer match',
          isPinned: false,
        ),
      );
      final foreignConversation = await endpoints.conversation.create(
        session,
        CreateConversationRequest(
          workspaceId: workspaceB.id!,
          requestId: 'create-foreign',
          conversationId: 'foreign',
          title: 'Foreign',
          isPinned: false,
        ),
      );

      final urgent = await endpoints.conversation.createLabel(
        session,
        CreateConversationLabelRequest(
          workspaceId: workspaceA.id!,
          requestId: 'create-urgent',
          labelId: 'urgent',
          name: ' Urgent ',
        ),
      );
      final ideas = await endpoints.conversation.createLabel(
        session,
        CreateConversationLabelRequest(
          workspaceId: workspaceA.id!,
          requestId: 'create-ideas',
          labelId: 'ideas',
          name: 'Ideas',
        ),
      );
      final sameNameInB = await endpoints.conversation.createLabel(
        session,
        CreateConversationLabelRequest(
          workspaceId: workspaceB.id!,
          requestId: 'create-urgent-b',
          labelId: 'urgent-b',
          name: 'urgent',
        ),
      );
      expect(urgent.name, 'Urgent');
      expect(sameNameInB.workspaceId, workspaceB.id);
      await expectLater(
        endpoints.conversation.createLabel(
          session,
          CreateConversationLabelRequest(
            workspaceId: workspaceA.id!,
            requestId: 'create-duplicate',
            labelId: 'urgent-duplicate',
            name: 'urgent',
          ),
        ),
        throwsA(isA<ConversationException>()),
      );

      await endpoints.conversation.renameLabel(
        session,
        RenameConversationLabelRequest(
          workspaceId: workspaceA.id!,
          requestId: 'rename-ideas',
          labelId: ideas.id,
          name: 'Planning',
        ),
      );
      final labelsA = await endpoints.conversation.listLabels(
        session,
        ListConversationLabelsRequest(workspaceId: workspaceA.id!),
      );
      expect(labelsA.map((label) => label.name).toSet(), {
        'Urgent',
        'Planning',
      });
      expect(
        (await endpoints.conversation.listLabels(
          session,
          ListConversationLabelsRequest(workspaceId: workspaceB.id!),
        )).map((label) => label.id),
        [sameNameInB.id],
      );

      await endpoints.conversation.setConversationLabels(
        session,
        SetConversationLabelsRequest(
          workspaceId: workspaceA.id!,
          requestId: 'labels-older',
          conversationId: olderMatch.id,
          labelIds: [urgent.id],
        ),
      );
      await endpoints.conversation.setConversationLabels(
        session,
        SetConversationLabelsRequest(
          workspaceId: workspaceA.id!,
          requestId: 'labels-newer',
          conversationId: newerMatch.id,
          labelIds: [ideas.id],
        ),
      );
      await expectLater(
        endpoints.conversation.setConversationLabels(
          session,
          SetConversationLabelsRequest(
            workspaceId: workspaceB.id!,
            requestId: 'labels-cross-workspace',
            conversationId: foreignConversation.id,
            labelIds: [urgent.id],
          ),
        ),
        throwsA(isA<ConversationException>()),
      );

      final page = await endpoints.conversation.listPage(
        session,
        ListConversationsRequest(
          workspaceId: workspaceA.id!,
          limit: 1,
          offset: 1,
          labelIds: [urgent.id, ideas.id],
        ),
      );
      expect(page.conversations.map((conversation) => conversation.id), [
        olderMatch.id,
      ]);
      expect(
        page.conversations.single.labels?.map((label) => label.name),
        ['Urgent'],
      );
      final foreignFilter = await endpoints.conversation.listPage(
        session,
        ListConversationsRequest(
          workspaceId: workspaceB.id!,
          limit: 10,
          labelIds: [urgent.id],
        ),
      );
      expect(foreignFilter.conversations, isEmpty);
      expect(unlabelled.id, isNotEmpty);

      await endpoints.conversation.deleteLabel(
        session,
        DeleteConversationLabelRequest(
          workspaceId: workspaceA.id!,
          requestId: 'delete-urgent',
          labelId: urgent.id,
        ),
      );
      expect(
        (await endpoints.conversation.listPage(
          session,
          ListConversationsRequest(workspaceId: workspaceA.id!, limit: 10),
        )).conversations,
        hasLength(3),
      );

      final survivingLabel = (await endpoints.conversation.listLabels(
        session,
        ListConversationLabelsRequest(workspaceId: workspaceA.id!),
      )).single;
      await endpoints.conversation.delete(
        session,
        DeleteConversationRequest(
          workspaceId: workspaceA.id!,
          requestId: 'delete-newer',
          conversationId: newerMatch.id,
          expectedRevision: newerMatch.revision,
        ),
      );
      final staleFilter = await endpoints.conversation.listPage(
        session,
        ListConversationsRequest(
          workspaceId: workspaceA.id!,
          limit: 10,
          labelIds: [survivingLabel.id],
        ),
      );
      expect(staleFilter.conversations, isEmpty);
      expect(
        (await endpoints.conversation.listPage(
          session,
          ListConversationsRequest(workspaceId: workspaceA.id!, limit: 10),
        )).conversations,
        hasLength(2),
      );
    });

    test('denies label reads to non-members', () async {
      final ownerId = const Uuid().v4().toString();
      final ownerSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          ownerId,
          const {},
        ),
      );
      final database = ownerSession.build();
      await AuthUser.db.insertRow(
        database,
        AuthUser(id: UuidValue.fromString(ownerId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        database,
        EmailAccount(
          authUserId: UuidValue.fromString(ownerId),
          email: '$ownerId@example.com',
          passwordHash: 'unused',
        ),
      );
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            database,
            name: 'Private labels',
            ownerUserId: ownerId,
            now: DateTime.now().toUtc(),
          );
      await endpoints.conversation.createLabel(
        ownerSession,
        CreateConversationLabelRequest(
          workspaceId: workspace.id!,
          requestId: 'create-private-label',
          labelId: 'private',
          name: 'Private',
        ),
      );
      final nonMemberId = const Uuid().v4().toString();
      await AuthUser.db.insertRow(
        database,
        AuthUser(id: UuidValue.fromString(nonMemberId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        database,
        EmailAccount(
          authUserId: UuidValue.fromString(nonMemberId),
          email: '$nonMemberId@example.com',
          passwordHash: 'unused',
        ),
      );
      final nonMemberSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          nonMemberId,
          const {},
        ),
      );

      await expectLater(
        endpoints.conversation.listLabels(
          nonMemberSession,
          ListConversationLabelsRequest(workspaceId: workspace.id!),
        ),
        throwsA(
          isA<ConversationException>().having(
            (error) => error.code,
            'code',
            ConversationErrorCode.permissionDenied,
          ),
        ),
      );
    });

    test('active workspace members share label management', () async {
      final ownerId = const Uuid().v4().toString();
      final memberId = const Uuid().v4().toString();
      final ownerSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          ownerId,
          const {},
        ),
      );
      final database = ownerSession.build();
      final now = DateTime.utc(2026, 11, 3);
      for (final userId in [ownerId, memberId]) {
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
      }
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            database,
            name: 'Shared labels',
            ownerUserId: ownerId,
            now: now,
          );
      await WorkspaceMember.db.insertRow(
        database,
        WorkspaceMember(
          workspaceId: workspace.id!,
          userId: memberId,
          role: 'member',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final memberSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          memberId,
          const {},
        ),
      );

      final created = await endpoints.conversation.createLabel(
        ownerSession,
        CreateConversationLabelRequest(
          workspaceId: workspace.id!,
          requestId: 'owner-create-shared-label',
          labelId: 'shared-label',
          name: 'Shared',
        ),
      );
      expect(
        (await endpoints.conversation.listLabels(
          memberSession,
          ListConversationLabelsRequest(workspaceId: workspace.id!),
        )).single.id,
        created.id,
      );
      final renamed = await endpoints.conversation.renameLabel(
        memberSession,
        RenameConversationLabelRequest(
          workspaceId: workspace.id!,
          requestId: 'member-rename-shared-label',
          labelId: created.id,
          name: 'Shared and renamed',
        ),
      );
      expect(renamed.name, 'Shared and renamed');
    });
  });
}
