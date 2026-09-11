// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/api_model_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/select_compaction_range_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/should_compact_conversation_usecase.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:riverpod/riverpod.dart';

const _kDefaultMaxOutputTokens = 4096;

typedef _LocalDependencies = ({
  ConversationRepository repository,
  Future<ModelSelectionStore> Function(String workspaceId) getModelStore,
  ApiModelRepository models,
  ShouldCompactConversationUsecase shouldCompact,
});

typedef _LocalCompactionContext = ({
  String conversationId,
  String workspaceId,
  String selectedModelId,
  String selectedProviderId,
  int maxOutputTokens,
  int? contextLimit,
});

typedef _LocalCompactionModel = ({
  String workspaceId,
  WorkspaceModelSelectionWithConnectionEntity model,
});

class const MaybeAutoCompactConversationUsecase({
  required final CompactConversationUsecase compactConversationUsecase,
  final ConversationRepository? conversationRepository,
  final Future<ModelSelectionStore> Function(String workspaceId)?
  modelSelectionStore,
  final ApiModelRepository? apiModelRepository,
  final ShouldCompactConversationUsecase? shouldCompactConversationUsecase,
  final Future<bool> Function(String conversationId)? cloudShouldCompact,
}) {
  Future<void> call({required String conversationId}) async {
    final cloudDecision = cloudShouldCompact;
    if (cloudDecision != null) {
      await _runCloudCompaction(cloudDecision, conversationId);

      return;
    }
    await _runLocalCompaction(conversationId);
  }

  Future<void> _runCloudCompaction(
    Future<bool> Function(String conversationId) cloudDecision,
    String conversationId,
  ) async {
    if (!await cloudDecision(conversationId)) return;

    final _ = await compactConversationUsecase(
      conversationId: conversationId,
      trigger: CompactionTrigger.auto,
    );
  }

  Future<void> _runLocalCompaction(String conversationId) async {
    final dependencies = _requiredLocalDependencies();
    final context = await _localCompactionContext(dependencies, conversationId);
    if (context == null || !await _shouldCompact(dependencies, context)) {
      return;
    }

    final _ = await compactConversationUsecase(
      conversationId: conversationId,
      trigger: CompactionTrigger.auto,
    );
  }

  _LocalDependencies _requiredLocalDependencies() {
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

    return (
      repository: repository,
      getModelStore: getModelStore,
      models: models,
      shouldCompact: shouldCompact,
    );
  }
}

Future<_LocalCompactionContext?> _localCompactionContext(
  _LocalDependencies dependencies,
  String conversationId,
) async {
  final conversation = await dependencies.repository.getConversationById(
    conversationId,
  );
  if (conversation == null) return null;

  return await _localCompactionContextForConversation(
    dependencies,
    conversation,
    conversationId,
  );
}

Future<_LocalCompactionContext?> _localCompactionContextForConversation(
  _LocalDependencies dependencies,
  ConversationEntity conversation,
  String conversationId,
) async {
  final modelId = conversation.modelId;
  if (modelId == null) return null;

  final loadedModel = await _loadLocalModel(
    dependencies,
    conversation.workspaceId,
    modelId,
  );
  if (loadedModel == null) return null;

  return await _localCompactionContextForLoadedModel(
    dependencies,
    conversationId,
    loadedModel,
  );
}

Future<_LocalCompactionContext> _localCompactionContextForLoadedModel(
  _LocalDependencies dependencies,
  String conversationId,
  _LocalCompactionModel loadedModel,
) async {
  final apiModel = await _loadLocalApiModel(dependencies, loadedModel.model);

  return _buildLocalCompactionContext(
    conversationId: conversationId,
    loadedModel: loadedModel,
    maxOutputTokens: apiModel?.limitOutput ?? _kDefaultMaxOutputTokens,
    contextLimit: apiModel?.limitContext,
  );
}

Future<ApiModelEntity?> _loadLocalApiModel(
  _LocalDependencies dependencies,
  WorkspaceModelSelectionWithConnectionEntity model,
) => dependencies.models.getModelByProviderAndModelId(
  model.modelsProvider.id,
  model.workspaceModelSelection.modelId,
);

_LocalCompactionContext _buildLocalCompactionContext({
  required String conversationId,
  required _LocalCompactionModel loadedModel,
  required int maxOutputTokens,
  required int? contextLimit,
}) => (
  conversationId: conversationId,
  workspaceId: loadedModel.workspaceId,
  selectedModelId: loadedModel.model.workspaceModelSelection.modelId,
  selectedProviderId: loadedModel.model.modelsProvider.id,
  maxOutputTokens: maxOutputTokens,
  contextLimit: contextLimit,
);

Future<_LocalCompactionModel?> _loadLocalModel(
  _LocalDependencies dependencies,
  String workspaceId,
  String modelId,
) async {
  final model = await (await dependencies.getModelStore(workspaceId))
      .getById(modelId);
  if (model == null) return null;

  return (workspaceId: workspaceId, model: model);
}

Future<bool> _shouldCompact(
  _LocalDependencies dependencies,
  _LocalCompactionContext context,
) async => (await dependencies.shouldCompact((
  conversationId: context.conversationId,
  workspaceId: context.workspaceId,
  selectedModelId: context.selectedModelId,
  selectedProviderId: context.selectedProviderId,
  maxOutputTokens: context.maxOutputTokens,
  contextLimit: context.contextLimit,
  trigger: CompactionTrigger.auto,
))).shouldCompact;

final maybeAutoCompactConversationUsecaseProvider =
    Provider<MaybeAutoCompactConversationUsecase>((ref) {
      return MaybeAutoCompactConversationUsecase(
        compactConversationUsecase: .new(
          compactionExecution: ref.watch(compactionExecutionRuntimeProvider),
          messageRepository: ref.watch(messageRepositoryProvider),
          conversationRepository: ref.watch(conversationRepositoryProvider),
          modelSelectionStore: (workspaceId) =>
              ref.read(modelSelectionStoreProvider(workspaceId).future),
          chatbotService: ref.watch(chatbotServiceProvider),
          selectCompactionRangeUsecase: ref.watch(
            selectCompactionRangeUsecaseProvider,
          ),
        ),
        conversationRepository: ref.watch(conversationRepositoryProvider),
        modelSelectionStore: (workspaceId) =>
            ref.read(modelSelectionStoreProvider(workspaceId).future),
        apiModelRepository: ref.watch(apiModelRepositoryProvider),
        shouldCompactConversationUsecase: ref.watch(
          shouldCompactConversationUsecaseProvider,
        ),
      );
    });
