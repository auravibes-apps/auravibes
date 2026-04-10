import 'package:auravibes_app/features/chats/notifiers/conversation_send_queue_notifier.dart';
import 'package:riverpod/riverpod.dart';

/// Runtime adapter that captures notifier method references behind plain
/// callback interfaces, so use cases stay decoupled from Riverpod notifier
/// classes.
///
/// Safety note: method references are captured once per provider rebuild.
/// This is safe because code-generated Riverpod notifiers are singleton-like.
/// If the notifier adds mutable local fields, captured references may go stale.
class ConversationSendQueueRuntime {
  const ConversationSendQueueRuntime({
    required this.enqueue,
    required this.dequeueAll,
  });

  final ConversationQueuedDraft Function({
    required String conversationId,
    required String content,
  })
  enqueue;
  final List<ConversationQueuedDraft> Function(String conversationId)
  dequeueAll;
}

final conversationSendQueueRuntimeProvider =
    Provider<ConversationSendQueueRuntime>((ref) {
      final notifier = ref.watch(conversationSendQueueProvider.notifier);
      return ConversationSendQueueRuntime(
        enqueue: notifier.enqueue,
        dequeueAll: notifier.dequeueAll,
      );
    });
