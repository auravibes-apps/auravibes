import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_queued_draft.g.dart';

class ConversationQueuedDraft extends AgentQueuedDraft {
  ConversationQueuedDraft({
    required this.id,
    required ChatDraft draft,
  }) : super(content: _contentForDraft(draft), payload: draft);

  final String id;
}

String _contentForDraft(ChatDraft draft) {
  if (draft.text.isNotEmpty) return draft.text;

  return draft.attachments
      .map((attachment) => attachment.displayName)
      .join(', ');
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
    required ChatDraft draft,
  }) {
    final queuedDraft = ConversationQueuedDraft(
      id: 'queued-${_nextDraftId++}',
      draft: draft,
    );

    state = {
      ...state,
      conversationId: [...state[conversationId] ?? const [], queuedDraft],
    };

    return queuedDraft;
  }

  ConversationQueuedDraft? peek(String conversationId) {
    final drafts = state[conversationId];

    return drafts?.firstOrNull;
  }

  ConversationQueuedDraft? dequeue(String conversationId) {
    final drafts = state[conversationId];
    if (drafts == null || drafts.isEmpty) {
      return null;
    }
    final [nextDraft, ...remainingDrafts] = drafts;

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

    state = _withoutConversation(conversationId);

    return drafts;
  }

  void remove({required String conversationId, required String draftId}) {
    final drafts = state[conversationId];
    if (drafts == null) return;

    if (!drafts.any((d) => d.id == draftId)) return;

    final remainingDrafts = drafts.where((d) => d.id != draftId).toList();

    state = {
      ..._withoutConversation(conversationId),
      if (remainingDrafts.isNotEmpty) conversationId: remainingDrafts,
    };
  }

  void clear(String conversationId) {
    final drafts = state[conversationId];
    if (drafts == null || drafts.isEmpty) return;

    state = _withoutConversation(conversationId);
  }

  Map<String, List<ConversationQueuedDraft>> _withoutConversation(
    String conversationId,
  ) {
    return {
      for (final entry in state.entries)
        if (entry.key != conversationId) entry.key: entry.value,
    };
  }
}
