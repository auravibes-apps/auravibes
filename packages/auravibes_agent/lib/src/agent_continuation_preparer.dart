class AgentConversationReference {
  const AgentConversationReference({
    required this.workspaceId,
    required this.modelId,
  });

  final String workspaceId;
  final String? modelId;
}

class PreparedContinueAgentInput<TModel, TChatMessage, TTool> {
  const PreparedContinueAgentInput({
    required this.model,
    required this.chatHistory,
    required this.enabledTools,
    required this.messagesCount,
  });

  final TModel model;
  final List<TChatMessage> chatHistory;
  final List<TTool> enabledTools;
  final int messagesCount;
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

  List<TChatMessage> buildChatHistory({
    required List<TMessage> messages,
    required List<TChatMessage> skillContextMessages,
  });

  bool shouldDisableTools(TModel model);

  bool isSystemMessage(TChatMessage message);

  bool isSkillContextMessage(TChatMessage message);

  bool isUserMessage(TChatMessage message);
}

class AgentContinuationPreparer<TModel, TMessage, TChatMessage, TTool> {
  const AgentContinuationPreparer({required this.provider});

  final AgentContinuationProvider<TModel, TMessage, TChatMessage, TTool>
  provider;

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
      throw Exception('Selected model not found');
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
    final chatHistory = provider.buildChatHistory(
      messages: messages,
      skillContextMessages: skillContextMessages,
    );
    assert(
      _startsWithUserMessage(chatHistory),
      'First non-system message after compaction must be user.',
    );

    return PreparedContinueAgentInput(
      model: projectedModel,
      chatHistory: chatHistory,
      enabledTools: provider.shouldDisableTools(projectedModel)
          ? const []
          : tools,
      messagesCount: messages.length,
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
