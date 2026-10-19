import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../database/drift/database_test_utils.dart';

void main() {
  group('MessageRepository bookmarks', () {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    final messages = MessageRepository(database);
    final conversations = ConversationRepository(database);

    setUp(() async {
      await clearAppDatabase(database);

      final workspace = await database.workspaceDao.insertWorkspace(
        .insert(id: const Value('ws-1'), name: 'Workspace', type: .local),
      );
      final otherWorkspace = await database.workspaceDao.insertWorkspace(
        .insert(id: const Value('ws-2'), name: 'Other workspace', type: .local),
      );
      for (final id in ['source', 'other']) {
        final _ = await database.conversationDao.insertConversation(
          .insert(
            id: Value(id),
            workspaceId: workspace.id,
            title: 'Conversation $id',
          ),
        );
      }
      final _ = await database.conversationDao.insertConversation(
        .insert(
          id: const Value('other-workspace'),
          workspaceId: otherWorkspace.id,
          title: 'Conversation other-workspace',
        ),
      );
    });

    tearDownAll(database.close);

    test('lists bookmarked messages with source context', () async {
      final message = await _createMessage(messages, 'source');

      expect(
        await messages.bookmarkMessage(
          workspaceId: 'ws-1',
          conversationId: 'source',
          messageId: message.id,
        ),
        isTrue,
      );

      final bookmarks = await messages.watchBookmarkedMessages('ws-1').first;
      expect(bookmarks, hasLength(1));
      expect(bookmarks.single.workspaceId, 'ws-1');
      expect(bookmarks.single.messageId, message.id);
      expect(bookmarks.single.conversationId, 'source');
      expect(bookmarks.single.conversationTitle, 'Conversation source');
      expect(bookmarks.single.workspaceName, 'Workspace');
      expect(bookmarks.single.excerpt, message.content);
    });

    test(
      'lists bookmarks across local workspaces with workspace context',
      () async {
        final first = await _createMessage(messages, 'source');
        final second = await _createMessage(messages, 'other-workspace');

        expect(
          await messages.bookmarkMessage(
            workspaceId: 'ws-1',
            conversationId: 'source',
            messageId: first.id,
          ),
          isTrue,
        );
        expect(
          await messages.bookmarkMessage(
            workspaceId: 'ws-2',
            conversationId: 'other-workspace',
            messageId: second.id,
          ),
          isTrue,
        );

        final bookmarks = await messages.watchBookmarkedMessages().first;
        expect(bookmarks, hasLength(2));
        expect(
          bookmarks.map((bookmark) => bookmark.workspaceId),
          containsAll(['ws-1', 'ws-2']),
        );
        expect(
          bookmarks.map((bookmark) => bookmark.workspaceName),
          containsAll(['Workspace', 'Other workspace']),
        );
      },
    );

    test('bookmark from fork stays attached to source conversation', () async {
      final message = await _createMessage(messages, 'source');
      final fork = await conversations.forkConversation('source');

      expect(
        await messages.bookmarkMessage(
          workspaceId: 'ws-1',
          conversationId: fork.id,
          messageId: message.id,
        ),
        isTrue,
      );

      final bookmarks = await messages.watchBookmarkedMessages('ws-1').first;
      expect(bookmarks, hasLength(1));
      expect(bookmarks.single.conversationId, 'source');
      expect(bookmarks.single.messageId, message.id);
    });

    test(
      'source deletion removes bookmarks without copying into fork',
      () async {
        final message = await _createMessage(messages, 'source');
        expect(
          await messages.bookmarkMessage(
            workspaceId: 'ws-1',
            conversationId: 'source',
            messageId: message.id,
          ),
          isTrue,
        );
        final fork = await conversations.forkConversation('source');

        expect(await conversations.deleteConversation('source'), isTrue);

        expect(await messages.watchBookmarkedMessages('ws-1').first, isEmpty);
        expect(await messages.getMessagesByConversation(fork.id), hasLength(1));
      },
    );

    test('deleting a bookmarked message removes it from the list', () async {
      final message = await _createMessage(messages, 'source');
      expect(
        await messages.bookmarkMessage(
          workspaceId: 'ws-1',
          conversationId: 'source',
          messageId: message.id,
        ),
        isTrue,
      );

      expect(
        await messages.deleteMessage(message.id, conversationId: 'source'),
        isTrue,
      );
      expect(await messages.watchBookmarkedMessages('ws-1').first, isEmpty);
    });

    test('unbookmark removes saved message from workspace list', () async {
      final message = await _createMessage(messages, 'source');
      expect(
        await messages.bookmarkMessage(
          workspaceId: 'ws-1',
          conversationId: 'source',
          messageId: message.id,
        ),
        isTrue,
      );

      expect(
        await messages.unbookmarkMessage(
          workspaceId: 'ws-1',
          conversationId: 'source',
          messageId: message.id,
        ),
        isTrue,
      );

      expect(await messages.watchBookmarkedMessages('ws-1').first, isEmpty);
    });
  });
}

Future<MessageEntity> _createMessage(
  MessageRepository repository,
  String conversationId,
) => repository.createMessage(
  .new(
    conversationId: conversationId,
    content: 'Saved response',
    messageType: .text,
    isUser: true,
    status: .sent,
  ),
);
