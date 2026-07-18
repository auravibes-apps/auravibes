// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/api_model_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/select_compaction_range_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/should_compact_conversation_usecase.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/providers/chatbot_service_provider.dart';
import 'package:riverpod/riverpod.dart';

const _kDefaultMaxOutputTokens = 4096;

class MaybeAutoCompactConversationUsecase {
  const MaybeAutoCompactConversationUsecase({
    required this.compactConversationUsecase,
    this.conversationRepository,
    this.modelSelectionStore,
    this.apiModelRepository,
    this.shouldCompactConversationUsecase,
    this.cloudShouldCompact,
  });

  final ConversationRepository? conversationRepository;
  final Future<ModelSelectionStore> Function(String workspaceId)?
  modelSelectionStore;
  final ApiModelRepository? apiModelRepository;
  final ShouldCompactConversationUsecase? shouldCompactConversationUsecase;
  final CompactConversationUsecase compactConversationUsecase;
  final Future<bool> Function(String conversationId)? cloudShouldCompact;

  Future<void> call({required String conversationId}) async {
    final cloudDecision = cloudShouldCompact;
    if (cloudDecision != null) {
      if (!await cloudDecision(conversationId)) return;
      switch (await compactConversationUsecase(
        conversationId: conversationId,
        trigger: CompactionTrigger.auto,
      )) {
        case _:
          return;
      }
    }
    final repository = conversationRepository;
    final getModelStore = modelSelectionStore;
    final models = apiModelRepository;
    final shouldCompact = shouldCompactConversationUsecase;
    if (repository == null ||
        getModelStore == null ||
        models == null ||
        shouldCompact == null) {
      throw StateError('Local compaction dependencies unavailable');
    }
    final conversation = await repository.getConversationById(
      conversationId,
    );
    if (conversation == null) return;

    final modelId = conversation.modelId;
    if (modelId == null) return;

    final foundModel = await (await getModelStore(
      conversation.workspaceId,
    )).getById(modelId);
    if (foundModel == null) return;

    final apiModel = await models.getModelByProviderAndModelId(
      foundModel.modelsProvider.id,
      foundModel.workspaceModelSelection.modelId,
    );

    final decision = await shouldCompact(
      conversationId: conversationId,
      workspaceId: conversation.workspaceId,
      selectedModelId: foundModel.workspaceModelSelection.modelId,
      selectedProviderId: foundModel.modelsProvider.id,
      maxOutputTokens: apiModel?.limitOutput ?? _kDefaultMaxOutputTokens,
      contextLimit: apiModel?.limitContext,
    );

    if (!decision.shouldCompact) return;

    switch (await compactConversationUsecase(
      conversationId: conversationId,
      trigger: CompactionTrigger.auto,
    )) {
      case _:
        return;
    }
  }
}

final maybeAutoCompactConversationUsecaseProvider =
    Provider<MaybeAutoCompactConversationUsecase>(
      (ref) {
        return MaybeAutoCompactConversationUsecase(
          compactConversationUsecase: CompactConversationUsecase(
            compactionExecution: ref.watch(
              compactionExecutionRuntimeProvider,
            ),
            messageRepository: ref.watch(messageRepositoryProvider),
            conversationRepository: ref.watch(conversationRepositoryProvider),
            modelSelectionStore: (workspaceId) => ref.read(
              modelSelectionStoreProvider(workspaceId).future,
            ),
            chatbotService: ref.watch(chatbotServiceProvider),
            selectCompactionRangeUsecase: ref.watch(
              selectCompactionRangeUsecaseProvider,
            ),
          ),
          conversationRepository: ref.watch(conversationRepositoryProvider),
          modelSelectionStore: (workspaceId) => ref.read(
            modelSelectionStoreProvider(workspaceId).future,
          ),
          apiModelRepository: ref.watch(apiModelRepositoryProvider),
          shouldCompactConversationUsecase: ref.watch(
            shouldCompactConversationUsecaseProvider,
          ),
        );
      },
    );
