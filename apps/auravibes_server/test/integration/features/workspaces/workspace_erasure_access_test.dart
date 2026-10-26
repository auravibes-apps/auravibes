import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/workspace_conversation_commands.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Workspace erasure access', (builder, endpoints) {
    test(
      'members cannot read skills, context, or execute commands after erasure is requested',
      () async {
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
              name: 'Retained during erasure',
              ownerUserId: userId,
              now: now,
            );
        final conversation = await Conversation.db.insertRow(
          session,
          Conversation(
            workspaceId: workspace.id!,
            stableId: 'erasure-access-chat',
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
            requestId: 'erasure-access-turn',
            requestHash: 'fixture',
            initiatorUserId: userId,
            status: 'running',
            revision: 1,
            acceptedSequence: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final skill = await SkillResource.db.insertRow(
          session,
          SkillResource(
            workspaceId: workspace.id!,
            skillId: 'support',
            resourceId: 'guide',
            title: 'Guide',
            slug: 'guide',
            description: 'A test guide',
            content: 'Private content',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final directorySelection = WorkspaceContextSelection(
          workspaceId: '${workspace.id}',
          conversationId: conversation.stableId,
          itemId: '',
          kind: 'directory',
        );

        final skillRequest = ListSkillResourcesRequest(
          workspaceId: workspace.id!,
          skillId: 'support',
        );
        final skillViewRequest = GetSkillResourceRequest(
          workspaceId: workspace.id!,
          resourceId: skill.resourceId,
        );
        expect(
          (await endpoints.skillResource.list(
            authenticated,
            skillRequest,
          )).single.id,
          skill.resourceId,
        );
        expect(
          (await endpoints.skillResource.get(
            authenticated,
            skillViewRequest,
          ))?.id,
          skill.resourceId,
        );
        await endpoints.workspaceContext.save(
          authenticated,
          workspace.id!,
          conversation.stableId,
          'before-erasure',
          jsonEncode(directorySelection.toJson()),
        );
        expect(
          jsonDecode(
            await endpoints.workspaceContext.read(
              authenticated,
              workspace.id!,
              conversation.stableId,
            ),
          )['selection']['kind'],
          'directory',
        );

        await CloudWorkspace.db.updateRow(
          session,
          workspace.copyWith(
            revision: workspace.revision + 1,
            deletedAt: now,
            erasureRequestedAt: now,
            updatedAt: now,
          ),
        );
        expect(
          await WorkspaceMember.db.count(
            session,
            where: (row) =>
                row.workspaceId.equals(workspace.id!) &
                row.userId.equals(userId) &
                row.removedAt.equals(null),
          ),
          1,
        );
        expect(
          await SkillResource.db.count(
            session,
            where: (row) => row.id.equals(skill.id),
          ),
          1,
        );
        expect(
          await WorkspaceConversationContext.db.count(
            session,
            where: (row) =>
                row.workspaceId.equals(workspace.id!) &
                row.actorUserId.equals(userId),
          ),
          1,
        );

        Matcher permissionDenied = isA<CloudWorkspaceException>().having(
          (error) => error.code,
          'code',
          CloudWorkspaceErrorCode.permissionDenied,
        );
        await expectLater(
          endpoints.skillResource.list(authenticated, skillRequest),
          throwsA(permissionDenied),
        );
        await expectLater(
          endpoints.skillResource.get(authenticated, skillViewRequest),
          throwsA(permissionDenied),
        );
        await expectLater(
          endpoints.workspaceContext.read(
            authenticated,
            workspace.id!,
            conversation.stableId,
          ),
          throwsA(permissionDenied),
        );
        await expectLater(
          endpoints.workspaceContext.save(
            authenticated,
            workspace.id!,
            conversation.stableId,
            'after-erasure',
            null,
          ),
          throwsA(permissionDenied),
        );
        await expectLater(
          const WorkspaceConversationCommands().call(
            session,
            turn,
            'after-erasure',
            {'action': 'createFolder', 'name': 'Must remain blocked'},
          ),
          throwsA(permissionDenied),
        );
        expect(
          await WorkspaceResource.db.count(
            session,
            where: (row) =>
                row.workspaceId.equals(workspace.id!) &
                row.resourceKind.equals(WorkspaceResourceKind.folder) &
                row.deletedAt.equals(null),
          ),
          0,
        );
      },
    );
  });
}
