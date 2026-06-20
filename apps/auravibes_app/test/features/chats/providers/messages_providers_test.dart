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

class _MessagesProvidersFixture {
  _FakeMessageRepository? _repository;
  ProviderContainer? _container;

  _FakeMessageRepository get repository =>
      _repository ?? fail('Repository fixture not initialized.');

  ProviderContainer get container =>
      _container ?? fail('Container fixture not initialized.');

  void setUp() {
    final repository = _FakeMessageRepository();
    _repository = repository;
    _container = ProviderContainer(
      overrides: [
        conversationSelectedProvider.overrideWithValue('conv-1'),
        messageRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  Future<void> tearDown() async {
    container.dispose();
    await repository.dispose();
    _container = null;
    _repository = null;
  }
}

@Dependencies([
  chatMessageIds,
  chatMessages,
  conversationQueuedDrafts,
  conversationUsedTokens,
])
void main() {
  group('chatMessageIdsProvider', () {
    final fixture = _MessagesProvidersFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns empty list when no messages', () async {
      final _ = fixture.container.listen(
        chatMessagesProvider,
        (_, _) {
          final _ = Object();
        },
        fireImmediately: true,
      );
      fixture.repository.emit([]);
      await Future<void>.delayed(Duration.zero);

      expect(fixture.container.read(chatMessageIdsProvider), isEmpty);
    });

    test('returns message ids from messages', () async {
      final _ = fixture.container.listen(
        chatMessagesProvider,
        (_, _) {
          final _ = Object();
        },
        fireImmediately: true,
      );
      fixture.repository.emit([
        _message(id: 'm1', content: 'hi', isUser: true),
        _message(id: 'm2', content: 'hello', isUser: false),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(fixture.container.read(chatMessageIdsProvider), ['m1', 'm2']);
    });
  });

  group('isMessageStreamingProvider', () {
    final fixture = _MessagesProvidersFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns false when message is not streaming', () async {
      final _ = fixture.container.listen(
        chatMessagesProvider,
        (_, _) {
          final _ = Object();
        },
        fireImmediately: true,
      );
      fixture.repository.emit([
        _message(id: 'm1', content: 'hi', isUser: true),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(
        fixture.container.read(isMessageStreamingProvider('m1')),
        isFalse,
      );
    });

    test('returns true when message is streaming', () async {
      fixture.container
        ..listen(
          chatMessagesProvider,
          (_, _) {
            final _ = Object();
          },
          fireImmediately: true,
        )
        ..listen(
          isMessageStreamingProvider('m1'),
          (_, _) {
            final _ = Object();
          },
          fireImmediately: true,
        );
      fixture.repository.emit([
        _message(id: 'm1', content: 'hi', isUser: true),
      ]);
      await Future<void>.delayed(Duration.zero);

      fixture.container
          .read(messagesStreamingProvider.notifier)
          .startSubscription(CompositeSubscription(), 'm1');
      await Future<void>.delayed(Duration.zero);

      expect(
        fixture.container.read(isMessageStreamingProvider('m1')),
        isTrue,
      );
    });
  });

  group('conversationUsedTokensProvider', () {
    final fixture = _MessagesProvidersFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns 0 when no messages', () async {
      final _ = fixture.container.listen(
        chatMessagesProvider,
        (_, _) {
          final _ = Object();
        },
        fireImmediately: true,
      );
      fixture.repository.emit([]);
      await Future<void>.delayed(Duration.zero);

      expect(fixture.container.read(conversationUsedTokensProvider), 0);
    });

    test('returns 0 when only user messages exist', () async {
      final _ = fixture.container.listen(
        chatMessagesProvider,
        (_, _) {
          final _ = Object();
        },
        fireImmediately: true,
      );
      fixture.repository.emit([
        _message(id: 'm1', content: 'hi', isUser: true),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(fixture.container.read(conversationUsedTokensProvider), 0);
    });

    test('returns metadata tokens from latest assistant message', () async {
      final _ = fixture.container.listen(
        chatMessagesProvider,
        (_, _) {
          final _ = Object();
        },
        fireImmediately: true,
      );
      fixture.repository.emit([
        _message(id: 'm1', content: 'hi', isUser: true),
        _message(
          id: 'm2',
          content: 'hello',
          isUser: false,
          metadata: const MessageMetadataEntity(totalTokens: 500),
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(fixture.container.read(conversationUsedTokensProvider), 500);
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
