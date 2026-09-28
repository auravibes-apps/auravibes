// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/usecases/send_new_message_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_chat_state.freezed.dart';
part 'new_chat_state.g.dart';

@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class NewChatState with _$NewChatState {
  const factory({
    String? modelId,

    /// Stores the provider ID (or name equivalent) for displaying and
    /// filtering models.
    String? providerId,
    String? agentId,
    ReasoningConfiguration? reasoningConfiguration,
    @Default(false) bool isLoading,
  }) = _NewChatState;
}

@riverpod
class NewChatNotifier extends _$NewChatNotifier {
  @override
  NewChatState build(String workspaceId) {
    return const NewChatState();
  }

  void setModelId(String? modelId) {
    state = state.copyWith(modelId: modelId);
  }

  void setProvider(String? providerId) {
    state = state.copyWith(
      providerId: providerId,
      modelId: null, // Reset model when provider changes.
    );
  }

  void setAgentId(String? agentId) {
    state = state.copyWith(agentId: agentId);
  }

  void setReasoningConfiguration(ReasoningConfiguration? value) {
    state = state.copyWith(reasoningConfiguration: value);
  }

  Future<ConversationEntity> startConversation(
    ChatDraft draft,
    SendNewMessageUsecase sendNewMessageUsecase,
  ) async {
    final modelId = state.modelId;
    if (modelId == null) {
      throw Exception('Please select a chat model');
    }

    state = state.copyWith(isLoading: true);
    try {
      return await sendNewMessageUsecase.call((
        draft: draft,
        workspaceModelSelectionId: modelId,
        workspaceId: workspaceId,
        agentId: state.agentId,
        reasoningConfiguration: state.reasoningConfiguration,
      ));
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
