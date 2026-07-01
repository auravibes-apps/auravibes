// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:riverpod/riverpod.dart';

/// Runtime adapter that captures notifier method references behind plain.
/// callback interfaces, so use cases stay decoupled from Riverpod notifier
/// classes.
///
/// Safety note: method references are captured once per provider rebuild.
/// The adapter stays valid as long as the underlying notifier instance is not
/// disposed and recreated between uses. For keepAlive notifiers this is
/// guaranteed. For auto-dispose notifiers, the adapter's `ref.watch`
/// subscription keeps the notifier alive while the adapter is watched.
class ConversationSendQueueRuntime implements AgentSendQueueRuntime {
  factory ConversationSendQueueRuntime({
    required ConversationQueuedDraft Function({
      required String conversationId,
      required String content,
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

  const ConversationSendQueueRuntime._({
    required this.enqueue,
    required this._dequeueAll,
    required this._clear,
  });

  final ConversationQueuedDraft Function({
    required String conversationId,
    required String content,
  })
  enqueue;
  final List<ConversationQueuedDraft> Function(String conversationId)
  _dequeueAll;
  final void Function(String conversationId) _clear;

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
