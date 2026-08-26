// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/services/codex_input_modalities.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_model_selections_providers.g.dart';

@riverpod
Stream<List<WorkspaceModelSelectionWithConnectionEntity>>
listWorkspaceModelSelections(Ref ref, {required String workspaceId}) async* {
  final workspaceModelSelectionRepository = await ref.watch(
    modelSelectionStoreProvider(workspaceId).future,
  );
  final modelCatalogStore = await ref.watch(
    modelCatalogStoreProvider(workspaceId).future,
  );

  yield* _projectWorkspaceModelSelections(
    selections: workspaceModelSelectionRepository.watch(workspaceId),
    providers: modelCatalogStore.watchAllProviders(),
    openAIModels: modelCatalogStore.watchModelsByProvider('openai'),
  );
}

Stream<List<WorkspaceModelSelectionWithConnectionEntity>>
_projectWorkspaceModelSelections({
  required Stream<List<WorkspaceModelSelectionWithConnectionEntity>> selections,
  required Stream<List<ApiModelProviderEntity>> providers,
  required Stream<List<ApiModelEntity>> openAIModels,
}) {
  final controller =
      StreamController<List<WorkspaceModelSelectionWithConnectionEntity>>();
  List<WorkspaceModelSelectionWithConnectionEntity>? latestSelections;
  List<ApiModelProviderEntity>? latestProviders;
  List<ApiModelEntity>? latestOpenAIModels;
  final subscriptions = <StreamSubscription<dynamic>>[];

  void emit() {
    final selections = latestSelections;
    final providers = latestProviders;
    final openAIModels = latestOpenAIModels;
    if (selections == null || providers == null || openAIModels == null) {
      return;
    }
    controller.add(_withCodexProjections(selections, providers, openAIModels));
  }

  controller
    ..onListen = () {
      subscriptions
        ..add(
          selections.listen((value) {
            latestSelections = value;
            emit();
          }, onError: controller.addError),
        )
        ..add(
          providers.listen((value) {
            latestProviders = value;
            emit();
          }, onError: controller.addError),
        )
        ..add(
          openAIModels.listen((value) {
            latestOpenAIModels = value;
            emit();
          }, onError: controller.addError),
        );
    }
    ..onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

  return controller.stream;
}

List<WorkspaceModelSelectionWithConnectionEntity> _withCodexProjections(
  List<WorkspaceModelSelectionWithConnectionEntity> models,
  List<ApiModelProviderEntity> providers,
  List<ApiModelEntity> openAIModels,
) {
  final hasCodexSelections = models.any(
    (model) =>
        model.modelConnection.modelId == ModelProviderOAuthProfiles.providerId,
  );
  if (!hasCodexSelections) return models;

  final openAIProvider = providers.firstWhereOrNull(
    (provider) => provider.id == 'openai',
  );
  if (openAIProvider == null) {
    return models
        .where(
          (model) =>
              model.modelConnection.modelId !=
              ModelProviderOAuthProfiles.providerId,
        )
        .toList();
  }

  final openAIModelsById = {
    for (final model in openAIModels)
      if (model.isCodexRuntimeModel) model.id: model,
  };

  return [
    for (final model in models)
      if (model.modelConnection.modelId !=
          ModelProviderOAuthProfiles.providerId)
        model
      else if (openAIModelsById[model.workspaceModelSelection.modelId]
          case final openAIModel?)
        _withCodexProjection(model, openAIProvider, openAIModel),
  ];
}

WorkspaceModelSelectionWithConnectionEntity _withCodexProjection(
  WorkspaceModelSelectionWithConnectionEntity model,
  ApiModelProviderEntity openAIProvider,
  ApiModelEntity openAIModel,
) {
  return model.copyWith(
    workspaceModelSelection: model.workspaceModelSelection.copyWith(
      modelName: openAIModel.name,
      modalitiesInput: CodexInputModalities.forModel(openAIModel),
      modalitiesOutput: openAIModel.modalitiesOutput,
      supportsReasoning: openAIModel.supportsReasoning,
      supportsToolCalls: openAIModel.supportsToolCalls,
    ),
    modelsProvider: ApiModelProviderEntity(
      id: ModelProviderOAuthProfiles.providerId,
      name: ModelProviderOAuthProfiles.displayName,
      type: openAIProvider.type,
      url: openAIProvider.url,
      doc: openAIProvider.doc,
    ),
  );
}

/// Groups models by connection id for two-step model selection.
/// Returns a map where keys are credential-backed connection ids.
@riverpod
Stream<Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>>
listModelsGroupedByProvider(Ref ref, {required String workspaceId}) {
  final controller =
      StreamController<
        Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
      >();
  final subscription = ref.listen(
    listWorkspaceModelSelectionsProvider(workspaceId: workspaceId),
    (_, next) {
      switch (next) {
        case AsyncData(:final value):
          controller.add(_groupModelsByProvider(value));
        case AsyncError(:final error, :final stackTrace):
          controller.addError(error, stackTrace);
        case AsyncLoading():
      }
    },
    fireImmediately: true,
  );

  final _ = ref.onDispose(() {
    subscription.close();
    unawaited(controller.close());
  });

  return controller.stream;
}

Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
_groupModelsByProvider(
  List<WorkspaceModelSelectionWithConnectionEntity> models,
) {
  final grouped = <String, List<WorkspaceModelSelectionWithConnectionEntity>>{};

  for (final model in models) {
    final connectionId = model.modelConnection.id;
    grouped.putIfAbsent(connectionId, () => []).add(model);
  }

  final sortedKeys = grouped.keys.toList()
    ..sort((left, right) => _compareProviderGroups(grouped, left, right));

  return {for (final key in sortedKeys) key: ?grouped[key]};
}

int _compareProviderGroups(
  Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> grouped,
  String left,
  String right,
) {
  final leftModel = grouped[left]?.firstOrNull;
  final rightModel = grouped[right]?.firstOrNull;
  if (leftModel == null || rightModel == null) return 0;
  final providerCompare = leftModel.modelsProvider.name.compareTo(
    rightModel.modelsProvider.name,
  );
  if (providerCompare != 0) return providerCompare;

  final credentialCompare = leftModel.modelConnection.name.compareTo(
    rightModel.modelConnection.name,
  );
  if (credentialCompare != 0) return credentialCompare;

  return left.compareTo(right);
}
// Top-level API/provider declarations are required by their consumers.
