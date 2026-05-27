// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: no-empty-block
// Required: Tests use intentional no-op callbacks and fake hooks.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.

// ignore_for_file: provider_dependencies
// Required: provider unit tests read scoped providers directly.

import 'dart:async';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_state.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:rxdart/rxdart.dart';

MessageEntity _message({
  required String id,
  required String content,
  required bool isUser,
  MessageMetadataEntity? metadata,
}) {
  final now = DateTime(2026);
  return MessageEntity(
    id: id,
    conversationId: 'conv-1',
    content: content,
    messageType: MessageType.text,
    isUser: isUser,
    status: MessageStatus.sent,
    createdAt: now,
    updatedAt: now,
    metadata: metadata,
  );
}

class _FakeMessageRepository implements MessageRepository {
  final StreamController<List<MessageEntity>> _controller =
      StreamController<List<MessageEntity>>.broadcast();

  void emit(List<MessageEntity> messages) => _controller.add(messages);

  Future<void> dispose() => _controller.close();

  @override
  Stream<List<MessageEntity>> watchMessagesByConversation(
    String conversationId,
  ) => _controller.stream;

  @override
  Future<MessageEntity> createMessage(MessageToCreate message) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteMessage(String id) {
    throw UnimplementedError();
  }

  @override
  Future<MessageEntity?> getMessageById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<int> getMessageCountByConversation(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageEntity>> getMessagesByConversation(
    String conversationId,
  ) async => const [];

  @override
  Future<List<MessageEntity>> getMessagesByConversationPaginated(
    String conversationId,
    int limit,
    int offset,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageEntity>> getMessagesByStatus(
    String conversationId,
    MessageStatus status,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageEntity>> getMessagesByType(
    String conversationId,
    MessageType messageType,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageEntity>> getSystemMessages(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageEntity>> getUserMessages(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> messageExists(String id) {
    throw UnimplementedError();
  }

  @override
  Future<MessageEntity> patchMessage(String id, MessagePatch message) {
    throw UnimplementedError();
  }

  @override
  Future<bool> validateMessage(MessageToCreate message) {
    throw UnimplementedError();
  }

  @override
  Future<MessageEntity?> getLatestCompactionSummary(String conversationId) {
    throw UnimplementedError();
  }
}

@Dependencies([
  chatMessageIds,
  chatMessages,
  conversationQueuedDrafts,
  conversationUsedTokens,
])
void main() {
  group('MessageIdList', () {
    test('returns empty list for empty messages', () {
      const list = MessageIdList.empty;
      expect(list, isEmpty);
    });

    test('returns correct length and elements', () {
      final list = MessageIdList(const ['a', 'b', 'c']);
      expect(list.length, 3);
      expect(list.firstOrNull, 'a');
      expect(list[2], 'c');
    });

    test('equality works correctly', () {
      final a = MessageIdList(const ['1', '2']);
      final b = MessageIdList(const ['1', '2']);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality works correctly', () {
      final a = MessageIdList(const ['1']);
      final b = MessageIdList(const ['2']);
      expect(a, isNot(equals(b)));
    });

    test('setting length throws', () {
      final list = MessageIdList(const ['a']);
      expect(() => list.length = 5, throwsUnsupportedError);
    });

    test('setting index throws', () {
      final list = MessageIdList(const ['a']);
      // ignore: prefer-first-or-null, prefer-first
      expect(() => list[0] = 'b', throwsUnsupportedError);
    });
  });

  group('chatMessageIdsProvider', () {
    late _FakeMessageRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _FakeMessageRepository();
      container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
          messageRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await repository.dispose();
    });

    test('returns empty list when no messages', () async {
      final _ = container.listen(
        chatMessagesProvider,
        (_, _) {},
        fireImmediately: true,
      );
      repository.emit([]);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(chatMessageIdsProvider), isEmpty);
    });

    test('returns message ids from messages', () async {
      final _ = container.listen(
        chatMessagesProvider,
        (_, _) {},
        fireImmediately: true,
      );
      repository.emit([
        _message(id: 'm1', content: 'hi', isUser: true),
        _message(id: 'm2', content: 'hello', isUser: false),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(chatMessageIdsProvider), ['m1', 'm2']);
    });
  });

  group('isMessageStreamingProvider', () {
    late _FakeMessageRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _FakeMessageRepository();
      container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
          messageRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await repository.dispose();
    });

    test('returns false when message is not streaming', () async {
      final _ = container.listen(
        chatMessagesProvider,
        (_, _) {},
        fireImmediately: true,
      );
      repository.emit([_message(id: 'm1', content: 'hi', isUser: true)]);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(isMessageStreamingProvider('m1')), isFalse);
    });

    test('returns true when message is streaming', () async {
      container
        ..listen(chatMessagesProvider, (_, _) {}, fireImmediately: true)
        ..listen(
          isMessageStreamingProvider('m1'),
          (_, _) {},
          fireImmediately: true,
        );
      repository.emit([_message(id: 'm1', content: 'hi', isUser: true)]);
      await Future<void>.delayed(Duration.zero);

      container
          .read(messagesStreamingProvider.notifier)
          .startSubscription(CompositeSubscription(), 'm1');
      await Future<void>.delayed(Duration.zero);

      expect(container.read(isMessageStreamingProvider('m1')), isTrue);
    });
  });

  group('pendingMcpConnectionsProvider', () {
    test('always returns empty list', () {
      final container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(pendingMcpConnectionsProvider), isEmpty);
    });
  });

  group('conversationUsedTokensProvider', () {
    late _FakeMessageRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _FakeMessageRepository();
      container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
          messageRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await repository.dispose();
    });

    test('returns 0 when no messages', () async {
      final _ = container.listen(
        chatMessagesProvider,
        (_, _) {},
        fireImmediately: true,
      );
      repository.emit([]);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(conversationUsedTokensProvider), 0);
    });

    test('returns 0 when only user messages exist', () async {
      final _ = container.listen(
        chatMessagesProvider,
        (_, _) {},
        fireImmediately: true,
      );
      repository.emit([_message(id: 'm1', content: 'hi', isUser: true)]);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(conversationUsedTokensProvider), 0);
    });

    test('returns metadata tokens from latest assistant message', () async {
      final _ = container.listen(
        chatMessagesProvider,
        (_, _) {},
        fireImmediately: true,
      );
      repository.emit([
        _message(id: 'm1', content: 'hi', isUser: true),
        _message(
          id: 'm2',
          content: 'hello',
          isUser: false,
          metadata: const MessageMetadataEntity(totalTokens: 500),
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(conversationUsedTokensProvider), 500);
    });
  });

  group('conversationQueuedDraftsProvider', () {
    test('returns empty list by default', () {
      final container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(conversationQueuedDraftsProvider), isEmpty);
    });
  });
}
