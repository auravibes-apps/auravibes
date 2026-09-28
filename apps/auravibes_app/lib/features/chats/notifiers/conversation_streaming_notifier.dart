import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/providers/conversation_activity_gate.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_streaming_notifier.g.dart';

@riverpod
class ConversationStreamingNotifier extends _$ConversationStreamingNotifier {
  @override
  Set<String> build() {
    return <String>{};
  }

  void start(String conversationId) {
    if (ref
        .read(conversationActivityGateProvider)
        .isCheckpointRestoreInProgress(conversationId)) {
      throw const CompactionCheckpointRestoreException();
    }
    state = {...state, conversationId};
  }

  bool isStreaming(String conversationId) {
    return state.contains(conversationId);
  }

  void remove(String conversationId) {
    state = {
      for (final activeConversationId in state)
        if (activeConversationId != conversationId) activeConversationId,
    };
  }
}
