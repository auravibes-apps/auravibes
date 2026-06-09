// Required: Existing code repeats lookups where extraction adds noise.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/repositories/api_model_repository.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/should_compact_conversation_usecase.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:riverpod/riverpod.dart';

const _kDefaultMaxOutputTokens = 4096;

class MaybeAutoCompactConversationUsecase {
  const MaybeAutoCompactConversationUsecase({
    required this.conversationRepository,
    required this.workspaceModelSelectionsRepository,
    required this.apiModelRepository,
    required this.shouldCompactConversationUsecase,
    required this.compactConversationUsecase,
  });

  final ConversationRepository conversationRepository;
  final WorkspaceModelSelectionRepository workspaceModelSelectionsRepository;
  final ApiModelRepository apiModelRepository;
  final ShouldCompactConversationUsecase shouldCompactConversationUsecase;
  final CompactConversationUsecase compactConversationUsecase;

  Future<void> call({required String conversationId}) async {
    final conversation = await conversationRepository.getConversationById(
      conversationId,
    );
    if (conversation == null) return;

    final modelId = conversation.modelId;
    if (modelId == null) return;

    final foundModel = await workspaceModelSelectionsRepository
        .getWorkspaceModelSelectionById(modelId);
    if (foundModel == null) return;

    final apiModel = await apiModelRepository.getModelByProviderAndModelId(
      foundModel.modelsProvider.id,
      foundModel.workspaceModelSelection.modelId,
    );

    final decision = await shouldCompactConversationUsecase(
      conversationId: conversationId,
      workspaceId: conversation.workspaceId,
      selectedModelId: foundModel.workspaceModelSelection.modelId,
      selectedProviderId: foundModel.modelsProvider.id,
      maxOutputTokens: apiModel?.limitOutput ?? _kDefaultMaxOutputTokens,
      contextLimit: apiModel?.limitContext,
    );

    if (!decision.shouldCompact) return;

    final _ = await compactConversationUsecase(
      conversationId: conversationId,
      trigger: CompactionTrigger.auto,
    );
  }
}

final maybeAutoCompactConversationUsecaseProvider =
    Provider<MaybeAutoCompactConversationUsecase>((ref) {
      return MaybeAutoCompactConversationUsecase(
        conversationRepository: ref.watch(conversationRepositoryProvider),
        workspaceModelSelectionsRepository: ref.watch(
          workspaceModelSelectionRepositoryProvider,
        ),
        apiModelRepository: ref.watch(apiModelRepositoryProvider),
        shouldCompactConversationUsecase: ref.watch(
          shouldCompactConversationUsecaseProvider,
        ),
        compactConversationUsecase: ref.watch(
          compactConversationUsecaseProvider,
        ),
      );
    });
