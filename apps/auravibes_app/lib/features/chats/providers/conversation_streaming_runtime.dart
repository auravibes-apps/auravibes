// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_state.dart';
import 'package:auravibes_app/features/chats/notifiers/titles_streams_notifier.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

class const ConversationStreamingRuntime({
  required final void Function(String conversationId) start,
  required final bool Function(String conversationId) isStreaming,
  required final void Function(String conversationId) remove,
});

class const MessagesStreamingRuntime({
  required final void Function(
    CompositeSubscription subscription,
    String messageId,
  )
  startSubscription,
  required final void Function(ChatResult<ChatMessage> result, String messageId)
  updateResult,
  required final Future<void> Function(String messageId) remove,
});

class const TitlesStreamingRuntime({
  required final void Function(String conversationId, String title) updateTitle,
  required final void Function(String conversationId) removeTitle,
});

class const ConversationRateLimitRetryRuntime({
  required final void Function(String conversationId, DateTime retryAt) start,
  required final DateTime? Function(String conversationId) retryAt,
  required final void Function(String conversationId) clear,
});

class ConversationRateLimitRetryNotifier
    extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() {
    return {};
  }

  void start(String conversationId, DateTime retryAt) {
    state = {...state, conversationId: retryAt};
  }

  DateTime? retryAt(String conversationId) {
    return state[conversationId];
  }

  void clear(String conversationId) {
    if (!state.containsKey(conversationId)) return;

    state = {
      for (final entry in state.entries)
        if (entry.key != conversationId) entry.key: entry.value,
    };
  }
}

final conversationStreamingRuntimeProvider =
    Provider<ConversationStreamingRuntime>((ref) {
      final notifier = ref.watch(conversationStreamingProvider.notifier);

      return ConversationStreamingRuntime(
        start: notifier.start,
        isStreaming: notifier.isStreaming,
        remove: notifier.remove,
      );
    });

final messagesStreamingRuntimeProvider = Provider<MessagesStreamingRuntime>((
  ref,
) {
  final notifier = ref.watch(messagesStreamingProvider.notifier);

  return MessagesStreamingRuntime(
    startSubscription: notifier.startSubscription,
    updateResult: notifier.updateResult,
    remove: notifier.remove,
  );
});

final titlesStreamingRuntimeProvider = Provider<TitlesStreamingRuntime>((ref) {
  final notifier = ref.watch(titlesStreamsProvider.notifier);

  return TitlesStreamingRuntime(
    updateTitle: notifier.updateTitle,
    removeTitle: notifier.removeTitle,
  );
});

final conversationRateLimitRetryProvider =
    NotifierProvider<ConversationRateLimitRetryNotifier, Map<String, DateTime>>(
      ConversationRateLimitRetryNotifier.new,
    );

final conversationRateLimitRetryRuntimeProvider =
    Provider<ConversationRateLimitRetryRuntime>((ref) {
      final notifier = ref.watch(conversationRateLimitRetryProvider.notifier);

      return ConversationRateLimitRetryRuntime(
        start: notifier.start,
        retryAt: notifier.retryAt,
        clear: notifier.clear,
      );
    });
