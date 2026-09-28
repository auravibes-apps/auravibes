import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_draft.g.dart';

@Riverpod(keepAlive: true)
class ConversationDraft extends _$ConversationDraft {
  @override
  ChatDraft? build(String workspaceId, String conversationId) => null;

  void save(ChatDraft draft) => state = draft.isEmpty ? null : draft;

  void clear() => state = null;

  void clearIfSame(ChatDraft? draft) {
    if (identical(state, draft)) clear();
  }
}
