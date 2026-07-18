import 'dart:async';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/titles_streams_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeConversationRepository implements ConversationRepository {
  ConversationEntity? conversationById;
  List<ConversationEntity> conversationsByWorkspace = const [];

  @override
  Stream<ConversationEntity?> watchConversationById(String id) =>
      Stream.value(conversationById);

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    int? limit,
  }) => Stream.value(conversationsByWorkspace);

  @override
  Stream<List<ConversationEntity>> watchChildConversations(
    String parentConversationId,
  ) => const Stream.empty();

  @override
  Future<List<ConversationEntity>> getChildConversations(
    String parentConversationId,
  ) async => const [];

  @override
  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity?> getConversationById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteConversation(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity> patchConversation(
    String id,
    ConversationPatch conversation,
  ) {
    throw UnimplementedError();
  }
}

void main() {
  group('conversationByIdStreamProvider', () {
    final fixture = _ConversationProviderFixture();

    setUp(fixture.reset);

    tearDown(fixture.dispose);

    test('emits conversation from repository stream', () async {
      final conversation = ConversationEntity(
        id: 'c1',
        title: 'Test',
        workspaceId: 'ws1',
        isPinned: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      fixture.repository.conversationById = conversation;
      final provider = conversationByIdStreamProvider(
        'ws1',
        conversationId: 'c1',
      );
      final result = Completer<ConversationEntity?>();
      final subscription = fixture.container.listen(
        provider,
        (_, next) {
          if (next case AsyncData(:final value)) result.complete(value);
        },
        fireImmediately: true,
      );
      final value = await result.future;
      subscription.close();

      expect(value, equals(conversation));
    });
  });

  group('conversationsStreamProvider', () {
    final fixture = _ConversationProviderFixture();

    setUp(fixture.reset);

    tearDown(fixture.dispose);

    test('emits conversations list from repository stream', () async {
      final conversations = [
        ConversationEntity(
          id: 'c1',
          title: 'Chat 1',
          workspaceId: 'ws1',
          isPinned: false,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ];

      fixture.repository.conversationsByWorkspace = conversations;
      final provider = conversationsStreamProvider(workspaceId: 'ws1');
      final result = Completer<List<ConversationEntity>>();
      final subscription = fixture.container.listen(
        provider,
        (_, next) {
          if (next case AsyncData(:final value)) result.complete(value);
        },
        fireImmediately: true,
      );
      final value = await result.future;
      subscription.close();

      expect(value, equals(conversations));
    });
  });

  group('streamingTitleProvider', () {
    test('returns null when no title for conversation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(streamingTitleProvider('c1')), isNull);
    });

    test('returns title when set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(titlesStreamsProvider.notifier).updateTitle('c1', 'New');
      expect(container.read(streamingTitleProvider('c1')), 'New');
    });
  });

  test(
    'conversation list resolves route session without scope override',
    () async {
      final repository = _FakeConversationRepository()
        ..conversationsByWorkspace = const [];
      final container = ProviderContainer(
        overrides: [
          workspaceSessionForRouteProvider('ws1').overrideWith(
            (_) async => const WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: 'ws1'),
            ),
          ),
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        conversationsStreamProvider(workspaceId: 'ws1'),
        (_, next) => next.toString(),
      );
      addTearDown(subscription.close);

      await expectLater(
        container.read(conversationsStreamProvider(workspaceId: 'ws1').future),
        completes,
      );
    },
  );
}

class _ConversationProviderFixture {
  _FakeConversationRepository? _repository;
  ProviderContainer? _container;

  _FakeConversationRepository get repository =>
      _repository ?? fail('Fixture not initialized');

  ProviderContainer get container =>
      _container ?? fail('Fixture not initialized');

  void reset() {
    final repository = _FakeConversationRepository();
    _repository = repository;
    _container = ProviderContainer(
      overrides: [
        workspaceSessionForRouteProvider('ws1').overrideWith(
          (_) async => const WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: 'ws1'),
          ),
        ),
        workspaceSessionProvider.overrideWithValue(
          const WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: 'ws1'),
          ),
        ),
        conversationRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  void dispose() {
    container.dispose();
    _repository = null;
    _container = null;
  }
}
