import 'package:auravibes_app/features/chats/notifiers/conversation_send_queue_notifier.dart';
import 'package:riverpod/riverpod.dart';

/// Runtime adapter that captures notifier method references behind plain
/// callback interfaces, so use cases stay decoupled from Riverpod notifier
/// classes.
///
/// Safety note: method references are captured once per provider rebuild.
/// The adapter stays valid as long as the underlying notifier instance is not
/// disposed and recreated between uses. For keepAlive notifiers this is
/// guaranteed. For auto-dispose notifiers, the adapter's `ref.watch`
/// subscription keeps the notifier alive while the adapter is watched.
class ConversationSendQueueRuntime {
  const ConversationSendQueueRuntime({
    required this.enqueue,
    required this.dequeueAll,
    required this.clear,
  });

  final ConversationQueuedDraft Function({
    required String conversationId,
    required String content,
  })
  enqueue;
  final List<ConversationQueuedDraft> Function(String conversationId)
  dequeueAll;
  final void Function(String conversationId) clear;
}

final conversationSendQueueRuntimeProvider =
    Provider<ConversationSendQueueRuntime>((ref) {
      final notifier = ref.watch(conversationSendQueueProvider.notifier);
      return ConversationSendQueueRuntime(
        enqueue: notifier.enqueue,
        dequeueAll: notifier.dequeueAll,
        clear: notifier.clearAll,
      );
    });
