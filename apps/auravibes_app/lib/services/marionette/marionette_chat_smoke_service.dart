import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chatbot_service.dart';
import 'package:auravibes_app/services/marionette/marionette_chat_smoke_fixture.dart';
import 'package:auravibes_app/services/marionette/marionette_demo_model_identity.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class MarionetteChatSmokeService({
  required super.serviceConnectionRepository,
  required final MarionetteChatSmokeFixture fixture,
  super.oauthCredentialService,
}) extends ChatbotService {
  @override
  Stream<ChatResult<ChatMessage>> sendMessage(
    WorkspaceModelSelectionWithConnectionEntity chatProvider,
    List<ChatMessage> history, {
    ChatbotMessageOptions options = const ChatbotMessageOptions(),
    ChatA2uiRuntime? a2uiRuntime,
  }) {
    if (_matchesDemoModel(chatProvider)) return fixture.sendMessage();

    return super.sendMessage(
      chatProvider,
      history,
      options: options,
      a2uiRuntime: a2uiRuntime,
    );
  }

  @override
  Stream<String> streamTitle(
    WorkspaceModelSelectionWithConnectionEntity chatProvider,
    String firstMessage,
  ) {
    if (_matchesDemoModel(chatProvider)) {
      return Stream.value(ChatbotService.generateFallbackTitle(firstMessage));
    }

    return super.streamTitle(chatProvider, firstMessage);
  }

  bool _matchesDemoModel(WorkspaceModelSelectionWithConnectionEntity model) =>
      MarionetteDemoModelIdentity.matchesDemoModelSelection(
        model.modelConnection.workspaceId,
        model.workspaceModelSelection.id,
        model,
      );
}
