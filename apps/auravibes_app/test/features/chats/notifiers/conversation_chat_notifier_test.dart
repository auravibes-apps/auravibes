// ignore_for_file: avoid-non-null-assertion
// Required: Tests inspect nullable values after arranging expected state.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

// ignore_for_file: provider_dependencies
// Required: provider unit tests read scoped providers directly.

import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_selection_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([ConversationChatNotifier])
void main() {
  group('ConversationResult types', () {
    test('ConversationFound holds conversation', () {
      final conversation = ConversationEntity(
        id: 'conv-1',
        title: 'Test',
        workspaceId: 'ws-1',
        isPinned: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final result = ConversationFound(conversation);
      expect(result.conversation.id, 'conv-1');
    });

    test('ConversationNotFound is a singleton-like const', () {
      const result = ConversationNotFound();
      expect(result, isA<ConversationNotFound>());
    });

    test('ConversationWorkspaceMismatch is a singleton-like const', () {
      const result = ConversationWorkspaceMismatch();
      expect(result, isA<ConversationWorkspaceMismatch>());
    });
  });

  group('ConversationChatNotifier', () {
    final conversation = ConversationEntity(
      id: 'conv-1',
      title: 'Test',
      workspaceId: 'ws-1',
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    test(
      'returns ConversationFound when conversation matches workspace',
      () async {
        final completer = Completer<AsyncValue<ConversationResult>>();

        final container = ProviderContainer(
          overrides: [
            conversationSelectedProvider.overrideWith((ref) => 'conv-1'),
            conversationByIdStreamProvider.overrideWith(
              (ref, conversationId) => Stream.value(conversation),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen<AsyncValue<ConversationResult>>(
          conversationChatProvider('ws-1'),
          (_, next) {
            if (next is AsyncData<ConversationResult>) {
              completer.complete(next);
            }
          },
          fireImmediately: true,
        );

        final result = (await completer.future).value!;
        sub.close();
        expect(result, isA<ConversationFound>());
        expect((result as ConversationFound).conversation.id, 'conv-1');
      },
    );

    test(
      'returns ConversationWorkspaceMismatch for wrong workspace',
      () async {
        final completer = Completer<AsyncValue<ConversationResult>>();

        final container = ProviderContainer(
          overrides: [
            conversationSelectedProvider.overrideWith((ref) => 'conv-1'),
            conversationByIdStreamProvider.overrideWith(
              (ref, conversationId) => Stream.value(conversation),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen<AsyncValue<ConversationResult>>(
          conversationChatProvider('ws-other'),
          (_, next) {
            if (next is AsyncData<ConversationResult>) {
              completer.complete(next);
            }
          },
          fireImmediately: true,
        );

        final result = (await completer.future).value!;
        sub.close();
        expect(result, isA<ConversationWorkspaceMismatch>());
      },
    );

    test('returns ConversationNotFound when conversation is null', () async {
      final completer = Completer<AsyncValue<ConversationResult>>();

      final container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWith((ref) => 'conv-1'),
          conversationByIdStreamProvider.overrideWith(
            (ref, conversationId) => Stream.value(null),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen<AsyncValue<ConversationResult>>(
        conversationChatProvider('ws-1'),
        (_, next) {
          if (next is AsyncData<ConversationResult>) {
            completer.complete(next);
          }
        },
        fireImmediately: true,
      );

      final result = (await completer.future).value!;
      sub.close();
      expect(result, isA<ConversationNotFound>());
    });

    test('setModel updates conversation when ConversationFound', () async {
      final updatedConversation = ConversationEntity(
        id: 'conv-1',
        title: 'Test',
        workspaceId: 'ws-1',
        isPinned: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        modelId: 'model-1',
      );

      final patched = <ConversationPatch>[];

      final container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWith((ref) => 'conv-1'),
          conversationByIdStreamProvider.overrideWith(
            (ref, conversationId) => Stream.value(conversation),
          ),
          conversationRepositoryProvider.overrideWithValue(
            _FakeConversationRepository(
              onPatch: (id, patch) {
                patched.add(patch);
                return updatedConversation;
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      var resolved = false;
      final completer = Completer<AsyncValue<ConversationResult>>();
      final sub = container.listen<AsyncValue<ConversationResult>>(
        conversationChatProvider('ws-1'),
        (_, next) {
          if (next is AsyncData<ConversationResult> && !resolved) {
            resolved = true;
            completer.complete(next);
          }
        },
        fireImmediately: true,
      );

      final _ = await completer.future;

      final notifier = container.read(
        conversationChatProvider('ws-1').notifier,
      );
      await notifier.setModel('model-1');

      expect(patched, hasLength(1));
      expect(patched.firstOrNull?.modelId, 'model-1');

      final state = container.read(conversationChatProvider('ws-1')).value;
      expect(state, isA<ConversationFound>());
      expect(
        (state! as ConversationFound).conversation.modelId,
        'model-1',
      );

      sub.close();
    });

    test('setModel does nothing when ConversationNotFound', () async {
      final container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWith((ref) => 'conv-1'),
          conversationByIdStreamProvider.overrideWith(
            (ref, conversationId) => Stream.value(null),
          ),
        ],
      );
      addTearDown(container.dispose);

      final completer = Completer<AsyncValue<ConversationResult>>();
      final sub = container.listen<AsyncValue<ConversationResult>>(
        conversationChatProvider('ws-1'),
        (_, next) {
          if (next is AsyncData<ConversationResult>) {
            completer.complete(next);
          }
        },
        fireImmediately: true,
      );

      final _ = await completer.future;

      final notifier = container.read(
        conversationChatProvider('ws-1').notifier,
      );
      await notifier.setModel('model-1');

      final state = container.read(conversationChatProvider('ws-1')).value;
      expect(state, isA<ConversationNotFound>());

      sub.close();
    });

    test('setModel does nothing when ConversationWorkspaceMismatch', () async {
      final container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWith((ref) => 'conv-1'),
          conversationByIdStreamProvider.overrideWith(
            (ref, conversationId) => Stream.value(conversation),
          ),
        ],
      );
      addTearDown(container.dispose);

      final completer = Completer<AsyncValue<ConversationResult>>();
      final sub = container.listen<AsyncValue<ConversationResult>>(
        conversationChatProvider('ws-other'),
        (_, next) {
          if (next is AsyncData<ConversationResult>) {
            completer.complete(next);
          }
        },
        fireImmediately: true,
      );

      final _ = await completer.future;

      final notifier = container.read(
        conversationChatProvider('ws-other').notifier,
      );
      await notifier.setModel('model-1');

      final state = container.read(conversationChatProvider('ws-other')).value;
      expect(state, isA<ConversationWorkspaceMismatch>());

      sub.close();
    });
  });
}

class _FakeConversationRepository implements ConversationRepository {
  _FakeConversationRepository({this.onPatch});

  final ConversationEntity Function(String, ConversationPatch)? onPatch;

  @override
  Future<ConversationEntity> patchConversation(
    String id,
    ConversationPatch patch,
  ) async {
    if (onPatch != null) return onPatch!(id, patch);
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity> createConversation(ConversationToCreate create) =>
      throw UnimplementedError();

  @override
  Future<ConversationEntity?> getConversationById(String id) =>
      throw UnimplementedError();

  @override
  Stream<ConversationEntity?> watchConversationById(String id) =>
      throw UnimplementedError();

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    int? limit,
  }) => throw UnimplementedError();

  @override
  Future<bool> deleteConversation(String id) => throw UnimplementedError();
}
