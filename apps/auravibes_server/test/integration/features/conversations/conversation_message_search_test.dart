import 'package:auravibes_server/src/features/conversations/repositories/conversation_repository.dart'
    as conversation_repo;
import 'package:auravibes_server/src/features/conversations/usecases/conversation_usecases.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'ConversationMessageSearch',
    (sessionBuilder, endpoints) {
      test(
        'searches visible messages, pages, and authorizes workspace access',
        () async {
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
          final workspaceRepository = workspace_repo.CloudWorkspaceRepository();
          final workspace = await workspaceRepository.createWorkspace(
            database,
            name: 'Workspace',
            ownerUserId: userId,
            now: DateTime.utc(2026),
          );
          final otherWorkspace = await workspaceRepository.createWorkspace(
            database,
            name: 'Other workspace',
            ownerUserId: userId,
            now: DateTime.utc(2026),
          );
          final firstConversation = await _insertConversation(
            database,
            workspaceId: workspace.id!,
            id: 'conversation-1',
            title: 'Design review',
          );
          final deletedConversation = await _insertConversation(
            database,
            workspaceId: workspace.id!,
            id: 'conversation-deleted',
            title: 'Deleted review',
            deletedAt: DateTime.utc(2026, 1, 2),
          );
          final privateConversation = await _insertConversation(
            database,
            workspaceId: otherWorkspace.id!,
            id: 'conversation-other-workspace',
            title: 'Private review',
          );
          await _insertMessage(
            database,
            conversation: firstConversation,
            id: 'user-match',
            role: 'user',
            content: 'Needle phrase first',
            createdAt: DateTime.utc(2026, 1, 1),
          );
          await _insertMessage(
            database,
            conversation: firstConversation,
            id: 'assistant-match',
            role: 'assistant',
            content: 'Needle phrase second result',
            createdAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
          );
          await _insertMessage(
            database,
            conversation: firstConversation,
            id: 'system-match',
            role: 'system',
            content: 'Needle phrase hidden system text',
            createdAt: DateTime.utc(2026, 1, 1, 0, 0, 2),
          );
          await _insertMessage(
            database,
            conversation: firstConversation,
            id: 'tool-match',
            role: 'assistant',
            kind: 'tool',
            content: 'Needle phrase hidden tool output',
            createdAt: DateTime.utc(2026, 1, 1, 0, 0, 5),
          );
          await _insertMessage(
            database,
            conversation: deletedConversation,
            id: 'deleted-match',
            role: 'user',
            content: 'Needle phrase deleted conversation',
            createdAt: DateTime.utc(2026, 1, 1, 0, 0, 3),
          );
          await _insertMessage(
            database,
            conversation: privateConversation,
            id: 'private-match',
            role: 'user',
            content: 'Needle phrase other workspace',
            createdAt: DateTime.utc(2026, 1, 1, 0, 0, 4),
          );

          final useCases = ConversationUseCases(
            conversation_repo.ConversationRepository(),
          );
          final firstPage = await useCases.searchMessages(
            database,
            userId: userId,
            request: SearchConversationMessagesRequest(
              workspaceId: workspace.id!,
              query: 'needle',
              limit: 1,
              offset: 0,
            ),
          );
          final secondPage = await useCases.searchMessages(
            database,
            userId: userId,
            request: SearchConversationMessagesRequest(
              workspaceId: workspace.id!,
              query: 'needle',
              limit: 1,
              offset: 1,
            ),
          );
          final noMatches = await useCases.searchMessages(
            database,
            userId: userId,
            request: SearchConversationMessagesRequest(
              workspaceId: workspace.id!,
              query: 'missing',
              limit: 10,
              offset: 0,
            ),
          );
          final targetMessages = await useCases.listMessages(
            database,
            userId: userId,
            request: ListConversationMessagesRequest(
              workspaceId: workspace.id!,
              conversationId: firstConversation.stableId,
              limit: 2,
              messageId: 'assistant-match',
            ),
          );

          expect(firstPage.single.messageId, 'assistant-match');
          expect(firstPage.single.conversationTitle, 'Design review');
          expect(firstPage.single.role, 'assistant');
          expect(firstPage.single.excerpt, contains('Needle phrase'));
          expect(secondPage.single.messageId, 'user-match');
          expect(noMatches, isEmpty);
          expect(targetMessages.first.id, 'assistant-match');
          expect(targetMessages, hasLength(2));
          await expectLater(
            useCases.searchMessages(
              database,
              userId: const Uuid().v4().toString(),
              request: SearchConversationMessagesRequest(
                workspaceId: workspace.id!,
                query: 'needle',
                limit: 10,
                offset: 0,
              ),
            ),
            throwsA(isA<ConversationException>()),
          );
        },
      );
    },
  );
}

Future<Conversation> _insertConversation(
  Session session, {
  required int workspaceId,
  required String id,
  required String title,
  DateTime? deletedAt,
}) => Conversation.db.insertRow(
  session,
  Conversation(
    workspaceId: workspaceId,
    stableId: id,
    title: title,
    isPinned: false,
    revision: 1,
    projectionRevision: 1,
    eventSequence: 0,
    executionState: 'idle',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    deletedAt: deletedAt,
  ),
);

Future<ConversationMessage> _insertMessage(
  Session session, {
  required Conversation conversation,
  required String id,
  required String role,
  required String content,
  required DateTime createdAt,
  String kind = 'text',
}) => ConversationMessage.db.insertRow(
  session,
  ConversationMessage(
    workspaceId: conversation.workspaceId,
    conversationId: conversation.id!,
    stableId: id,
    role: role,
    kind: kind,
    status: 'sent',
    content: content,
    revision: 1,
    createdAt: createdAt,
    updatedAt: createdAt,
  ),
);
