import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/database/drift/tables/messages.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_message_search_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_route_failure.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('searches visible text in workspace with bounded pagination', () async {
    final fixture = await _createFixture();
    addTearDown(fixture.database.close);
    final userMessage = await _insertMessage(
      database: fixture.database,
      conversationId: fixture.firstConversationId,
      content: 'The HABITAT report is ready.',
      createdAt: .utc(2026),
      isUser: true,
    );
    final assistantMessage = await _insertMessage(
      database: fixture.database,
      conversationId: fixture.secondConversationId,
      content: 'I found the habitat report and its conclusion.',
      createdAt: .utc(2026, 1, 2),
    );
    final systemMessage = await _insertMessage(
      database: fixture.database,
      conversationId: fixture.firstConversationId,
      content: 'Hidden habitat context.',
      createdAt: .utc(2026, 1, 3),
      messageType: .system,
    );
    final toolMessage = await _insertMessage(
      database: fixture.database,
      conversationId: fixture.firstConversationId,
      content: 'Tool habitat output.',
      createdAt: .utc(2026, 1, 4),
      messageType: .toolCall,
    );
    final otherWorkspaceMessage = await _insertMessage(
      database: fixture.database,
      conversationId: fixture.otherConversationId,
      content: 'Other workspace habitat result.',
      createdAt: .utc(2026, 1, 5),
    );

    final firstPage = await fixture.repository.searchMessages(
      query: 'habitat',
      workspaceIds: {fixture.workspaceId},
      limit: 1,
    );
    final secondPage = await fixture.repository.searchMessages(
      query: 'habitat',
      workspaceIds: {fixture.workspaceId},
      limit: 1,
      offset: 1,
    );
    final noMatches = await fixture.repository.searchMessages(
      query: 'absent phrase',
      workspaceIds: {fixture.workspaceId},
      limit: 10,
    );

    expect(firstPage.single.messageId, assistantMessage.id);
    expect(firstPage.single.conversationTitle, 'Second conversation');
    expect(firstPage.single.workspaceName, 'Current workspace');
    expect(firstPage.single.role, 'assistant');
    expect(firstPage.single.excerpt, contains('habitat'));
    expect(secondPage.single.messageId, userMessage.id);
    expect(secondPage.single.role, 'user');
    expect(
      [...firstPage, ...secondPage].map((result) => result.messageId),
      isNot(contains(systemMessage.id)),
    );
    expect(
      [...firstPage, ...secondPage].map((result) => result.messageId),
      isNot(contains(toolMessage.id)),
    );
    expect(
      [...firstPage, ...secondPage].map((result) => result.messageId),
      isNot(contains(otherWorkspaceMessage.id)),
    );
    expect(noMatches, isEmpty);
  });

  test('keeps local results when one cloud workspace fails', () async {
    final fixture = await _createFixture();
    addTearDown(fixture.database.close);
    final message = await _insertMessage(
      database: fixture.database,
      conversationId: fixture.firstConversationId,
      content: 'A habitat result',
      createdAt: .utc(2026),
    );
    final now = DateTime.utc(2026);
    final container = ProviderContainer(
      overrides: [
        messageRepositoryProvider.overrideWithValue(fixture.repository),
        allWorkspacesProvider.overrideWithValue(
          AsyncData([
            WorkspaceEntity(
              id: fixture.workspaceId,
              name: 'Current workspace',
              type: .local,
              createdAt: now,
              updatedAt: now,
            ),
            WorkspaceEntity(
              id: 'remote-workspace',
              name: 'Unavailable workspace',
              type: .remote,
              createdAt: now,
              updatedAt: now,
            ),
          ]),
        ),
        workspaceSessionForRouteProvider('remote-workspace').overrideWith(
          (ref) async => throw const WorkspaceRouteFailure(invalidMirror: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    final page = await container.read(
      conversationMessageSearchPageProvider((
        query: 'habitat',
        workspaceId: null,
        offset: 0,
      )).future,
    );

    expect(page.results.single.messageId, message.id);
    expect(page.hasError, isTrue);
  });

  test('keeps a long query inside its result excerpt', () async {
    final fixture = await _createFixture();
    addTearDown(fixture.database.close);
    final query = List.filled(33, 'needle').join();
    final message = await _insertMessage(
      database: fixture.database,
      conversationId: fixture.firstConversationId,
      content: '${List.filled(12, 'context').join(' ')} $query suffix',
      createdAt: .utc(2026),
    );

    final results = await fixture.repository.searchMessages(
      query: query,
      workspaceIds: {fixture.workspaceId},
      limit: 1,
    );

    expect(results.single.messageId, message.id);
    expect(results.single.excerpt, contains(query));
  });

  test('keeps emoji intact when excerpt starts near a match', () async {
    final fixture = await _createFixture();
    addTearDown(fixture.database.close);
    final emoji = String.fromCharCodes([0x1f469, 0x1f3fd, 0x200d, 0x1f680]);
    final content =
        '${List.filled(8, 'a').join()}$emoji'
        '${List.filled(45, 'a').join()} habitat';
    final message = await _insertMessage(
      database: fixture.database,
      conversationId: fixture.firstConversationId,
      content: content,
      createdAt: .utc(2026),
    );

    final results = await fixture.repository.searchMessages(
      query: 'habitat',
      workspaceIds: {fixture.workspaceId},
      limit: 1,
    );

    expect(results.single.messageId, message.id);
    expect(results.single.excerpt, contains(emoji));
  });
}

typedef _SearchFixture = ({
  AppDatabase database,
  MessageRepository repository,
  String workspaceId,
  String firstConversationId,
  String secondConversationId,
  String otherConversationId,
});

Future<_SearchFixture> _createFixture() async {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  final repository = MessageRepository(database);
  final workspace = await database.workspaceDao.insertWorkspace(
    .insert(name: 'Current workspace', type: .local),
  );
  final otherWorkspace = await database.workspaceDao.insertWorkspace(
    .insert(name: 'Other workspace', type: .local),
  );
  final firstConversation = await database.conversationDao.insertConversation(
    .insert(workspaceId: workspace.id, title: 'First conversation'),
  );
  final secondConversation = await database.conversationDao.insertConversation(
    .insert(workspaceId: workspace.id, title: 'Second conversation'),
  );
  final otherConversation = await database.conversationDao.insertConversation(
    .insert(workspaceId: otherWorkspace.id, title: 'Private conversation'),
  );

  return (
    database: database,
    repository: repository,
    workspaceId: workspace.id,
    firstConversationId: firstConversation.id,
    secondConversationId: secondConversation.id,
    otherConversationId: otherConversation.id,
  );
}

Future<MessagesTable> _insertMessage({
  required AppDatabase database,
  required String conversationId,
  required String content,
  required DateTime createdAt,
  bool isUser = false,
  MessagesTableType messageType = .text,
}) => database.messageDao.insertMessage(
  .insert(
    conversationId: conversationId,
    content: content,
    messageType: messageType,
    isUser: isUser,
    status: .sent,
    createdAt: Value(createdAt),
  ),
);
