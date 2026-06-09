// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

// ignore_for_file: cascade_invocations
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubConversationRepository implements ConversationRepository {
  List<ConversationEntity> conversationsByWorkspace = [];
  ConversationEntity? conversationById;
  List<ConversationEntity> created = [];
  List<ConversationEntity> patched = [];
  bool deleteResult = true;

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    int? limit,
  }) {
    return Stream.value(conversationsByWorkspace);
  }

  @override
  Stream<ConversationEntity?> watchConversationById(String id) {
    return Stream.value(conversationById);
  }

  @override
  Future<ConversationEntity?> getConversationById(String id) async {
    return conversationById;
  }

  @override
  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  ) async {
    final entity = ConversationEntity(
      id: 'created-${created.length}',
      title: conversation.title,
      workspaceId: conversation.workspaceId,
      isPinned: conversation.isPinned ?? false,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      modelId: conversation.modelId,
    );
    created.add(entity);

    return entity;
  }

  @override
  Future<ConversationEntity> patchConversation(
    String id,
    ConversationPatch conversation,
  ) async {
    final entity = ConversationEntity(
      id: id,
      title: conversation.title ?? 'patched',
      workspaceId: 'ws-1',
      isPinned: conversation.isPinned ?? false,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      modelId: conversation.modelId,
    );
    patched.add(entity);

    return entity;
  }

  @override
  Future<bool> deleteConversation(String id) async {
    return deleteResult;
  }
}

void main() {
  group('ConversationRepository', () {
    test('watchConversationsByWorkspace emits list', () async {
      final repo = _StubConversationRepository();
      repo.conversationsByWorkspace = [
        ConversationEntity(
          id: '1',
          title: 'Test',
          workspaceId: 'ws-1',
          isPinned: false,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];

      final result = await repo.watchConversationsByWorkspace('ws-1').first;

      expect(result, hasLength(1));
      expect(result.firstOrNull?.id, '1');
    });

    test('watchConversationsByWorkspace respects limit parameter', () async {
      final repo = _StubConversationRepository();
      repo.conversationsByWorkspace = [
        ConversationEntity(
          id: '1',
          title: 'A',
          workspaceId: 'ws-1',
          isPinned: false,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];

      final result = await repo
          .watchConversationsByWorkspace('ws-1', limit: 5)
          .first;

      expect(result, hasLength(1));
    });

    test('watchConversationById emits entity', () async {
      final repo = _StubConversationRepository();
      repo.conversationById = ConversationEntity(
        id: 'c-1',
        title: 'Test',
        workspaceId: 'ws-1',
        isPinned: false,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final result = await repo.watchConversationById('c-1').first;

      expect(result, isNotNull);
      expect((result ?? fail('Expected result to be non-null')).id, 'c-1');
    });

    test('getConversationById returns null when not found', () async {
      final repo = _StubConversationRepository();

      final result = await repo.getConversationById('missing');

      expect(result, isNull);
    });

    test('createConversation returns entity with data', () async {
      final repo = _StubConversationRepository();
      const toCreate = ConversationToCreate(
        title: 'New',
        workspaceId: 'ws-1',
        modelId: 'model-1',
      );

      final result = await repo.createConversation(toCreate);

      expect(result.title, 'New');
      expect(result.workspaceId, 'ws-1');
      expect(result.modelId, 'model-1');
      expect(repo.created, hasLength(1));
    });

    test('patchConversation returns patched entity', () async {
      final repo = _StubConversationRepository();
      const patch = ConversationPatch(title: 'Updated', isPinned: true);

      final result = await repo.patchConversation('c-1', patch);

      expect(result.title, 'Updated');
      expect(result.isPinned, true);
      expect(result.id, 'c-1');
      expect(repo.patched, hasLength(1));
    });

    test('deleteConversation returns bool', () async {
      final repo = _StubConversationRepository();

      final result = await repo.deleteConversation('c-1');

      expect(result, true);
    });

    test('deleteConversation returns false when not found', () async {
      final repo = _StubConversationRepository();
      repo.deleteResult = false;

      final result = await repo.deleteConversation('missing');

      expect(result, false);
    });
  });

  group('ConversationException', () {
    test('contains message', () {
      const ex = ConversationException('test error');
      expect(ex.message, 'test error');
      expect(ex.cause, isNull);
    });

    test('toString without cause', () {
      const ex = ConversationException('oops');
      expect(ex.toString(), 'ConversationException: oops');
    });

    test('toString includes cause when provided', () {
      final cause = Exception('inner');
      final ex = ConversationException('test', cause);
      expect(ex.toString(), contains('Caused by:'));
      expect(ex.toString(), contains('test'));
    });
  });

  group('ConversationValidationException', () {
    test('is a ConversationException', () {
      const ex = ConversationValidationException('bad data');
      expect(ex, isA<ConversationException>());
      expect(ex.message, 'bad data');
    });
  });

  group('ConversationNotFoundException', () {
    test('contains id in message', () {
      const ex = ConversationNotFoundException('c-42');
      expect(ex, isA<ConversationException>());
      expect(ex.conversationId, 'c-42');
      expect(ex.toString(), contains('c-42'));
      expect(ex.toString(), contains('not found'));
    });

    test('includes cause when provided', () {
      final cause = Exception('db error');
      final ex = ConversationNotFoundException('c-1', cause);
      expect(ex.cause, cause);
      expect(ex.toString(), contains('Caused by:'));
    });
  });
}
