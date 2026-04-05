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
  });
}
