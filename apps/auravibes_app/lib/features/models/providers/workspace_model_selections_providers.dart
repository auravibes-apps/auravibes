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

  yield* WorkspaceModelSelectionsProviders(
    selections: workspaceModelSelectionRepository.watch(workspaceId),
    providers: modelCatalogStore.watchAllProviders(),
    openAIModels: modelCatalogStore.watchModelsByProvider('openai'),
  ).stream;
}

class WorkspaceModelSelectionsProviders {
  WorkspaceModelSelectionsProviders({
    required this._selections,
    required this._providers,
    required this._openAIModels,
  });

  final Stream<List<WorkspaceModelSelectionWithConnectionEntity>> _selections;
  final Stream<List<ApiModelProviderEntity>> _providers;
  final Stream<List<ApiModelEntity>> _openAIModels;
  final _controller =
      StreamController<List<WorkspaceModelSelectionWithConnectionEntity>>();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  List<WorkspaceModelSelectionWithConnectionEntity>? _latestSelections;
  List<ApiModelProviderEntity>? _latestProviders;
  List<ApiModelEntity>? _latestOpenAIModels;

  Stream<List<WorkspaceModelSelectionWithConnectionEntity>> get stream {
    _controller
      ..onListen = _listen
      ..onCancel = cancel;
    return _controller.stream;
  }

  Future<void> cancel() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }

  void _emit() {
    final selections = _latestSelections;
    final providers = _latestProviders;
    final openAIModels = _latestOpenAIModels;
    if (selections == null || providers == null || openAIModels == null) {
      return;
    }
    _controller.add(
      _WorkspaceModelSelectionTransforms.withCodexProjections(
        selections,
        providers,
        openAIModels,
      ),
    );
  }

  void _onSelectionsChanged(
    List<WorkspaceModelSelectionWithConnectionEntity> value,
  ) {
    _latestSelections = value;
    _emit();
  }

  void _onProvidersChanged(List<ApiModelProviderEntity> value) {
    _latestProviders = value;
    _emit();
  }

  void _onOpenAIModelsChanged(List<ApiModelEntity> value) {
    _latestOpenAIModels = value;
    _emit();
  }

  void _listen() {
    _subscriptions
      ..add(
        _selections.listen(_onSelectionsChanged, onError: _controller.addError),
      )
      ..add(
        _providers.listen(_onProvidersChanged, onError: _controller.addError),
      )
      ..add(
        _openAIModels.listen(
          _onOpenAIModelsChanged,
          onError: _controller.addError,
        ),
      );
  }
}

class _WorkspaceModelSelectionTransforms {
  static List<WorkspaceModelSelectionWithConnectionEntity> withCodexProjections(
    List<WorkspaceModelSelectionWithConnectionEntity> models,
    List<ApiModelProviderEntity> providers,
    List<ApiModelEntity> openAIModels,
  ) {
    if (!_hasCodexSelections(models)) return models;

    final openAIProvider = providers.firstWhereOrNull(
      (provider) => provider.id == 'openai',
    );
    if (openAIProvider == null) {
      return _withoutCodexSelections(models);
    }

    final openAIModelsById = _codexModelsById(openAIModels);

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

  static bool _hasCodexSelections(
    List<WorkspaceModelSelectionWithConnectionEntity> models,
  ) => models.any(
    (model) =>
        model.modelConnection.modelId == ModelProviderOAuthProfiles.providerId,
  );

  static List<WorkspaceModelSelectionWithConnectionEntity>
  _withoutCodexSelections(
    List<WorkspaceModelSelectionWithConnectionEntity> models,
  ) => models
      .where(
        (model) =>
            model.modelConnection.modelId !=
            ModelProviderOAuthProfiles.providerId,
      )
      .toList();

  static Map<String, ApiModelEntity> _codexModelsById(
    List<ApiModelEntity> models,
  ) => {
    for (final model in models)
      if (model.isCodexRuntimeModel) model.id: model,
  };

  static WorkspaceModelSelectionWithConnectionEntity _withCodexProjection(
    WorkspaceModelSelectionWithConnectionEntity model,
    ApiModelProviderEntity openAIProvider,
    ApiModelEntity openAIModel,
  ) {
    return model.copyWith(
      workspaceModelSelection: _withCodexModelSelection(
        model.workspaceModelSelection,
        openAIModel,
      ),
      modelsProvider: _withCodexProvider(openAIProvider),
    );
  }

  static WorkspaceModelSelectionEntity _withCodexModelSelection(
    WorkspaceModelSelectionEntity selection,
    ApiModelEntity model,
  ) => selection.copyWith(
    modelName: model.name,
    modalitiesInput: CodexInputModalities.forModel(model),
    modalitiesOutput: model.modalitiesOutput,
    supportsReasoning: model.supportsReasoning,
    supportsToolCalls: model.supportsToolCalls,
  );

  static ApiModelProviderEntity _withCodexProvider(
    ApiModelProviderEntity provider,
  ) => ApiModelProviderEntity(
    id: ModelProviderOAuthProfiles.providerId,
    name: ModelProviderOAuthProfiles.displayName,
    type: provider.type,
    url: provider.url,
    doc: provider.doc,
  );

  static Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  _groupModelsByProvider(
    List<WorkspaceModelSelectionWithConnectionEntity> models,
  ) {
    final grouped =
        <String, List<WorkspaceModelSelectionWithConnectionEntity>>{};

    for (final model in models) {
      final connectionId = model.modelConnection.id;
      grouped.putIfAbsent(connectionId, () => []).add(model);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((left, right) => _compareProviderGroups(grouped, left, right));

    return {for (final key in sortedKeys) key: ?grouped[key]};
  }

  static int _compareProviderGroups(
    Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> grouped,
    String left,
    String right,
  ) {
    final leftModel = grouped[left]?.firstOrNull;
    final rightModel = grouped[right]?.firstOrNull;
    if (leftModel == null || rightModel == null) return 0;
    final providerCompare = _compareProviders(leftModel, rightModel);
    if (providerCompare != 0) return providerCompare;

    final credentialCompare = _compareConnections(leftModel, rightModel);
    if (credentialCompare != 0) return credentialCompare;

    return left.compareTo(right);
  }

  static int _compareProviders(
    WorkspaceModelSelectionWithConnectionEntity left,
    WorkspaceModelSelectionWithConnectionEntity right,
  ) => left.modelsProvider.name.compareTo(right.modelsProvider.name);

  static int _compareConnections(
    WorkspaceModelSelectionWithConnectionEntity left,
    WorkspaceModelSelectionWithConnectionEntity right,
  ) => left.modelConnection.name.compareTo(right.modelConnection.name);
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
    (_, next) => _addModelSelectionUpdate(controller, next),
    fireImmediately: true,
  );

  final _ = ref.onDispose(() {
    subscription.close();
    unawaited(controller.close());
  });

  return controller.stream;
}

void _addModelSelectionUpdate(
  StreamController<
    Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  >
  controller,
  AsyncValue<List<WorkspaceModelSelectionWithConnectionEntity>> next,
) {
  switch (next) {
    case AsyncData(:final value):
      controller.add(
        _WorkspaceModelSelectionTransforms._groupModelsByProvider(value),
      );
    case AsyncError(:final error, :final stackTrace):
      controller.addError(error, stackTrace);
    case AsyncLoading():
  }
}

// Top-level API/provider declarations are required by their consumers.
