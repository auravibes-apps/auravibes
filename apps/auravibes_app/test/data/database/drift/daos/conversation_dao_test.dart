import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
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

final class _DatabaseFixture(final QueryExecutor Function() createConnection) {
  AppDatabase? _database;

  AppDatabase get database =>
      _database ?? fail('Database fixture not initialized');

  void reset() {
    _database = .new(connection: createConnection());
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
        .insert(name: 'WS', type: WorkspaceType.local),
      );
      final conv = await fixture.database.conversationDao.insertConversation(
        .insert(workspaceId: ws.id, title: 'Test Conversation'),
      );
      expect(conv.title, equals('Test Conversation'));
      expect(conv.workspaceId, equals(ws.id));
      expect(conv.isPinned, isFalse);
    });

    test('persists pin state after reopening the database', () async {
      await fixture.close();
      final directory = await Directory.systemTemp.createTemp(
        'auravibes-conversation-',
      );
      final file = File('${directory.path}/conversations.sqlite');
      var database = AppDatabase(connection: NativeDatabase(file));
      addTearDown(() async {
        await database.close();
        final _ = await directory.delete(recursive: true);
      });

      final workspace = await database.workspaceDao.insertWorkspace(
        .insert(name: 'WS', type: WorkspaceType.local),
      );
      final conversation = await database.conversationDao.insertConversation(
        .insert(workspaceId: workspace.id, title: 'Pinned'),
      );
      final _ = await database.conversationDao.patchConversation(
        conversation.id,
        const ConversationsCompanion(isPinned: .new(true)),
      );
      await database.close();

      database = AppDatabase(connection: NativeDatabase(file));
      final restored = await database.conversationDao.getConversationById(
        conversation.id,
      );

      expect(
        (restored ?? fail('Expected restored conversation')).isPinned,
        isTrue,
      );
    });

    test('getConversationById returns conversation', () async {
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        .insert(name: 'WS', type: WorkspaceType.local),
      );
      final created = await fixture.database.conversationDao.insertConversation(
        .insert(workspaceId: ws.id, title: 'Test'),
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
        .insert(name: 'WS', type: WorkspaceType.local),
      );
      final created = await fixture.database.conversationDao.insertConversation(
        .insert(workspaceId: ws.id, title: 'Original'),
      );
      final patched = await fixture.database.conversationDao.patchConversation(
        created.id,
        .new(updatedAt: Value(DateTime.now()), title: const Value('Updated')),
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
        const ConversationsCompanion(title: .new('X')),
      );
      expect(patched, isFalse);
    });

    test('deleteConversation removes conversation', () async {
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        .insert(name: 'WS', type: WorkspaceType.local),
      );
      final created = await fixture.database.conversationDao.insertConversation(
        .insert(workspaceId: ws.id, title: 'To Delete'),
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
        .insert(name: 'WS', type: WorkspaceType.local),
      );
      final created = await fixture.database.conversationDao.insertConversation(
        .insert(workspaceId: ws.id, title: 'Watched'),
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
        .insert(name: 'WS', type: WorkspaceType.local),
      );
      final _ = await fixture.database.conversationDao.insertConversation(
        .insert(workspaceId: ws.id, title: 'A'),
      );
      final _ = await fixture.database.conversationDao.insertConversation(
        .insert(workspaceId: ws.id, title: 'B'),
      );
      final emitted = await fixture.database.conversationDao
          .watchConversationsByWorkspace(ws.id)
          .first;
      expect(emitted.length, equals(2));
    });

    test(
      'orders pinned conversations first and preserves update order',
      () async {
        final workspace = await fixture.database.workspaceDao.insertWorkspace(
          .insert(name: 'WS', type: WorkspaceType.local),
        );
        final unpinnedOld = await fixture.database.conversationDao
            .insertConversation(
              .insert(workspaceId: workspace.id, title: 'Unpinned old'),
            );
        final pinnedOld = await fixture.database.conversationDao
            .insertConversation(
              .insert(
                workspaceId: workspace.id,
                title: 'Pinned old',
                isPinned: const Value(true),
              ),
            );
        final pinnedRecent = await fixture.database.conversationDao
            .insertConversation(
              .insert(
                workspaceId: workspace.id,
                title: 'Pinned recent',
                isPinned: const Value(true),
              ),
            );
        final unpinnedRecent = await fixture.database.conversationDao
            .insertConversation(
              .insert(workspaceId: workspace.id, title: 'Unpinned recent'),
            );
        final _ = await fixture.database.conversationDao.patchConversation(
          unpinnedOld.id,
          .new(updatedAt: .new(DateTime.utc(2025))),
        );
        final _ = await fixture.database.conversationDao.patchConversation(
          pinnedOld.id,
          .new(updatedAt: .new(DateTime.utc(2025, 1, 2))),
        );
        final _ = await fixture.database.conversationDao.patchConversation(
          pinnedRecent.id,
          .new(updatedAt: .new(DateTime.utc(2025, 1, 3))),
        );
        final _ = await fixture.database.conversationDao.patchConversation(
          unpinnedRecent.id,
          .new(updatedAt: .new(DateTime.utc(2025, 1, 4))),
        );

        final conversations = await fixture.database.conversationDao
            .watchConversationsByWorkspace(workspace.id)
            .first;

        expect(
          conversations.map((conversation) => conversation.id),
          equals([
            pinnedRecent.id,
            pinnedOld.id,
            unpinnedRecent.id,
            unpinnedOld.id,
          ]),
        );
      },
    );

    test('rejects more than ten pinned conversations per workspace', () async {
      final workspace = await fixture.database.workspaceDao.insertWorkspace(
        .insert(name: 'WS', type: WorkspaceType.local),
      );
      final conversations = [
        for (
          var index = 0;
          index < ConversationLimits.maxPinnedPerWorkspace + 1;
          index++
        )
          await fixture.database.conversationDao.insertConversation(
            .insert(workspaceId: workspace.id, title: 'Conversation $index'),
          ),
      ];

      for (final conversation in conversations.take(
        ConversationLimits.maxPinnedPerWorkspace,
      )) {
        expect(
          await fixture.database.conversationDao.patchConversation(
            conversation.id,
            const ConversationsCompanion(isPinned: .new(true)),
          ),
          isTrue,
        );
      }

      await expectLater(
        fixture.database.conversationDao.patchConversation(
          conversations.last.id,
          const ConversationsCompanion(isPinned: .new(true)),
        ),
        throwsA(isA<ConversationPinLimitException>()),
      );
      await expectLater(
        fixture.database.conversationDao.insertConversation(
          .insert(
            workspaceId: workspace.id,
            title: 'Inserted over cap',
            isPinned: const Value(true),
          ),
        ),
        throwsA(isA<ConversationPinLimitException>()),
      );
      expect(
        ConversationPinLimitException(workspace.id).toString(),
        'ConversationPinLimitException: workspace ${workspace.id} has reached '
        'the pinned conversation limit',
      );
      final emitted = await fixture.database.conversationDao
          .watchConversationsByWorkspace(workspace.id)
          .first;
      expect(
        emitted.where((conversation) => conversation.isPinned),
        hasLength(ConversationLimits.maxPinnedPerWorkspace),
      );
    });

    test('watchConversationsByWorkspace with limit', () async {
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        .insert(name: 'WS', type: WorkspaceType.local),
      );
      final _ = await fixture.database.conversationDao.insertConversation(
        .insert(workspaceId: ws.id, title: 'A'),
      );
      final _ = await fixture.database.conversationDao.insertConversation(
        .insert(workspaceId: ws.id, title: 'B'),
      );
      final emitted = await fixture.database.conversationDao
          .watchConversationsByWorkspace(ws.id, limit: 1)
          .first;
      expect(emitted.length, equals(1));
    });
  });
}
