// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/features/models/models/model_connection_store.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/services/codex_input_modalities.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_model_selection_providers.g.dart';

@riverpod
Future<WorkspaceModelSelectionWithConnectionEntity?>
workspaceModelSelectionById(
  Ref ref,
  String workspaceId,
  String workspaceModelSelectionId,
) async {
  final workspaceModelSelectionRepository = await ref.watch(
    modelSelectionStoreProvider(workspaceId).future,
  );
  final modelCatalogStore = await ref.watch(
    modelCatalogStoreProvider(workspaceId).future,
  );

  final selectedModel = await workspaceModelSelectionRepository.getById(
    workspaceModelSelectionId,
  );
  if (selectedModel == null || !_isCodexSelection(selectedModel)) {
    return selectedModel;
  }

  return WorkspaceModelSelectionProviders.resolve(
    selectedModel,
    modelCatalogStore,
  );
}

bool _isCodexSelection(WorkspaceModelSelectionWithConnectionEntity selection) =>
    ModelProviderOAuthProfiles.isCodexProvider(
      selection.modelConnection.modelId,
    );

class WorkspaceModelSelectionProviders {
  static Future<WorkspaceModelSelectionWithConnectionEntity> resolve(
    WorkspaceModelSelectionWithConnectionEntity selectedModel,
    ModelCatalogStore modelCatalogStore,
  ) async {
    final openAIModel = await _codexRuntimeModel(
      modelCatalogStore,
      selectedModel.workspaceModelSelection.modelId,
    );
    if (openAIModel == null || !openAIModel.isCodexRuntimeModel) {
      return selectedModel;
    }

    return selectedModel.copyWith(
      workspaceModelSelection: selectedModel.workspaceModelSelection.copyWith(
        modelName: openAIModel.name,
        modalitiesInput: CodexInputModalities.forModel(openAIModel),
        modalitiesOutput: openAIModel.modalitiesOutput,
        supportsReasoning: openAIModel.supportsReasoning,
        supportsToolCalls: openAIModel.supportsToolCalls,
      ),
    );
  }

  static Future<ApiModelEntity?> _codexRuntimeModel(
    ModelCatalogStore modelCatalogStore,
    String modelId,
  ) => modelCatalogStore.getModelByProviderAndModelId('openai', modelId);
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<int?> modelContextLimit(
  Ref ref,
  String workspaceId,
  String workspaceModelSelectionId,
) async {
  final selectedModel = await ref.watch(
    workspaceModelSelectionByIdProvider(
      workspaceId,
      workspaceModelSelectionId,
    ).future,
  );
  final selection = selectedModel;
  if (selection == null) return null;

  return _modelContextLimit(ref, workspaceId, selection);
}

Future<int?> _modelContextLimit(
  Ref ref,
  String workspaceId,
  WorkspaceModelSelectionWithConnectionEntity selection,
) async {
  final value = await ref.watch(
    getModelByProviderAndModelIdProvider(
      workspaceId: workspaceId,
      providerId: selection.modelsProvider.id,
      modelId: selection.workspaceModelSelection.modelId,
    ).future,
  );

  return value?.limitContext;
}
// Top-level API/provider declarations are required by their consumers.
