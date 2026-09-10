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
  final stores = await _modelSelectionStores(ref, workspaceId);
  final selectedModel = await stores.selections.getById(
    workspaceModelSelectionId,
  );

  return _resolveSelectedModel(selectedModel, stores.catalog);
}

Future<({ModelSelectionStore selections, ModelCatalogStore catalog})>
_modelSelectionStores(Ref ref, String workspaceId) async => (
  selections: await ref.watch(modelSelectionStoreProvider(workspaceId).future),
  catalog: await ref.watch(modelCatalogStoreProvider(workspaceId).future),
);

bool _isCodexSelection(WorkspaceModelSelectionWithConnectionEntity selection) =>
    ModelProviderOAuthProfiles.isCodexProvider(
      selection.modelConnection.modelId,
    );

Future<WorkspaceModelSelectionWithConnectionEntity?> _resolveSelectedModel(
  WorkspaceModelSelectionWithConnectionEntity? selectedModel,
  ModelCatalogStore catalog,
) {
  if (selectedModel == null || !_isCodexSelection(selectedModel)) {
    return Future.value(selectedModel);
  }

  return WorkspaceModelSelectionProviders.resolve(selectedModel, catalog);
}

class WorkspaceModelSelectionProviders {
  static Future<WorkspaceModelSelectionWithConnectionEntity> resolve(
    WorkspaceModelSelectionWithConnectionEntity selectedModel,
    ModelCatalogStore modelCatalogStore,
  ) async {
    final modelId = selectedModel.workspaceModelSelection.modelId;
    final openAIModel = await _codexRuntimeModel(modelCatalogStore, modelId);

    return _resolveRuntimeModel(selectedModel, openAIModel);
  }

  static WorkspaceModelSelectionWithConnectionEntity _resolveRuntimeModel(
    WorkspaceModelSelectionWithConnectionEntity selectedModel,
    ApiModelEntity? openAIModel,
  ) {
    if (openAIModel == null || !openAIModel.isCodexRuntimeModel) {
      return selectedModel;
    }

    return selectedModel.copyWith(
      workspaceModelSelection: _withRuntimeModel(
        selectedModel.workspaceModelSelection,
        openAIModel,
      ),
    );
  }

  static WorkspaceModelSelectionEntity _withRuntimeModel(
    WorkspaceModelSelectionEntity selection,
    ApiModelEntity model,
  ) => selection.copyWith(
    modelName: model.name,
    modalitiesInput: CodexInputModalities.forModel(model),
    modalitiesOutput: model.modalitiesOutput,
    supportsReasoning: model.supportsReasoning,
    supportsToolCalls: model.supportsToolCalls,
  );

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
