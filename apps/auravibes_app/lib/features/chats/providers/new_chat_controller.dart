import 'package:auravibes_app/domain/usecases/chats/start_new_chat_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/conversation/resolve_conversation_tool_states_usecase.dart'
    as tools_usecases;
import 'package:auravibes_app/features/tools/providers/conversation_tools_controller.dart';
import 'package:auravibes_app/features/workspaces/providers/selected_workspace.dart';
import 'package:auravibes_app/providers/messages_controller.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_chat_controller.freezed.dart';
part 'new_chat_controller.g.dart';

@freezed
abstract class NewChatState with _$NewChatState {
  const factory NewChatState({
    String? modelId,
    @Default(false) bool isLoading,
  }) = _NewChatState;
}

@riverpod
class NewChatController extends _$NewChatController {
  @override
  NewChatState build() {
    return const NewChatState();
  }

  void setModelId(String? modelId) {
    state = state.copyWith(modelId: modelId);
  }

  Future<String> startConversation(String message) async {
    final modelId = state.modelId;
    if (modelId == null) {
      throw Exception('Please select a chat model');
    }

    state = state.copyWith(isLoading: true);
    try {
      final workspaceId = await ref.read(
        selectedWorkspaceProvider.selectAsync((workspace) => workspace.id),
      );
      return StartNewChatUseCase(
        getConversationTools: (currentWorkspaceId) async {
          final toolStates = await ref.read(
            conversationToolsControllerProvider(
              workspaceId: currentWorkspaceId,
            ).future,
          );

          return toolStates
              .map(
                (toolState) => tools_usecases.ResolvedConversationToolState(
                  tool: toolState.tool,
                  isEnabled: toolState.isEnabled,
                  permissionMode: toolState.permissionMode,
                  isWorkspaceEnabled: toolState.isWorkspaceEnabled,
                ),
              )
              .toList();
        },
        addConversation: ref
            .read(messagesControllerProvider.notifier)
            .addConversation,
      ).call(
        workspaceId: workspaceId,
        modelId: modelId,
        message: message,
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
