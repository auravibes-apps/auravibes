import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/titles_streams_notifier.dart';
import 'package:dartantic_ai/dartantic_ai.dart' hide Provider;
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
