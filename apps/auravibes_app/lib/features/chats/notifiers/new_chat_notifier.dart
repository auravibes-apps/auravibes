import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/features/chats/usecases/send_new_message_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/selected_workspace.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_chat_notifier.freezed.dart';
part 'new_chat_notifier.g.dart';

@freezed
abstract class NewChatState with _$NewChatState {
  const factory NewChatState({
    String? modelId,

    /// Stores the provider ID (or name-equivalent)
    /// - for display and filtering models
    String? providerId,
    @Default(false) bool isLoading,
  }) = _NewChatState;
}

@riverpod
class NewChatNotifier extends _$NewChatNotifier {
  @override
  NewChatState build() {
    return const NewChatState();
  }

  void setModelId(String? modelId) {
    state = state.copyWith(modelId: modelId);
  }

  void setProvider(String? providerId) {
    state = state.copyWith(
      providerId: providerId,
      modelId: null, // Reset model when provider changes
    );
  }

  Future<ConversationEntity> startConversation(String message) async {
    final modelId = state.modelId;
    if (modelId == null) {
      throw Exception('Please select a chat model');
    }

    state = state.copyWith(isLoading: true);
    try {
      final workspaceId = await ref.read(
        selectedWorkspaceProvider.selectAsync((workspace) => workspace.id),
      );
      // TODO: manage future
      return ref
          .read(sendNewMessageUsecaseProvider)
          .call(
            firstMessage: message,
            credentialsModelId: modelId,
            workspaceId: workspaceId,
          );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
