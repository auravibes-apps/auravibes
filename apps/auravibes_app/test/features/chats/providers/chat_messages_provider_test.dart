import 'dart:async';

import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain/langchain.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

List<String> _messageIds(ProviderContainer container) =>
    container.read(chatMessagesProvider).value?.map((m) => m.id).toList() ??
    const [];

void main() {
  group('chatMessagesProvider', () {
    late _FakeMessageRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _FakeMessageRepository();
      container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conversation-1'),
          messageRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await repository.dispose();
    });

    test('updates from repository stream without one-shot refetches', () async {
      container.listen(chatMessagesProvider, (_, _) {}, fireImmediately: true);

      repository.emit([
        _message(id: 'message-1', content: 'hello', isUser: true),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(repository.watchedConversationIds, ['conversation-1']);
      expect(repository.getMessagesByConversationCallCount, 0);
      expect(
        container.read(chatMessagesProvider).value,
        [
          _message(id: 'message-1', content: 'hello', isUser: true),
        ],
      );
      expect(_messageIds(container), ['message-1']);

      repository.emit([
        _message(id: 'message-1', content: 'hello', isUser: true),
        _message(id: 'message-2', content: 'hi there', isUser: false),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(chatMessagesProvider).value,
        [
          _message(id: 'message-1', content: 'hello', isUser: true),
          _message(id: 'message-2', content: 'hi there', isUser: false),
        ],
      );
      expect(_messageIds(container), ['message-1', 'message-2']);
    });

    test('applies streaming overlay only in message provider', () async {
      container
        ..listen(chatMessagesProvider, (_, _) {}, fireImmediately: true)
        ..listen(
          messageConversationByIdProvider('message-1'),
          (_, _) {},
          fireImmediately: true,
        );

      repository.emit([
        _message(id: 'message-1', content: 'persisted', isUser: false),
      ]);
      await Future<void>.delayed(Duration.zero);

      container.read(messagesStreamingProvider.notifier)
        ..startSubscription(CompositeSubscription(), 'message-1')
        ..updateResult(
          const ChatResult(
            id: 'chunk-1',
            output: AIChatMessage(content: 'streaming'),
            finishReason: FinishReason.unspecified,
            metadata: {},
            usage: LanguageModelUsage(),
            streaming: true,
          ),
          'message-1',
        );
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(chatMessagesProvider).value,
        [_message(id: 'message-1', content: 'persisted', isUser: false)],
      );
      expect(
        container.read(messageConversationByIdProvider('message-1'))?.content,
        'streaming',
      );
    });

    test(
      'uses latest assistant usage and replaces with streaming value',
      () async {
        container
          ..listen(
            chatMessagesProvider,
            (_, _) {},
            fireImmediately: true,
          )
          ..listen(
            conversationUsedTokensProvider,
            (_, _) {},
            fireImmediately: true,
          );

        repository.emit([
          _message(
            id: 'message-1',
            content: 'first',
            isUser: true,
            metadata: const MessageMetadataEntity(totalTokens: 1000),
          ),
          _message(
            id: 'message-2',
            content: 'second',
            isUser: false,
            metadata: const MessageMetadataEntity(totalTokens: 500),
          ),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(conversationUsedTokensProvider), 500);

        container.read(messagesStreamingProvider.notifier)
          ..startSubscription(CompositeSubscription(), 'message-2')
          ..updateResult(
            const ChatResult(
              id: 'chunk-2',
              output: AIChatMessage(content: 'streaming'),
              finishReason: FinishReason.unspecified,
              metadata: {},
              usage: LanguageModelUsage(totalTokens: 900),
              streaming: true,
            ),
            'message-2',
          );
        await Future<void>.delayed(Duration.zero);

        expect(container.read(conversationUsedTokensProvider), 900);
      },
    );

    test('computes token usage percentage, clamps progress at 100%', () async {
      container =
          ProviderContainer(
              overrides: [
                conversationSelectedProvider.overrideWithValue(
                  'conversation-1',
                ),
                messageRepositoryProvider.overrideWithValue(repository),
                conversationContextLimitProvider.overrideWith(
                  (ref) async => 1000,
                ),
              ],
            )
            ..listen(chatMessagesProvider, (_, _) {}, fireImmediately: true)
            ..listen(
              conversationTokenUsageSummaryProvider,
              (_, _) {},
              fireImmediately: true,
            );

      repository.emit([
        _message(
          id: 'message-1',
          content: 'first',
          isUser: false,
          metadata: const MessageMetadataEntity(totalTokens: 1900),
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      final summaryAsync = container.read(
        conversationTokenUsageSummaryProvider,
      );
      final summary = summaryAsync.value;

      expect(summary?.usedTokens, 1900);
      expect(summary?.limitTokens, 1000);
      expect(summary?.percent, 190);
      expect(summary?.progress, 1);
    });
  });
}

MessageEntity _message({
  required String id,
  required String content,
  required bool isUser,
  MessageMetadataEntity? metadata,
}) {
  final now = DateTime(2026);

  return MessageEntity(
    id: id,
    conversationId: 'conversation-1',
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

  final List<String> watchedConversationIds = [];
  int getMessagesByConversationCallCount = 0;

  void emit(List<MessageEntity> messages) {
    _controller.add(messages);
  }

  Future<void> dispose() {
    return _controller.close();
  }

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
  ) async {
    getMessagesByConversationCallCount++;
    return const [];
  }

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
  Future<MessageEntity> updateMessage(String id, MessageToUpdate message) {
    throw UnimplementedError();
  }

  @override
  Future<bool> validateMessage(MessageToCreate message) {
    throw UnimplementedError();
  }

  @override
  Stream<List<MessageEntity>> watchMessagesByConversation(
    String conversationId,
  ) {
    watchedConversationIds.add(conversationId);
    return _controller.stream;
  }
}
