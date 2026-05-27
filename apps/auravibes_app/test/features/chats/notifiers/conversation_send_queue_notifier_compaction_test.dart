// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

// ignore_for_file: cascade_invocations
// Required: Test readability
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('ConversationSendQueue compaction-as-busy ordering', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'enqueued messages maintain FIFO order after compaction completes',
      () {
        final notifier = container.read(conversationSendQueueProvider.notifier);

        final first = notifier.enqueue(
          conversationId: 'conv-1',
          content: 'First queued',
        );
        final second = notifier.enqueue(
          conversationId: 'conv-1',
          content: 'Second queued',
        );
        final third = notifier.enqueue(
          conversationId: 'conv-1',
          content: 'Third queued',
        );

        expect(notifier.dequeue('conv-1')?.id, first.id);
        expect(notifier.dequeue('conv-1')?.id, second.id);
        expect(notifier.dequeue('conv-1')?.id, third.id);
        expect(notifier.dequeue('conv-1'), isNull);
      },
    );

    test('messages queued for different conversations are independent', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final conv1First = notifier.enqueue(
        conversationId: 'conv-1',
        content: 'Conv1 First',
      );
      final conv2First = notifier.enqueue(
        conversationId: 'conv-2',
        content: 'Conv2 First',
      );
      final _ = notifier.enqueue(
        conversationId: 'conv-1',
        content: 'Conv1 Second',
      );

      expect(notifier.dequeue('conv-1')?.id, conv1First.id);
      expect(notifier.dequeue('conv-2')?.id, conv2First.id);
    });

    test(
      'compaction conversation queue is separate from other conversations',
      () {
        final notifier = container.read(conversationSendQueueProvider.notifier);

        final compactingConvMsg = notifier.enqueue(
          conversationId: 'compacting-conv',
          content: 'Sent during compaction',
        );
        final otherConvMsg = notifier.enqueue(
          conversationId: 'other-conv',
          content: 'Sent to other',
        );

        expect(notifier.peek('compacting-conv')?.id, compactingConvMsg.id);
        expect(notifier.peek('other-conv')?.id, otherConvMsg.id);

        final _ = notifier.dequeue('compacting-conv');
        expect(notifier.peek('compacting-conv'), isNull);
        expect(notifier.peek('other-conv')?.id, otherConvMsg.id);
      },
    );

    test(
      'dequeueAll returns all queued messages in order for compaction drain',
      () {
        final notifier = container.read(conversationSendQueueProvider.notifier);

        final first = notifier.enqueue(
          conversationId: 'conv-1',
          content: 'First',
        );
        final second = notifier.enqueue(
          conversationId: 'conv-1',
          content: 'Second',
        );
        final third = notifier.enqueue(
          conversationId: 'conv-1',
          content: 'Third',
        );

        final all = notifier.dequeueAll('conv-1');

        expect(all.map((d) => d.id), [first.id, second.id, third.id]);
        expect(notifier.peek('conv-1'), isNull);
      },
    );

    test('queue state is empty after draining all conversations', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      notifier
        ..enqueue(conversationId: 'conv-1', content: 'A')
        ..enqueue(conversationId: 'conv-2', content: 'B')
        ..dequeueAll('conv-1')
        ..dequeueAll('conv-2');

      final state = container.read(conversationSendQueueProvider);
      expect(state, isEmpty);
    });
  });
}
