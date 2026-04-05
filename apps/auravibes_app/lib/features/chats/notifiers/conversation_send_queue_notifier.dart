import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_send_queue_notifier.g.dart';

class ConversationQueuedDraft {
  const ConversationQueuedDraft({
    required this.id,
    required this.content,
  });

  final String id;
  final String content;
}

@riverpod
class ConversationSendQueue extends _$ConversationSendQueue {
  int _nextDraftId = 0;

  @override
  Map<String, List<ConversationQueuedDraft>> build() {
    return {};
  }

  ConversationQueuedDraft enqueue({
    required String conversationId,
    required String content,
  }) {
    final draft = ConversationQueuedDraft(
      id: 'queued-${_nextDraftId++}',
      content: content,
    );

    state = {
      ...state,
      conversationId: [...state[conversationId] ?? const [], draft],
    };

    return draft;
  }

  ConversationQueuedDraft? peek(String conversationId) {
    final drafts = state[conversationId];
    if (drafts == null || drafts.isEmpty) {
      return null;
    }

    return drafts.first;
  }

  ConversationQueuedDraft? dequeue(String conversationId) {
    final drafts = state[conversationId];
    if (drafts == null || drafts.isEmpty) {
      return null;
    }

    final nextDraft = drafts.first;
    final remainingDrafts = drafts.sublist(1);

    state = {
      for (final entry in state.entries)
        if (entry.key != conversationId) entry.key: entry.value,
      if (remainingDrafts.isNotEmpty) conversationId: remainingDrafts,
    };

    return nextDraft;
  }

  List<ConversationQueuedDraft> dequeueAll(String conversationId) {
    final drafts = state[conversationId];
    if (drafts == null || drafts.isEmpty) {
      return const [];
    }

    state = {
      for (final entry in state.entries)
        if (entry.key != conversationId) entry.key: entry.value,
    };

    return drafts;
  }
}
