// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/services/codex_input_modalities.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_model_selections_providers.g.dart';

@riverpod
Stream<List<WorkspaceModelSelectionWithConnectionEntity>>
listWorkspaceModelSelections(Ref ref, {required String workspaceId}) async* {
  final stores = await _modelStores(ref, workspaceId);

  yield* WorkspaceModelSelectionsProviders(
    selections: stores.selections.watch(workspaceId),
    providers: stores.catalog.watchAllProviders(),
    openAIModels: stores.catalog.watchModelsByProvider('openai'),
  ).stream;
}

Future<({ModelSelectionStore selections, ModelCatalogStore catalog})>
_modelStores(Ref ref, String workspaceId) async => (
  selections: await ref.watch(modelSelectionStoreProvider(workspaceId).future),
  catalog: await ref.watch(modelCatalogStoreProvider(workspaceId).future),
);

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
      ..onListen = listen
      ..onCancel = cancel;
    return _controller.stream;
  }

  Future<void> cancel() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }

  void listen() => _listenStreams();
}

extension on WorkspaceModelSelectionsProviders {
  void _emit() {
    if ((_latestSelections, _latestProviders, _latestOpenAIModels) case (
      final selections?,
      final providers?,
      final models?,
    )) {
      _controller.add(
        _WorkspaceModelSelectionTransforms.withCodexProjections(
          selections,
          providers,
          models,
        ),
      );
    }
  }

  void _listenStreams() {
    _subscriptions.addAll([
      _selections.listen(_updateSelections, onError: _controller.addError),
      _providers.listen(_updateProviders, onError: _controller.addError),
      _openAIModels.listen(_updateOpenAIModels, onError: _controller.addError),
    ]);
  }

  void _updateSelections(
    List<WorkspaceModelSelectionWithConnectionEntity> value,
  ) {
    _latestSelections = value;
    _emit();
  }

  void _updateProviders(List<ApiModelProviderEntity> value) {
    _latestProviders = value;
    _emit();
  }

  void _updateOpenAIModels(List<ApiModelEntity> value) {
    _latestOpenAIModels = value;
    _emit();
  }
}

class _WorkspaceModelSelectionTransforms {
  static List<WorkspaceModelSelectionWithConnectionEntity> withCodexProjections(
    List<WorkspaceModelSelectionWithConnectionEntity> models,
    List<ApiModelProviderEntity> providers,
    List<ApiModelEntity> openAIModels,
  ) {
    if (!models.any(_isCodexSelection)) return models;

    final openAIProvider = _openAIProvider(providers);
    if (openAIProvider == null) {
      return _withoutCodexSelections(models);
    }

    return _withOpenAIModels(models, openAIProvider, openAIModels);
  }

  static ApiModelProviderEntity? _openAIProvider(
    List<ApiModelProviderEntity> providers,
  ) {
    for (final provider in providers) {
      if (provider.id == 'openai') return provider;
    }
    return null;
  }

  static List<WorkspaceModelSelectionWithConnectionEntity> _withOpenAIModels(
    List<WorkspaceModelSelectionWithConnectionEntity> models,
    ApiModelProviderEntity provider,
    List<ApiModelEntity> openAIModels,
  ) {
    final modelsById = _CodexModelProjection.modelsById(openAIModels);
    return [
      for (final model in models)
        if (!_isCodexSelection(model))
          model
        else if (modelsById[model.workspaceModelSelection.modelId]
            case final openAIModel?)
          _CodexModelProjection.apply(model, provider, openAIModel),
    ];
  }

  static bool _isCodexSelection(
    WorkspaceModelSelectionWithConnectionEntity model,
  ) => model.modelConnection.modelId == ModelProviderOAuthProfiles.providerId;

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

  static Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  _groupModelsByProvider(
    List<WorkspaceModelSelectionWithConnectionEntity> models,
  ) {
    final grouped = _emptyProviderGroups(models);
    for (final model in models) {
      grouped[model.modelConnection.id]!.add(model);
    }

    final sortedKeys = _sortedProviderKeys(grouped);
    return {for (final key in sortedKeys) key: grouped[key]!};
  }

  static Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  _emptyProviderGroups(
    List<WorkspaceModelSelectionWithConnectionEntity> models,
  ) => {for (final model in models) model.modelConnection.id: []};

  static List<String> _sortedProviderKeys(
    Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> grouped,
  ) => grouped.keys.toList()
    ..sort(
      (left, right) => _ProviderGroupOrdering.compare(grouped, left, right),
    );
}

class _ProviderGroupOrdering {
  static int compare(
    Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> grouped,
    String left,
    String right,
  ) {
    final models = _providerModels(grouped, left, right);
    final providerCompare = _compareProviders(models.left, models.right);
    if (providerCompare != 0) return providerCompare;

    final connectionCompare = _compareConnections(models.left, models.right);
    return connectionCompare != 0 ? connectionCompare : left.compareTo(right);
  }

  static ({
    WorkspaceModelSelectionWithConnectionEntity left,
    WorkspaceModelSelectionWithConnectionEntity right,
  })
  _providerModels(
    Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> grouped,
    String left,
    String right,
  ) => (left: grouped[left]!.first, right: grouped[right]!.first);

  static int _compareProviders(
    WorkspaceModelSelectionWithConnectionEntity left,
    WorkspaceModelSelectionWithConnectionEntity right,
  ) => left.modelsProvider.name.compareTo(right.modelsProvider.name);

  static int _compareConnections(
    WorkspaceModelSelectionWithConnectionEntity left,
    WorkspaceModelSelectionWithConnectionEntity right,
  ) => left.modelConnection.name.compareTo(right.modelConnection.name);
}

class _CodexModelProjection {
  static Map<String, ApiModelEntity> modelsById(List<ApiModelEntity> models) =>
      {
        for (final model in models)
          if (model.isCodexRuntimeModel) model.id: model,
      };

  static WorkspaceModelSelectionWithConnectionEntity apply(
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
}

/// Groups models by connection id for two-step model selection.
/// Returns a map where keys are credential-backed connection ids.
@riverpod
Stream<Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>>
listModelsGroupedByProvider(Ref ref, {required String workspaceId}) {
  final controller = _modelGroupsController();
  final subscription = _listenForModelGroups(ref, workspaceId, controller);

  final _ = ref.onDispose(() {
    subscription.close();
    unawaited(controller.close());
  });

  return controller.stream;
}

StreamController<Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>>
_modelGroupsController() => StreamController();

ProviderSubscription<
  AsyncValue<List<WorkspaceModelSelectionWithConnectionEntity>>
>
_listenForModelGroups(
  Ref ref,
  String workspaceId,
  StreamController<
    Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  >
  controller,
) => ref.listen(
  listWorkspaceModelSelectionsProvider(workspaceId: workspaceId),
  (_, next) => _addModelSelectionUpdate(controller, next),
  fireImmediately: true,
);

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
