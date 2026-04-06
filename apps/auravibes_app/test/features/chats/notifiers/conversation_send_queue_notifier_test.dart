import 'package:auravibes_app/features/chats/notifiers/conversation_send_queue_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('ConversationSendQueueNotifier', () {
    late ProviderContainer container;

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
        content: 'First queued message',
      );
      final second = notifier.enqueue(
        conversationId: 'conversation-1',
        content: 'Second queued message',
      );

      expect(
        notifier.peek('conversation-1')?.content,
        'First queued message',
      );
      expect(notifier.dequeue('conversation-1')?.id, first.id);
      expect(notifier.dequeue('conversation-1')?.id, second.id);
      expect(notifier.dequeue('conversation-1'), isNull);
    });

    test('remove removes a specific draft by id', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final first = notifier.enqueue(
        conversationId: 'conv-1',
        content: 'First',
      );
      final second = notifier.enqueue(
        conversationId: 'conv-1',
        content: 'Second',
      );

      notifier.remove(conversationId: 'conv-1', draftId: first.id);

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1']?.length, 1);
      expect(state['conv-1']?.first.id, second.id);
    });

    test('remove with unknown draftId is no-op', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      notifier.enqueue(conversationId: 'conv-1', content: 'First');

      notifier.remove(conversationId: 'conv-1', draftId: 'nonexistent');

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1']?.length, 1);
    });

    test('remove with unknown conversationId is no-op', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final draft = notifier.enqueue(
        conversationId: 'conv-1',
        content: 'First',
      );

      notifier.remove(conversationId: 'unknown', draftId: draft.id);

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1']?.length, 1);
    });

    test('remove last draft clears conversation entry', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final draft = notifier.enqueue(
        conversationId: 'conv-1',
        content: 'Only one',
      );

      notifier.remove(conversationId: 'conv-1', draftId: draft.id);

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1'], isNull);
    });

    test('clearAll removes all drafts for a conversation', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      notifier.enqueue(conversationId: 'conv-1', content: 'First');
      notifier.enqueue(conversationId: 'conv-1', content: 'Second');
      notifier.enqueue(conversationId: 'conv-2', content: 'Other conv');

      notifier.clearAll('conv-1');

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1'], isNull);
      expect(state['conv-2']?.length, 1);
    });

    test('clearAll with unknown conversationId is no-op', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      notifier.enqueue(conversationId: 'conv-1', content: 'First');

      notifier.clearAll('unknown');

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1']?.length, 1);
    });
  });
}
