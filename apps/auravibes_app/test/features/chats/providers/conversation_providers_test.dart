// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.

import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/titles_streams_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeConversationRepository implements ConversationRepository {
  final StreamController<ConversationEntity?> _byIdController =
      StreamController<ConversationEntity?>.broadcast();
  final StreamController<List<ConversationEntity>> _byWorkspaceController =
      StreamController<List<ConversationEntity>>.broadcast();

  void emitById(ConversationEntity? conversation) =>
      _byIdController.add(conversation);

  void emitByWorkspace(List<ConversationEntity> conversations) =>
      _byWorkspaceController.add(conversations);

  Future<void> dispose() async {
    final _ = await _byIdController.close();
    final _ = await _byWorkspaceController.close();
  }

  @override
  Stream<ConversationEntity?> watchConversationById(String id) =>
      _byIdController.stream;

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    int? limit,
  }) => _byWorkspaceController.stream;

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
    late _FakeConversationRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _FakeConversationRepository();
      container = ProviderContainer(
        overrides: [
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await repository.dispose();
    });

    test('emits conversation from repository stream', () async {
      final conversation = ConversationEntity(
        id: 'c1',
        title: 'Test',
        workspaceId: 'ws1',
        isPinned: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final completer = Completer<void>();
      final _ = container.listen(
        conversationByIdStreamProvider(conversationId: 'c1'),
        (_, next) {
          if (next.hasValue && !completer.isCompleted) {
            completer.complete();
          }
        },
        fireImmediately: true,
      );

      repository.emitById(conversation);
      await completer.future;

      final asyncValue = container.read(
        conversationByIdStreamProvider(conversationId: 'c1'),
      );
      expect(asyncValue.value, equals(conversation));
    });
  });

  group('conversationsStreamProvider', () {
    late _FakeConversationRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _FakeConversationRepository();
      container = ProviderContainer(
        overrides: [
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await repository.dispose();
    });

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

      final completer = Completer<void>();
      final _ = container.listen(
        conversationsStreamProvider(workspaceId: 'ws1'),
        (_, next) {
          if (next.hasValue && !completer.isCompleted) {
            completer.complete();
          }
        },
        fireImmediately: true,
      );

      repository.emitByWorkspace(conversations);
      await completer.future;

      final asyncValue = container.read(
        conversationsStreamProvider(workspaceId: 'ws1'),
      );
      expect(asyncValue.value, equals(conversations));
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
}
