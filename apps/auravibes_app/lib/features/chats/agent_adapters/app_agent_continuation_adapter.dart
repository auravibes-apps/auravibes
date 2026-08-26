// ignore_for_file: dead_code

import 'package:auravibes_app/data/repositories/api_model_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/select_prompt_messages_usecase.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/services/agent_harness/build_skill_context_messages_service.dart';
import 'package:auravibes_app/services/chatbot_service/build_prompt_chat_messages.dart';
import 'package:auravibes_app/services/codex_input_modalities.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    hide BuildPromptChatMessages;
import 'package:riverpod/riverpod.dart';

class AppAgentContinuationAdapter
    implements
        AgentContinuationProvider<
          WorkspaceModelSelectionWithConnectionEntity,
          MessageEntity,
          ChatMessage,
          ToolSpec
        > {
  AppAgentContinuationAdapter({
    required this.conversationRepository,
    required this.modelSelectionStore,
    required this.apiModelRepository,
    required this.selectPromptMessagesUsecase,
    required this.buildSkillContextMessagesUsecase,
    required this.loadConversationToolSpecsUsecase,
    this.loadConversationToolSpecsUsecaseForWorkspace,
  });

  final ConversationRepository conversationRepository;
  final Future<ModelSelectionStore> Function(String workspaceId)
  modelSelectionStore;
  final ApiModelRepository apiModelRepository;
  final SelectPromptMessagesUsecase selectPromptMessagesUsecase;
  final BuildSkillContextMessagesService buildSkillContextMessagesUsecase;
  final LoadConversationToolSpecsUsecase loadConversationToolSpecsUsecase;
  final LoadConversationToolSpecsUsecase Function(String workspaceId)?
  loadConversationToolSpecsUsecaseForWorkspace;
  final Map<String, String> _workspaceIdsByModelId = {};

  @override
  Future<AgentConversationReference?> loadConversation(
    String conversationId,
  ) async {
    final conversation = await conversationRepository.getConversationById(
      conversationId,
    );
    if (conversation == null) return null;

    if (conversation.modelId case final modelId?) {
      _workspaceIdsByModelId[modelId] = conversation.workspaceId;
    }

    return AgentConversationReference(
      workspaceId: conversation.workspaceId,
      modelId: conversation.modelId,
    );
  }

  @override
  Future<WorkspaceModelSelectionWithConnectionEntity?> loadSelectedModel(
    String modelId,
  ) async {
    final workspaceId = _workspaceIdsByModelId[modelId];
    if (workspaceId == null) return null;

    return await (await modelSelectionStore(workspaceId)).getById(modelId);
  }

  @override
  Future<WorkspaceModelSelectionWithConnectionEntity> projectSelectedModel(
    WorkspaceModelSelectionWithConnectionEntity model,
  ) async {
    if (!ModelProviderOAuthProfiles.isCodexProvider(
      model.modelConnection.modelId,
    )) {
      return model;
    }
    final openAIModel = await apiModelRepository.getModelByProviderAndModelId(
      'openai',
      model.workspaceModelSelection.modelId,
    );
    if (openAIModel == null) {
      throw Exception('OpenAI model catalog is unavailable');
    }
    if (!openAIModel.isCodexRuntimeModel) {
      throw Exception('Selected Codex model is not supported');
    }

    return model.copyWith(
      workspaceModelSelection: model.workspaceModelSelection.copyWith(
        modelName: openAIModel.name,
        supportsReasoning: openAIModel.supportsReasoning,
        supportsToolCalls: openAIModel.supportsToolCalls,
        modalitiesInput: CodexInputModalities.forModel(openAIModel),
        modalitiesOutput: openAIModel.modalitiesOutput,
      ),
    );
  }

  @override
  Future<List<MessageEntity>> selectPromptMessages(String conversationId) {
    return selectPromptMessagesUsecase.call(conversationId);
  }

  @override
  Future<List<ChatMessage>> buildSkillContextMessages({
    required String conversationId,
    required String workspaceId,
  }) {
    return buildSkillContextMessagesUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
  }

  @override
  Future<List<ToolSpec>> loadTools({
    required String conversationId,
    required String workspaceId,
  }) {
    return (loadConversationToolSpecsUsecaseForWorkspace?.call(workspaceId) ??
            loadConversationToolSpecsUsecase)
        .call(conversationId: conversationId, workspaceId: workspaceId);
  }

  @override
  Future<List<ChatMessage>> buildChatHistory({
    required WorkspaceModelSelectionWithConnectionEntity model,
    required List<MessageEntity> messages,
    required List<ChatMessage> skillContextMessages,
  }) async {
    return [
      ...skillContextMessages,
      ...await BuildPromptChatMessages(
        modalitiesInput: model.workspaceModelSelection.modalitiesInput,
      )(messages),
    ];
  }

  @override
  bool shouldDisableTools(WorkspaceModelSelectionWithConnectionEntity model) {
    return ModelProviderOAuthProfiles.isCodexProvider(
          model.modelConnection.modelId,
        ) &&
        !model.workspaceModelSelection.supportsToolCalls;
  }

  @override
  bool isSystemMessage(ChatMessage message) {
    return message.role == ChatMessageRole.system;
  }

  @override
  bool isSkillContextMessage(ChatMessage message) => message.isSkillContext;

  @override
  bool isUserMessage(ChatMessage message) {
    return message.role == ChatMessageRole.user;
  }
}

final appAgentContinuationProvider = Provider<AppAgentContinuationAdapter>((
  ref,
) {
  return AppAgentContinuationAdapter(
    conversationRepository: ref.watch(conversationRepositoryProvider),
    modelSelectionStore: (workspaceId) =>
        ref.read(modelSelectionStoreProvider(workspaceId).future),
    apiModelRepository: ref.watch(apiModelRepositoryProvider),
    selectPromptMessagesUsecase: ref.watch(selectPromptMessagesUsecaseProvider),
    buildSkillContextMessagesUsecase: ref.watch(
      buildSkillContextMessagesServiceProvider,
    ),
    loadConversationToolSpecsUsecase: throw UnimplementedError(),
    loadConversationToolSpecsUsecaseForWorkspace: (workspaceId) =>
        ref.read(loadConversationToolSpecsUsecaseProvider(workspaceId)),
  );
});

extension on ChatMessage {
  bool get isSkillContext => metadata['kind'] == skillContextMetadataKind;
}
