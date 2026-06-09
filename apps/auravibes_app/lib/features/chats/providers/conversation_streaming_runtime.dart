// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_state.dart';
import 'package:auravibes_app/features/chats/notifiers/titles_streams_notifier.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

class ConversationStreamingRuntime {
  const ConversationStreamingRuntime({
    required this.start,
    required this.isStreaming,
    required this.remove,
  });

  final void Function(String conversationId) start;
  final bool Function(String conversationId) isStreaming;
  final void Function(String conversationId) remove;
}

class MessagesStreamingRuntime {
  const MessagesStreamingRuntime({
    required this.startSubscription,
    required this.updateResult,
    required this.remove,
  });

  final void Function(CompositeSubscription subscription, String messageId)
  startSubscription;
  final void Function(ChatResult<ChatMessage> result, String messageId)
  updateResult;
  final Future<void> Function(String messageId) remove;
}

class TitlesStreamingRuntime {
  const TitlesStreamingRuntime({
    required this.updateTitle,
    required this.removeTitle,
  });

  final void Function(String conversationId, String title) updateTitle;
  final void Function(String conversationId) removeTitle;
}

class ConversationRateLimitRetryRuntime {
  const ConversationRateLimitRetryRuntime({
    required this.start,
    required this.retryAt,
    required this.clear,
  });

  final void Function(String conversationId, DateTime retryAt) start;
  final DateTime? Function(String conversationId) retryAt;
  final void Function(String conversationId) clear;
}

class ConversationRateLimitRetryNotifier
    extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() {
    return {};
  }

  void start(String conversationId, DateTime retryAt) {
    state = {
      ...state,
      conversationId: retryAt,
    };
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
