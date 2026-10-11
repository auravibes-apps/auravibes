import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_draft.g.dart';

@Riverpod(keepAlive: true)
class ConversationDraft extends _$ConversationDraft {
  @override
  ChatDraft? build(String workspaceId, String conversationId) {
    final registry = ref.watch(conversationDraftRegistryProvider);
    final _ = ref.onDispose(
      () => registry.unregister(workspaceId, conversationId, this),
    );
    registry.register(workspaceId, conversationId, this);

    return null;
  }

  void save(ChatDraft draft) => state = draft.isEmpty ? null : draft;

  void clear() => state = null;

  ChatDraft? take() {
    final draft = state;
    clear();

    return draft;
  }

  void clearIfSame(ChatDraft? draft) {
    if (identical(state, draft)) clear();
  }
}

typedef _ConversationDraftKey = ({String workspaceId, String conversationId});

class ConversationDraftRegistry {
  final Map<_ConversationDraftKey, ConversationDraft> _drafts = {};

  void register(
    String workspaceId,
    String conversationId,
    ConversationDraft draft,
  ) {
    _drafts[(workspaceId: workspaceId, conversationId: conversationId)] = draft;
  }

  void unregister(
    String workspaceId,
    String conversationId,
    ConversationDraft draft,
  ) {
    final key = (workspaceId: workspaceId, conversationId: conversationId);
    if (identical(_drafts[key], draft)) {
      final _ = _drafts.remove(key);
    }
  }

  ChatDraft? clearConversation(String workspaceId, String conversationId) =>
      _drafts[(workspaceId: workspaceId, conversationId: conversationId)]
          ?.take();

  List<ChatDraft> clearWorkspace(String workspaceId) => [
    for (final entry in _drafts.entries)
      if (entry.key.workspaceId == workspaceId)
        if (entry.value.take() case final ChatDraft draft) draft,
  ];
}

final conversationDraftRegistryProvider = Provider<ConversationDraftRegistry>(
  (ref) => ConversationDraftRegistry(),
);
