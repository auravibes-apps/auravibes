import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('ConversationSendQueueNotifier', () {
    var container = ProviderContainer();

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('enqueues and dequeues drafts in FIFO order', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final first = notifier.enqueue(
        conversationId: 'conversation-1',
        draft: const ChatDraft(text: 'First queued message'),
      );
      final second = notifier.enqueue(
        conversationId: 'conversation-1',
        draft: const ChatDraft(text: 'Second queued message'),
      );

      expect(notifier.peek('conversation-1')?.content, 'First queued message');
      expect(notifier.dequeue('conversation-1')?.id, first.id);
      expect(notifier.dequeue('conversation-1')?.id, second.id);
      expect(notifier.dequeue('conversation-1'), isNull);
    });

    test('keeps conversation queues independent across peek and dequeue', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final first = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Conv1 First'),
      );
      final second = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Conv1 Second'),
      );
      final other = notifier.enqueue(
        conversationId: 'conv-2',
        draft: const ChatDraft(text: 'Conv2 First'),
      );

      expect(notifier.peek('conv-1')?.id, first.id);
      expect(notifier.peek('conv-2')?.id, other.id);
      expect(notifier.dequeue('conv-1')?.id, first.id);
      expect(notifier.peek('conv-1')?.id, second.id);
      expect(notifier.dequeue('conv-2')?.id, other.id);
    });

    test('dequeueAll preserves order and clears all conversation queues', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final first = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );
      final second = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Second'),
      );
      final third = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Third'),
      );
      final _ = notifier.enqueue(
        conversationId: 'conv-2',
        draft: const ChatDraft(text: 'Other'),
      );

      final all = notifier.dequeueAll('conv-1');

      expect(all.map((draft) => draft.id), [first.id, second.id, third.id]);
      expect(notifier.peek('conv-1'), isNull);
      final _ = notifier.dequeueAll('conv-2');
      expect(container.read(conversationSendQueueProvider), isEmpty);
    });

    test('remove removes a specific draft by id', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final first = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );
      final second = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Second'),
      );

      notifier.remove(conversationId: 'conv-1', draftId: first.id);

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1']?.length, 1);
      expect(state['conv-1']?.first.id, second.id);
    });

    test('remove with unknown draftId is no-op', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final _ = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );
      notifier.remove(conversationId: 'conv-1', draftId: 'nonexistent');

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1']?.length, 1);
    });

    test('remove with unknown conversationId is no-op', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final draft = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );

      notifier.remove(conversationId: 'unknown', draftId: draft.id);

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1']?.length, 1);
    });

    test('remove last draft clears conversation entry', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final draft = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Only one'),
      );

      notifier.remove(conversationId: 'conv-1', draftId: draft.id);

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1'], isNull);
    });

    test('clear removes all drafts for a conversation', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final _ = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );
      final _ = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Second'),
      );
      final _ = notifier.enqueue(
        conversationId: 'conv-2',
        draft: const ChatDraft(text: 'Other conv'),
      );
      notifier.clear('conv-1');

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1'], isNull);
      expect(state['conv-2']?.length, 1);
    });

    test('clear with unknown conversationId is no-op', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final _ = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );
      notifier.clear('unknown');

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1']?.length, 1);
    });
  });
}
