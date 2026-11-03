import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_list_query_options.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../database_test_utils.dart';

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
      _database ??= .new(connection: createConnection());

  Future<void> reset() => clearAppDatabase(database);

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

void main() {
  group('ConversationDao', () {
    final fixture = _DatabaseFixture(createTestConnection);

    var isFirstTest = true;
    setUp(() async {
      if (isFirstTest) {
        isFirstTest = false;

        return;
      }

      await fixture.reset();
    });

    tearDownAll(() async {
      await fixture.close();
    });

    test('database fixture reuses its database after reset', () async {
      final originalDatabase = fixture.database;

      await fixture.reset();

      expect(fixture.database, same(originalDatabase));
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
      final directory = await Directory.systemTemp.createTemp(
        'auravibes-conversation-',
      );
      final file = File('${directory.path}/conversations.sqlite');
      AppDatabase database = _ConversationDatabaseBeforeReopen(
        NativeDatabase(file),
      );
      addTearDown(() async {
        await database.close();
        final _ = await directory.delete(recursive: true);
      });

      final workspace = await database.workspaceDao.insertWorkspace(
        .insert(name: 'WS', type: WorkspaceType.local),
      );
      final agent = await database.agentsDao.createAgent(
        .new(
          workspaceId: .new(workspace.id),
          name: const .new('Agent'),
          content: const .new('Prompt'),
        ),
        const [],
      );
      final conversation = await database.conversationDao.insertConversation(
        .insert(
          workspaceId: workspace.id,
          title: 'Pinned',
          agentId: .new(agent.id),
        ),
      );
      final _ = await database.conversationDao.patchConversation(
        conversation.id,
        const ConversationsCompanion(isPinned: .new(true)),
      );
      await database.close();

      database = _ConversationDatabaseAfterReopen(NativeDatabase(file));
      final restored = await database.conversationDao.getConversationById(
        conversation.id,
      );

      final restoredConversation =
          restored ?? fail('Expected restored conversation');
      expect(restoredConversation.isPinned, isTrue);
      expect(restoredConversation.agentId, agent.id);
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
        final firstPage = await fixture.database.conversationDao
            .watchConversationsByWorkspace(
              workspace.id,
              options: ConversationListQueryOptions(
                search: '',
                archivedOnly: false,
                limit: 1,
                offset: 0,
              ),
            )
            .first;
        final secondPage = await fixture.database.conversationDao
            .watchConversationsByWorkspace(
              workspace.id,
              options: ConversationListQueryOptions(
                search: '',
                archivedOnly: false,
                limit: 1,
                offset: 1,
              ),
            )
            .first;

        expect(firstPage.single.id, pinnedRecent.id);
        expect(secondPage.single.id, pinnedOld.id);
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
          .watchConversationsByWorkspace(
            ws.id,
            options: ConversationListQueryOptions(
              search: '',
              archivedOnly: false,
              limit: 1,
              offset: 0,
            ),
          )
          .first;
      expect(emitted.length, equals(1));
    });

    test('watchConversationsByWorkspace searches and applies offset', () async {
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        .insert(name: 'WS', type: WorkspaceType.local),
      );
      final _ = await fixture.database.conversationDao.insertConversation(
        .insert(workspaceId: ws.id, title: 'Release Plan'),
      );
      final _ = await fixture.database.conversationDao.insertConversation(
        .insert(workspaceId: ws.id, title: 'Design Brief'),
      );
      final _ = await fixture.database.conversationDao.insertConversation(
        .insert(workspaceId: ws.id, title: 'Release Notes'),
      );

      final allMatches = await fixture.database.conversationDao
          .watchConversationsByWorkspace(
            ws.id,
            options: ConversationListQueryOptions(
              search: 'release',
              archivedOnly: false,
              limit: null,
              offset: 0,
            ),
          )
          .first;
      final page = await fixture.database.conversationDao
          .watchConversationsByWorkspace(
            ws.id,
            options: ConversationListQueryOptions(
              search: 'release',
              archivedOnly: false,
              limit: 1,
              offset: 1,
            ),
          )
          .first;

      expect(allMatches, hasLength(2));
      expect(page, hasLength(1));
      expect(page.single.id, allMatches[1].id);
    });

    test(
      'archive filtering stays workspace-local and supports search',
      () async {
        final workspace = await fixture.database.workspaceDao.insertWorkspace(
          .insert(name: 'Archive workspace', type: WorkspaceType.local),
        );
        final otherWorkspace = await fixture.database.workspaceDao
            .insertWorkspace(
              .insert(name: 'Other workspace', type: WorkspaceType.local),
            );
        final archivedMatch = await fixture.database.conversationDao
            .insertConversation(
              .insert(
                id: const Value('archived-match'),
                workspaceId: workspace.id,
                title: 'Project plan',
                updatedAt: Value(DateTime.utc(2026)),
              ),
            );
        final archivedOther = await fixture.database.conversationDao
            .insertConversation(
              .insert(
                id: const Value('archived-other'),
                workspaceId: workspace.id,
                title: 'Design outline',
                updatedAt: Value(DateTime.utc(2026)),
              ),
            );
        final active = await fixture.database.conversationDao
            .insertConversation(
              .insert(
                id: const Value('active'),
                workspaceId: workspace.id,
                title: 'Project active',
                updatedAt: Value(DateTime.utc(2026)),
              ),
            );
        final archivedElsewhere = await fixture.database.conversationDao
            .insertConversation(
              .insert(
                id: const Value('archived-elsewhere'),
                workspaceId: otherWorkspace.id,
                title: 'Project elsewhere',
                updatedAt: Value(DateTime.utc(2026)),
              ),
            );

        for (final conversation in [
          archivedMatch,
          archivedOther,
          archivedElsewhere,
        ]) {
          await fixture.database.conversationArchiveStateDao.setArchived(
            workspaceId: conversation.workspaceId,
            conversationId: conversation.id,
            isArchived: true,
          );
        }

        final activeConversations = await fixture.database.conversationDao
            .watchConversationsByWorkspace(workspace.id)
            .first;
        final archivedConversations = await fixture.database.conversationDao
            .watchConversationsByWorkspace(
              workspace.id,
              options: ConversationListQueryOptions(
                search: '',
                archivedOnly: true,
                limit: null,
                offset: 0,
              ),
            )
            .first;
        final searchedArchive = await fixture.database.conversationDao
            .watchConversationsByWorkspace(
              workspace.id,
              options: ConversationListQueryOptions(
                search: 'project',
                archivedOnly: true,
                limit: null,
                offset: 0,
              ),
            )
            .first;
        final archivePage = await fixture.database.conversationDao
            .watchConversationsByWorkspace(
              workspace.id,
              options: ConversationListQueryOptions(
                search: '',
                archivedOnly: true,
                limit: 1,
                offset: 1,
              ),
            )
            .first;

        expect(activeConversations.map((conversation) => conversation.id), [
          active.id,
        ]);
        expect(
          archivedConversations.map((conversation) => conversation.id).toSet(),
          {archivedMatch.id, archivedOther.id},
        );
        expect(searchedArchive.map((conversation) => conversation.id), [
          archivedMatch.id,
        ]);
        expect(archivePage.map((conversation) => conversation.id), [
          archivedMatch.id,
        ]);
      },
    );

    test('archive state can be restored idempotently', () async {
      final workspace = await fixture.database.workspaceDao.insertWorkspace(
        .insert(name: 'Archive state workspace', type: WorkspaceType.local),
      );
      final conversation = await fixture.database.conversationDao
          .insertConversation(
            .insert(workspaceId: workspace.id, title: 'Restore me'),
          );

      await fixture.database.conversationArchiveStateDao.setArchived(
        workspaceId: workspace.id,
        conversationId: conversation.id,
        isArchived: true,
      );
      await fixture.database.conversationArchiveStateDao.setArchived(
        workspaceId: workspace.id,
        conversationId: conversation.id,
        isArchived: true,
      );
      expect(
        await fixture.database.conversationArchiveStateDao
            .getArchivedConversationIds(workspace.id),
        {conversation.id},
      );

      await fixture.database.conversationArchiveStateDao.setArchived(
        workspaceId: workspace.id,
        conversationId: conversation.id,
        isArchived: false,
      );
      expect(
        await fixture.database.conversationArchiveStateDao
            .getArchivedConversationIds(workspace.id),
        isEmpty,
      );
    });

    test(
      'archive round trip preserves transcript, attachment, and fork link',
      () async {
        final workspace = await fixture.database.workspaceDao.insertWorkspace(
          .insert(
            name: 'Archive preservation workspace',
            type: WorkspaceType.local,
          ),
        );
        final conversation = await fixture.database.conversationDao
            .insertConversation(
              .insert(
                workspaceId: workspace.id,
                title: 'Pinned parent',
                isPinned: const Value(true),
              ),
            );
        final child = await fixture.database.conversationDao.insertConversation(
          .insert(
            workspaceId: workspace.id,
            title: 'Child conversation',
            parentConversationId: Value(conversation.id),
          ),
        );
        final message = await fixture.database.messageDao.insertMessage(
          .insert(
            conversationId: conversation.id,
            content: 'Transcript remains available',
            messageType: .text,
            isUser: true,
            status: .sent,
          ),
        );
        final _ = await fixture.database
            .into(fixture.database.messageAttachments)
            .insert(
              MessageAttachmentsCompanion.insert(
                messageId: message.id,
                localPath: '/archive/attachment.png',
                fileName: 'attachment.png',
                mimeType: 'image/png',
                modality: 'image',
                sizeBytes: 128,
              ),
            );

        for (final isArchived in [true, false]) {
          await fixture.database.conversationArchiveStateDao.setArchived(
            workspaceId: workspace.id,
            conversationId: conversation.id,
            isArchived: isArchived,
          );
        }

        final restored = await fixture.database.conversationDao
            .getConversationById(conversation.id);
        final messages = await fixture.database.messageDao
            .getMessagesByConversation(conversation.id);
        final attachments = await fixture.database
            .select(fixture.database.messageAttachments)
            .get();
        final children = await fixture.database.conversationDao
            .getChildConversations(conversation.id);

        expect(restored?.isPinned, isTrue);
        expect(messages.single.content, 'Transcript remains available');
        expect(attachments.single.localPath, '/archive/attachment.png');
        expect(children.map((conversation) => conversation.id), [child.id]);
      },
    );
  });
}

final class _ConversationDatabaseBeforeReopen extends AppDatabase {
  new(QueryExecutor connection) : super(connection: connection);
}

final class _ConversationDatabaseAfterReopen extends AppDatabase {
  new(QueryExecutor connection) : super(connection: connection);
}
