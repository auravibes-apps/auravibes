
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

QueryExecutor createTestConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async {
          return NativeDatabase.memory();
        }),
      );
    }),
  );
}

final class _DatabaseFixture {
  _DatabaseFixture(this.createConnection);

  final QueryExecutor Function() createConnection;
  AppDatabase? _database;

  AppDatabase get database =>
      _database ?? fail('Database fixture not initialized');

  void reset() {
    _database = AppDatabase(connection: createConnection());
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

void main() {
  group('MessageDao', () {
    final fixture = _DatabaseFixture(createTestConnection);
    var conversationId = '';

    setUp(() async {
      fixture.reset();
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      final conv = await fixture.database.conversationDao.insertConversation(
        ConversationsCompanion.insert(workspaceId: ws.id, title: 'Conv'),
      );
      conversationId = conv.id;
    });

    tearDown(() async {
      await fixture.close();
    });

    test('insertMessage creates and returns message', () async {
      final msg = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'Hello',
          messageType: MessagesTableType.text,
          isUser: true,
          status: MessageTableStatus.sent,
        ),
      );
      expect(msg.content, equals('Hello'));
      expect(msg.isUser, isTrue);
    });

    test('getMessageById returns message', () async {
      final created = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'Hi',
          messageType: MessagesTableType.text,
          isUser: true,
          status: MessageTableStatus.sent,
        ),
      );
      final found = await fixture.database.messageDao.getMessageById(
        created.id,
      );
      expect(found, isNotNull);
      expect(
        (found ?? fail('Expected found to be non-null')).content,
        equals('Hi'),
      );
    });

    test('getMessageById returns null for nonexistent', () async {
      final found = await fixture.database.messageDao.getMessageById('missing');
      expect(found, isNull);
    });

    test('patchMessage updates fields', () async {
      final created = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'Original',
          messageType: MessagesTableType.text,
          isUser: true,
          status: MessageTableStatus.sent,
        ),
      );
      final patched = await fixture.database.messageDao.patchMessage(
        created.id,
        MessagesCompanion(
          updatedAt: Value(DateTime.now()),
          content: const Value('Updated'),
        ),
      );
      expect(patched, isNotNull);
      expect(
        (patched ?? fail('Expected patched to be non-null')).content,
        equals('Updated'),
      );
    });

    test('patchMessage returns null for nonexistent', () async {
      final patched = await fixture.database.messageDao.patchMessage(
        'missing',
        const MessagesCompanion(content: Value('X')),
      );
      expect(patched, isNull);
    });

    test('deleteMessage removes message', () async {
      final created = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'Delete me',
          messageType: MessagesTableType.text,
          isUser: true,
          status: MessageTableStatus.sent,
        ),
      );
      final deleted = await fixture.database.messageDao.deleteMessage(
        created.id,
      );
      expect(deleted, isTrue);
      expect(
        await fixture.database.messageDao.getMessageById(created.id),
        isNull,
      );
    });

    test('deleteMessage returns false for nonexistent', () async {
      final deleted = await fixture.database.messageDao.deleteMessage(
        'missing',
      );
      expect(deleted, isFalse);
    });

    test('getMessagesByConversation returns ordered messages', () async {
      final _ = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'First',
          messageType: MessagesTableType.text,
          isUser: true,
          status: MessageTableStatus.sent,
        ),
      );
      final _ = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'Second',
          messageType: MessagesTableType.text,
          isUser: false,
          status: MessageTableStatus.sent,
        ),
      );
      final msgs = await fixture.database.messageDao.getMessagesByConversation(
        conversationId,
      );
      expect(msgs.length, equals(2));
      expect(msgs.firstOrNull?.content, equals('First'));
      expect(msgs.last.content, equals('Second'));
    });

    test('getMessagesByConversationPaginated paginates correctly', () async {
      for (var i = 0; i < 5; i++) {
        final _ = await fixture.database.messageDao.insertMessage(
          MessagesCompanion.insert(
            conversationId: conversationId,
            content: 'Msg $i',
            messageType: MessagesTableType.text,
            isUser: true,
            status: MessageTableStatus.sent,
          ),
        );
      }
      final page = await fixture.database.messageDao
          .getMessagesByConversationPaginated(
            conversationId,
            2,
            0,
          );
      expect(page.length, equals(2));
    });

    test('getMessagesByType filters by type', () async {
      final _ = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'Text msg',
          messageType: MessagesTableType.text,
          isUser: true,
          status: MessageTableStatus.sent,
        ),
      );
      final _ = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'System msg',
          messageType: MessagesTableType.system,
          isUser: false,
          status: MessageTableStatus.sent,
        ),
      );
      final textMsgs = await fixture.database.messageDao.getMessagesByType(
        conversationId,
        MessagesTableType.text,
      );
      expect(textMsgs.length, equals(1));
      expect(textMsgs.firstOrNull?.content, equals('Text msg'));
    });

    test('getUserMessages returns only user messages', () async {
      final _ = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'User',
          messageType: MessagesTableType.text,
          isUser: true,
          status: MessageTableStatus.sent,
        ),
      );
      final _ = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'AI',
          messageType: MessagesTableType.text,
          isUser: false,
          status: MessageTableStatus.sent,
        ),
      );
      final userMsgs = await fixture.database.messageDao.getUserMessages(
        conversationId,
      );
      expect(userMsgs.length, equals(1));
      expect(userMsgs.firstOrNull?.content, equals('User'));
    });

    test('getSystemMessages returns only non-user messages', () async {
      final _ = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'User',
          messageType: MessagesTableType.text,
          isUser: true,
          status: MessageTableStatus.sent,
        ),
      );
      final _ = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'AI',
          messageType: MessagesTableType.text,
          isUser: false,
          status: MessageTableStatus.sent,
        ),
      );
      final sysMsgs = await fixture.database.messageDao.getSystemMessages(
        conversationId,
      );
      expect(sysMsgs.length, equals(1));
      expect(sysMsgs.firstOrNull?.content, equals('AI'));
    });

    test('getMessageCountByConversation returns count', () async {
      expect(
        await fixture.database.messageDao.getMessageCountByConversation(
          conversationId,
        ),
        equals(0),
      );
      final _ = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'Msg',
          messageType: MessagesTableType.text,
          isUser: true,
          status: MessageTableStatus.sent,
        ),
      );
      expect(
        await fixture.database.messageDao.getMessageCountByConversation(
          conversationId,
        ),
        equals(1),
      );
    });

    test('messageExists returns correct state', () async {
      final created = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'Exists',
          messageType: MessagesTableType.text,
          isUser: true,
          status: MessageTableStatus.sent,
        ),
      );
      expect(
        await fixture.database.messageDao.messageExists(created.id),
        isTrue,
      );
      expect(
        await fixture.database.messageDao.messageExists('missing'),
        isFalse,
      );
    });

    test('getMessagesByStatus filters by status', () async {
      final _ = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'Sent',
          messageType: MessagesTableType.text,
          isUser: true,
          status: MessageTableStatus.sent,
        ),
      );
      final _ = await fixture.database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'Error',
          messageType: MessagesTableType.text,
          isUser: true,
          status: MessageTableStatus.error,
        ),
      );
      final sent = await fixture.database.messageDao.getMessagesByStatus(
        conversationId,
        'sent',
      );
      expect(sent.length, equals(1));
      expect(sent.firstOrNull?.content, equals('Sent'));
    });
  });
}
