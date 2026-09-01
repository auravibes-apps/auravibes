// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

/// Runtime adapter that captures notifier method references behind plain
/// callback interfaces, so use cases stay decoupled from Riverpod notifier
/// classes.
///
/// Safety note. Method references are captured once per provider rebuild.
/// The adapter stays valid as long as the underlying notifier instance is not
/// disposed and recreated between uses. For keep-alive notifiers this is
/// guaranteed. For auto-dispose notifiers, the adapter's `ref.watch`
/// subscription keeps the notifier alive while the adapter is watched.
class const ConversationSendQueueRuntime._({
  required final ConversationQueuedDraft Function({
    required String conversationId,
    required ChatDraft draft,
  })
  enqueue,
  required final List<ConversationQueuedDraft> Function(String conversationId)
  _dequeueAll,
  required final void Function(String conversationId) _clear,
}) implements AgentSendQueueRuntime {
  factory({
    required ConversationQueuedDraft Function({
      required String conversationId,
      required ChatDraft draft,
    })
    enqueue,
    required List<ConversationQueuedDraft> Function(String conversationId)
    dequeueAll,
    required void Function(String conversationId) clear,
  }) {
    return ConversationSendQueueRuntime._(
      enqueue: enqueue,
      dequeueAll: dequeueAll,
      clear: clear,
    );
  }

  @override
  List<AgentQueuedDraft> dequeueAll(String conversationId) {
    return List<AgentQueuedDraft>.of(_dequeueAll(conversationId));
  }

  @override
  void clear(String conversationId) {
    _clear(conversationId);
  }
}

final conversationSendQueueRuntimeProvider =
    Provider<ConversationSendQueueRuntime>((ref) {
      final notifier = ref.watch(conversationSendQueueProvider.notifier);

      return ConversationSendQueueRuntime(
        enqueue: notifier.enqueue,
        dequeueAll: notifier.dequeueAll,
        clear: notifier.clear,
      );
    });
