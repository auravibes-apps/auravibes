import 'package:auravibes_engine/src/agent_transcript_context.dart';
import 'package:auravibes_engine/src/reasoning_configuration.dart';

class const AgentConversationReference({
  required final String workspaceId,
  required final String? modelId,
  final ReasoningConfiguration? reasoningConfiguration,
});

class const PreparedContinueAgentInput<TModel, TChatMessage, TTool>({
  required final TModel model,
  required final List<TChatMessage> chatHistory,
  required final List<TChatMessage> requestedContextMessages,
  required final List<TTool> enabledTools,
  required final int messagesCount,
  required final List<AgentTranscriptContextEntry> transcriptContextEntries,
  final ReasoningConfiguration? reasoningConfiguration,
});

class const PreparedAgentTranscriptContext<TChatMessage, TTool>({
  required final List<TChatMessage> contextMessages,
  required final List<TTool> tools,
  required final List<AgentTranscriptContextEntry> entries,
});

class const SelectedModelNotFoundException() implements Exception {
  @override
  String toString() => 'Selected model not found';
}

abstract interface class AgentContinuationProvider<
  TModel,
  TMessage,
  TChatMessage,
  TTool
> {
  Future<AgentConversationReference?> loadConversation(String conversationId);

  Future<TModel?> loadSelectedModel(String modelId);

  Future<TModel> projectSelectedModel(TModel model);

  Future<List<TMessage>> selectPromptMessages(String conversationId);

  Future<List<TChatMessage>> buildSkillContextMessages({
    required String conversationId,
    required String workspaceId,
  });

  Future<List<TTool>> loadTools({
    required String conversationId,
    required String workspaceId,
  });

  Future<PreparedAgentTranscriptContext<TChatMessage, TTool>>
  reconcileTranscriptContext({
    required String conversationId,
    required String workspaceId,
    required List<TChatMessage> contextMessages,
    required List<TTool> tools,
  });

  Future<List<TChatMessage>> buildChatHistory({
    required TModel model,
    required List<TMessage> messages,
    required List<TChatMessage> skillContextMessages,
  });

  bool shouldDisableTools(TModel model);

  bool isSystemMessage(TChatMessage message);

  bool isSkillContextMessage(TChatMessage message);

  bool isUserMessage(TChatMessage message);
}

class const AgentContinuationPreparer<TModel, TMessage, TChatMessage, TTool>({
  required final AgentContinuationProvider<
    TModel,
    TMessage,
    TChatMessage,
    TTool
  >
  provider,
}) {
  Future<PreparedContinueAgentInput<TModel, TChatMessage, TTool>> call({
    required String conversationId,
  }) async {
    final conversation = await provider.loadConversation(conversationId);
    if (conversation == null) {
      throw Exception('Conversation not found');
    }
    final modelId = conversation.modelId;
    if (modelId == null) {
      throw Exception('Conversation has no model id');
    }

    final foundModel = await provider.loadSelectedModel(modelId);
    if (foundModel == null) {
      throw const SelectedModelNotFoundException();
    }
    final projectedModel = await provider.projectSelectedModel(foundModel);
    final messages = await provider.selectPromptMessages(conversationId);
    final skillContextMessages = await provider.buildSkillContextMessages(
      conversationId: conversationId,
      workspaceId: conversation.workspaceId,
    );
    final tools = await provider.loadTools(
      conversationId: conversationId,
      workspaceId: conversation.workspaceId,
    );
    final transcriptContext = await provider.reconcileTranscriptContext(
      conversationId: conversationId,
      workspaceId: conversation.workspaceId,
      contextMessages: skillContextMessages,
      tools: provider.shouldDisableTools(projectedModel) ? const [] : tools,
    );
    final chatHistory = await provider.buildChatHistory(
      model: projectedModel,
      messages: messages,
      skillContextMessages: transcriptContext.contextMessages,
    );
    assert(
      _startsWithUserMessage(chatHistory),
      'First non-system message after compaction must be user.',
    );

    return PreparedContinueAgentInput(
      model: projectedModel,
      chatHistory: chatHistory,
      requestedContextMessages: skillContextMessages,
      enabledTools: transcriptContext.tools,
      messagesCount: messages.length,
      transcriptContextEntries: transcriptContext.entries,
      reasoningConfiguration: conversation.reasoningConfiguration,
    );
  }

  bool _startsWithUserMessage(List<TChatMessage> chatHistory) {
    for (final message in chatHistory) {
      if (provider.isSystemMessage(message) ||
          provider.isSkillContextMessage(message)) {
        continue;
      }

      return provider.isUserMessage(message);
    }

    return true;
  }
}
