// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

// ignore_for_file: cascade_invocations
import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/conversation_dao.dart';
import 'package:auravibes_app/data/repositories/conversation_repository_impl.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'conversation_repository_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ConversationDao>()])
void main() {
  group('ConversationRepositoryImpl', () {
    var mockDao = MockConversationDao();
    var database = _TestAppDatabase(mockDao);
    var repository = ConversationRepositoryImpl(database);

    tearDown(() async {
      await database.close();
      mockDao = MockConversationDao();
      database = _TestAppDatabase(mockDao);
      repository = ConversationRepositoryImpl(database);
    });

    tearDownAll(() async {
      await database.close();
    });

    final now = DateTime(2026);

    ConversationsTable createConversationRow({
      String id = 'conv-1',
      String title = 'Test Conversation',
      String workspaceId = 'ws-1',
      String? modelId,
      bool isPinned = false,
    }) {
      return ConversationsTable(
        id: id,
        createdAt: now,
        updatedAt: now,
        workspaceId: workspaceId,
        title: title,
        modelId: modelId,
        isPinned: isPinned,
      );
    }

    group('watchConversationsByWorkspace', () {
      test('maps stream rows to entities', () async {
        final controller = StreamController<List<ConversationsTable>>();
        controller.add([createConversationRow(id: 'c1')]);
        addTearDown(controller.close);

        when(
          mockDao.watchConversationsByWorkspace(
            'ws-1',
            limit: anyNamed('limit'),
          ),
        ).thenAnswer((_) => controller.stream);

        final result = await repository
            .watchConversationsByWorkspace('ws-1')
            .first;

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'c1');
        expect(result.firstOrNull?.title, 'Test Conversation');
      });

      test('passes limit parameter', () async {
        final controller = StreamController<List<ConversationsTable>>();
        controller.add([]);
        addTearDown(controller.close);

        when(
          mockDao.watchConversationsByWorkspace('ws-1', limit: 5),
        ).thenAnswer((_) => controller.stream);

        final _ = await repository
            .watchConversationsByWorkspace('ws-1', limit: 5)
            .first;

        expect(
          () => verify(
            mockDao.watchConversationsByWorkspace('ws-1', limit: 5),
          ).called(1),
          returnsNormally,
        );
      });
    });

    group('watchConversationById', () {
      test('maps non-null stream to entity', () async {
        final controller = StreamController<ConversationsTable?>();
        controller.add(createConversationRow());
        addTearDown(controller.close);

        when(
          mockDao.watchConversationById('conv-1'),
        ).thenAnswer((_) => controller.stream);

        final result = await repository.watchConversationById('conv-1').first;

        expect(result, isNotNull);
        expect((result ?? fail('Expected result to be non-null')).id, 'conv-1');
      });

      test('maps null stream value to null', () async {
        final controller = StreamController<ConversationsTable?>();
        controller.add(null);
        addTearDown(controller.close);

        when(
          mockDao.watchConversationById('nonexistent'),
        ).thenAnswer((_) => controller.stream);

        final result = await repository
            .watchConversationById('nonexistent')
            .first;

        expect(result, isNull);
      });
    });

    group('getConversationById', () {
      test('returns entity when found', () async {
        when(
          mockDao.getConversationById('conv-1'),
        ).thenAnswer((_) async => createConversationRow());

        final result = await repository.getConversationById('conv-1');

        expect(result, isNotNull);
        expect((result ?? fail('Expected result to be non-null')).id, 'conv-1');
        expect(result.title, 'Test Conversation');
        expect(result.workspaceId, 'ws-1');
        expect(result.isPinned, false);
      });

      test('returns null when not found', () async {
        when(
          mockDao.getConversationById('nonexistent'),
        ).thenAnswer((_) async => null);

        final result = await repository.getConversationById('nonexistent');

        expect(result, isNull);
      });
    });

    group('createConversation', () {
      test('creates and returns conversation', () async {
        const toCreate = ConversationToCreate(
          title: 'New Chat',
          workspaceId: 'ws-1',
          isPinned: true,
        );
        final createdRow = ConversationsTable(
          id: 'new-conv',
          createdAt: now,
          updatedAt: now,
          workspaceId: 'ws-1',
          title: 'New Chat',
          isPinned: true,
        );

        when(
          mockDao.insertConversation(any),
        ).thenAnswer((_) async => createdRow);

        final result = await repository.createConversation(toCreate);

        expect(result.id, 'new-conv');
        expect(result.title, 'New Chat');
        expect(result.isPinned, true);
        verify(mockDao.insertConversation(any)).called(1);
      });

      test('throws on empty title', () async {
        const toCreate = ConversationToCreate(
          title: '',
          workspaceId: 'ws-1',
        );

        await expectLater(
          repository.createConversation(toCreate),
          throwsA(isA<ConversationValidationException>()),
        );
      });

      test('throws on empty workspaceId', () async {
        const toCreate = ConversationToCreate(
          title: 'Valid Title',
          workspaceId: '',
        );

        await expectLater(
          repository.createConversation(toCreate),
          throwsA(isA<ConversationValidationException>()),
        );
      });

      test('throws on empty modelId', () async {
        const toCreate = ConversationToCreate(
          title: 'Valid Title',
          workspaceId: 'ws-1',
          modelId: '',
        );

        await expectLater(
          repository.createConversation(toCreate),
          throwsA(isA<ConversationValidationException>()),
        );
        final _ = verifyNever(mockDao.insertConversation(any));
      });
    });

    group('patchConversation', () {
      test('patches and returns updated conversation', () async {
        final updatedRow = ConversationsTable(
          id: 'conv-1',
          createdAt: now,
          updatedAt: now,
          workspaceId: 'ws-1',
          title: 'Updated Title',
          isPinned: true,
        );

        when(
          mockDao.getConversationById('conv-1'),
        ).thenAnswer((_) async => createConversationRow());
        when(
          mockDao.patchConversation('conv-1', any),
        ).thenAnswer((_) async => true);

        when(
          mockDao.getConversationById('conv-1'),
        ).thenAnswer((_) async => updatedRow);

        const patch = ConversationPatch(title: 'Updated Title', isPinned: true);
        final result = await repository.patchConversation('conv-1', patch);

        expect(result.title, 'Updated Title');
        expect(result.isPinned, true);
      });

      test(
        'throws ConversationNotFoundException when conversation missing',
        () async {
          when(
            mockDao.getConversationById('nonexistent'),
          ).thenAnswer((_) async => null);

          const patch = ConversationPatch(title: 'Updated');

          await expectLater(
            repository.patchConversation('nonexistent', patch),
            throwsA(isA<ConversationNotFoundException>()),
          );
        },
      );

      test('throws ConversationException when update fails', () async {
        when(
          mockDao.getConversationById('conv-1'),
        ).thenAnswer((_) async => createConversationRow());
        when(
          mockDao.patchConversation('conv-1', any),
        ).thenAnswer((_) async => false);

        const patch = ConversationPatch(title: 'Updated');

        await expectLater(
          repository.patchConversation('conv-1', patch),
          throwsA(isA<ConversationException>()),
        );
      });

      test('throws on invalid patch with empty title', () async {
        const patch = ConversationPatch(title: '');

        await expectLater(
          repository.patchConversation('conv-1', patch),
          throwsA(isA<ConversationValidationException>()),
        );
      });

      test('throws on empty patch', () async {
        const patch = ConversationPatch();

        await expectLater(
          repository.patchConversation('conv-1', patch),
          throwsA(isA<ConversationValidationException>()),
        );
      });
    });

    group('deleteConversation', () {
      test('returns true when deleted', () async {
        when(
          mockDao.getConversationById('conv-1'),
        ).thenAnswer((_) async => createConversationRow());
        when(
          mockDao.deleteConversation('conv-1'),
        ).thenAnswer((_) async => true);

        final result = await repository.deleteConversation('conv-1');

        expect(result, true);
        verify(mockDao.deleteConversation('conv-1')).called(1);
      });

      test('returns false when not found', () async {
        when(
          mockDao.getConversationById('nonexistent'),
        ).thenAnswer((_) async => null);

        final result = await repository.deleteConversation('nonexistent');

        expect(result, false);
        final _ = verifyNever(mockDao.deleteConversation(any));
      });
    });
  });
}

class _TestAppDatabase extends AppDatabase {
  _TestAppDatabase(this._conversationDao)
    : super(connection: DatabaseConnection(NativeDatabase.memory()));
  final ConversationDao _conversationDao;

  @override
  ConversationDao get conversationDao => _conversationDao;
}
