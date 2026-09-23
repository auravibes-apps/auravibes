import 'dart:async';

import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/usecases/local_chat_attachment_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_queued_draft.g.dart';

class ConversationQueuedDraft({
  required final String id,
  required final ChatDraft draft,
}) extends AgentQueuedDraft {
  this : super(content: _contentForDraft(draft), payload: draft);
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
  Map<String, List<ConversationQueuedDraft>> _queuedDrafts = const {};

  @override
  Map<String, List<ConversationQueuedDraft>> build() {
    final attachmentUsecase = ref.watch(localChatAttachmentUsecaseProvider);
    final _ = ref.onDispose(() {
      for (final drafts in _queuedDrafts.values) {
        _deleteAttachments(drafts, attachmentUsecase);
      }
    });

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

    _setState({
      ...state,
      conversationId: [...state[conversationId] ?? const [], queuedDraft],
    });

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

    _setState({
      for (final entry in state.entries)
        if (entry.key != conversationId) entry.key: entry.value,
      if (remainingDrafts.isNotEmpty) conversationId: remainingDrafts,
    });

    return nextDraft;
  }

  List<ConversationQueuedDraft> dequeueAll(String conversationId) {
    final drafts = state[conversationId];
    if (drafts == null || drafts.isEmpty) {
      return const [];
    }

    _setState(_withoutConversation(state, conversationId));

    return drafts;
  }

  void remove({required String conversationId, required String draftId}) {
    final drafts = state[conversationId];
    if (drafts == null) return;

    final remainingDrafts = _withoutDraft(drafts, draftId);
    if (remainingDrafts.length == drafts.length) return;

    _setState(_withRemainingDrafts(conversationId, remainingDrafts));
    _deleteAttachments(
      drafts.where((draft) => draft.id == draftId),
      ref.read(localChatAttachmentUsecaseProvider),
    );
  }

  ConversationQueuedDraft? take({
    required String conversationId,
    required String draftId,
  }) {
    final drafts = state[conversationId];
    if (drafts == null) return null;

    final draft = drafts.where((draft) => draft.id == draftId).firstOrNull;
    if (draft == null) return null;

    _setState(
      _withRemainingDrafts(conversationId, _withoutDraft(drafts, draftId)),
    );

    return draft;
  }

  void clear(String conversationId) {
    final drafts = state[conversationId];
    if (drafts == null || drafts.isEmpty) return;

    _setState(_withoutConversation(state, conversationId));
    _deleteAttachments(drafts, ref.read(localChatAttachmentUsecaseProvider));
  }

  Map<String, List<ConversationQueuedDraft>> _withRemainingDrafts(
    String conversationId,
    List<ConversationQueuedDraft> remainingDrafts,
  ) => {
    ..._withoutConversation(state, conversationId),
    if (remainingDrafts.isNotEmpty) conversationId: remainingDrafts,
  };

  void _setState(Map<String, List<ConversationQueuedDraft>> nextState) {
    _queuedDrafts = nextState;
    state = nextState;
  }
}

List<ConversationQueuedDraft> _withoutDraft(
  List<ConversationQueuedDraft> drafts,
  String draftId,
) => drafts.where((draft) => draft.id != draftId).toList();

Map<String, List<ConversationQueuedDraft>> _withoutConversation(
  Map<String, List<ConversationQueuedDraft>> state,
  String conversationId,
) => {
  for (final entry in state.entries)
    if (entry.key != conversationId) entry.key: entry.value,
};

void _deleteAttachments(
  Iterable<ConversationQueuedDraft> drafts,
  LocalChatAttachmentUsecase attachmentUsecase,
) {
  for (final draft in drafts) {
    for (final attachment in draft.draft.attachments) {
      unawaited(attachmentUsecase.deleteAttachment(attachment.localPath));
    }
  }
}
