// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

import 'package:auravibes_app/data/database/drift/app_database.dart';
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
  group('ConversationDao', () {
    final fixture = _DatabaseFixture(createTestConnection);

    setUp(fixture.reset);

    tearDown(() async {
      await fixture.close();
    });

    test('insertConversation creates and returns conversation', () async {
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      final conv = await fixture.database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          workspaceId: ws.id,
          title: 'Test Conversation',
        ),
      );
      expect(conv.title, equals('Test Conversation'));
      expect(conv.workspaceId, equals(ws.id));
    });

    test('getConversationById returns conversation', () async {
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      final created = await fixture.database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          workspaceId: ws.id,
          title: 'Test',
        ),
      );
      final found = await fixture.database.conversationDao.getConversationById(
        created.id,
      );
      expect(found, isNotNull);
      expect(
        (found ?? fail('Expected found to be non-null')).title,
        equals('Test'),
      );
    });

    test('getConversationById returns null for nonexistent', () async {
      final found = await fixture.database.conversationDao.getConversationById(
        'nonexistent',
      );
      expect(found, isNull);
    });

    test('patchConversation updates fields', () async {
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      final created = await fixture.database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          workspaceId: ws.id,
          title: 'Original',
        ),
      );
      final patched = await fixture.database.conversationDao.patchConversation(
        created.id,
        ConversationsCompanion(
          updatedAt: Value(DateTime.now()),
          title: const Value('Updated'),
        ),
      );
      expect(patched, isTrue);
      final found = await fixture.database.conversationDao.getConversationById(
        created.id,
      );
      expect(
        (found ?? fail('Expected found to be non-null')).title,
        equals('Updated'),
      );
    });

    test('patchConversation returns false for nonexistent', () async {
      final patched = await fixture.database.conversationDao.patchConversation(
        'nonexistent',
        const ConversationsCompanion(title: Value('X')),
      );
      expect(patched, isFalse);
    });

    test('deleteConversation removes conversation', () async {
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      final created = await fixture.database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          workspaceId: ws.id,
          title: 'To Delete',
        ),
      );
      final deleted = await fixture.database.conversationDao.deleteConversation(
        created.id,
      );
      expect(deleted, isTrue);
      expect(
        await fixture.database.conversationDao.getConversationById(created.id),
        isNull,
      );
    });

    test('deleteConversation returns false for nonexistent', () async {
      final deleted = await fixture.database.conversationDao.deleteConversation(
        'nonexistent',
      );
      expect(deleted, isFalse);
    });

    test('watchConversationById emits conversation', () async {
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      final created = await fixture.database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          workspaceId: ws.id,
          title: 'Watched',
        ),
      );
      final emitted = await fixture.database.conversationDao
          .watchConversationById(created.id)
          .first;
      expect(emitted, isNotNull);
      expect(
        (emitted ?? fail('Expected emitted to be non-null')).title,
        equals('Watched'),
      );
    });

    test('watchConversationsByWorkspace emits list', () async {
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      final _ = await fixture.database.conversationDao.insertConversation(
        ConversationsCompanion.insert(workspaceId: ws.id, title: 'A'),
      );
      final _ = await fixture.database.conversationDao.insertConversation(
        ConversationsCompanion.insert(workspaceId: ws.id, title: 'B'),
      );
      final emitted = await fixture.database.conversationDao
          .watchConversationsByWorkspace(ws.id)
          .first;
      expect(emitted.length, equals(2));
    });

    test('watchConversationsByWorkspace with limit', () async {
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      final _ = await fixture.database.conversationDao.insertConversation(
        ConversationsCompanion.insert(workspaceId: ws.id, title: 'A'),
      );
      final _ = await fixture.database.conversationDao.insertConversation(
        ConversationsCompanion.insert(workspaceId: ws.id, title: 'B'),
      );
      final emitted = await fixture.database.conversationDao
          .watchConversationsByWorkspace(ws.id, limit: 1)
          .first;
      expect(emitted.length, equals(1));
    });
  });
}
