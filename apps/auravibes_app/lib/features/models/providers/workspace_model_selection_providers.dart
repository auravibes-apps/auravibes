// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/services/codex_input_modalities.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_model_selection_providers.g.dart';

@Riverpod(
  dependencies: [workspaceSession],
)
Future<WorkspaceModelSelectionWithConnectionEntity?>
workspaceModelSelectionById(
  Ref ref,
  String workspaceModelSelectionId,
) async {
  final workspaceId = ref
      .watch(workspaceSessionProvider)
      .workspace
      .localWorkspaceId;
  final workspaceModelSelectionRepository = await ref.watch(
    modelSelectionStoreProvider(workspaceId).future,
  );
  final modelCatalogStore = await ref.watch(
    modelCatalogStoreProvider(workspaceId).future,
  );

  final selectedModel = await workspaceModelSelectionRepository.getById(
    workspaceModelSelectionId,
  );
  if (selectedModel == null ||
      !isOpenAICodexProvider(selectedModel.modelConnection.modelId)) {
    return selectedModel;
  }

  final openAIModel = await modelCatalogStore.getModelByProviderAndModelId(
    'openai',
    selectedModel.workspaceModelSelection.modelId,
  );
  if (openAIModel == null || !openAIModel.isCodexRuntimeModel) {
    return selectedModel;
  }

  return selectedModel.copyWith(
    workspaceModelSelection: selectedModel.workspaceModelSelection.copyWith(
      modelName: openAIModel.name,
      modalitiesInput: codexInputModalities(openAIModel),
      modalitiesOutput: openAIModel.modalitiesOutput,
      supportsReasoning: openAIModel.supportsReasoning,
      supportsToolCalls: openAIModel.supportsToolCalls,
    ),
  );
}

@Riverpod(
  dependencies: [
    workspaceModelSelectionById,
    workspaceSession,
  ],
)
Future<int?> modelContextLimit(
  Ref ref,
  String workspaceModelSelectionId,
) async {
  final selectedModel = await ref.watch(
    workspaceModelSelectionByIdProvider(workspaceModelSelectionId).future,
  );
  final modelId = selectedModel?.workspaceModelSelection.modelId;
  final providerId = selectedModel?.modelsProvider.id;
  if (modelId == null || providerId == null) return null;
  final workspaceId = ref
      .watch(workspaceSessionProvider)
      .workspace
      .localWorkspaceId;

  final value = await ref.watch(
    getModelByProviderAndModelIdProvider(
      workspaceId: workspaceId,
      providerId: providerId,
      modelId: modelId,
    ).future,
  );

  return value?.limitContext;
}
