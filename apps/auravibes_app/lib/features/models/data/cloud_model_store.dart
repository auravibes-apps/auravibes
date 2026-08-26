import 'dart:async';

import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/models/cloud_model_resources.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/services/cloud_model_gateway.dart';
import 'package:auravibes_app/features/models/usecases/cloud_model_connection_usecases.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class CloudModelStore implements ModelConnectionStore, ModelSelectionStore {
  CloudModelStore(this._workspaceId, this._usecases);

  final String _workspaceId;
  final CloudModelConnectionUsecases _usecases;

  @override
  Stream<List<ModelConnectionEntity>> watchModelConnections(
    ModelConnectionFilter filter,
  ) => _usecases.watchConnections().map(
    (items) => items.map(_connectionEntity).toList(),
  );

  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate connection,
  ) async {
    final id = const Uuid().v4();
    final created = await _usecases.create(
      id: id,
      name: connection.name,
      providerId: connection.modelId,
      secret: connection.authMode == ModelProviderAuthMode.apiKey
          ? connection.key
          : null,
      url: connection.url,
    );

    return _connectionEntity(
      CloudModelConnection.fromView(created),
      hasKeyOverride: connection.authMode == ModelProviderAuthMode.apiKey,
    );
  }

  @override
  Future<ModelConnectionForEdit?> getModelConnectionForEdit(String id) async {
    final items = await _usecases.watchConnections().first;
    final item = items.where((item) => item.id == id).firstOrNull;
    if (item == null) return null;

    return ModelConnectionForEdit(
      id: item.id,
      name: item.name,
      modelId: item.providerId,
      workspaceId: _workspaceId,
      hasKey: item.hasSecret,
      url: item.url,
      keySuffix: item.keySuffix,
    );
  }

  @override
  Future<ModelConnectionEntity> updateModelConnection(
    String id,
    ModelConnectionToUpdate update,
  ) async {
    final items = await _usecases.watchConnections().first;
    final existing = items.where((item) => item.id == id).firstOrNull;
    if (existing == null) throw StateError('Model connection not found: $id');

    final updated = await _usecases.update(
      connection: existing,
      name: update.name ?? existing.name,
      url: update.url ?? existing.url,
      secret: update.key?.isNotEmpty == true ? update.key : null,
    );

    return _connectionEntity(
      CloudModelConnection.fromView(updated),
      hasKeyOverride: update.key?.isNotEmpty == true ? true : null,
    );
  }

  @override
  Future<void> deleteModelConnection(String id) async {
    final items = await _usecases.watchConnections().first;
    final existing = items.where((item) => item.id == id).firstOrNull;
    if (existing == null) throw StateError('Model connection not found: $id');
    await _usecases.delete(existing);
  }

  @override
  Stream<List<WorkspaceModelSelectionWithConnectionEntity>> watch(
    String workspaceId,
  ) => _usecases.watchSelections().map(
    (items) => items.map(_selection).toList(),
  );

  @override
  Future<WorkspaceModelSelectionWithConnectionEntity?> getById(String id) =>
      _getById(id);

  Future<WorkspaceModelSelectionWithConnectionEntity?> _getById(
    String id,
  ) async {
    final items = await watch(_workspaceId).first;

    return items
        .where((item) => item.workspaceModelSelection.id == id)
        .firstOrNull;
  }

  WorkspaceModelSelectionWithConnectionEntity _selection(
    WorkspaceModelSelectionView selection,
  ) {
    final providerType = switch (selection.providerId) {
      'openai' => ModelProvidersType.openai,
      'anthropic' => ModelProvidersType.anthropic,
      'openrouter' => ModelProvidersType.openrouter,
      _ => null,
    };

    return WorkspaceModelSelectionWithConnectionEntity(
      workspaceModelSelection: WorkspaceModelSelectionEntity(
        id: selection.id,
        modelId: selection.modelId,
        createdAt: selection.createdAt,
        updatedAt: selection.updatedAt,
        modelConnectionId: selection.connectionId,
        modelName: selection.modelName,
      ),
      modelConnection: ModelConnectionEntity(
        id: selection.connectionId,
        name: selection.connectionName,
        modelId: selection.providerId,
        createdAt: selection.createdAt,
        updatedAt: selection.updatedAt,
        workspaceId: _workspaceId,
        hasKey: selection.connectionHasSecret,
        url: selection.connectionUrl,
        keySuffix: selection.connectionKeySuffix,
      ),
      modelsProvider: ApiModelProviderEntity(
        id: selection.providerId,
        name: selection.providerId,
        type: providerType,
        url: selection.connectionUrl ?? '',
        doc: '',
      ),
    );
  }

  ModelConnectionEntity _connectionEntity(
    CloudModelConnection item, {
    bool? hasKeyOverride,
  }) => ModelConnectionEntity(
    id: item.id,
    name: item.name,
    modelId: item.providerId,
    createdAt: item.createdAt,
    updatedAt: item.updatedAt,
    workspaceId: _workspaceId,
    hasKey: hasKeyOverride ?? item.hasSecret,
    url: item.url,
    keySuffix: item.keySuffix,
  );
}

class CloudModelCatalogStore implements ModelCatalogStore {
  static const _pollInterval = Duration(minutes: 15);
  const CloudModelCatalogStore(this._gateway);

  final CloudModelGateway _gateway;

  @override
  Future<List<ApiModelProviderEntity>> getAllProviders() async =>
      (await _gateway.listModelCatalogProviders())
          .map(_provider)
          .toList(growable: false);

  @override
  Future<List<ApiModelEntity>> getAllModels() async =>
      (await _gateway.listModelCatalogModels())
          .map(_model)
          .toList(growable: false);

  @override
  Future<ApiModelEntity?> getModelByProviderAndModelId(
    String providerId,
    String modelId,
  ) async => (await getModelsByProvider(
    providerId,
  )).where((model) => model.id == modelId).firstOrNull;

  @override
  Future<List<ApiModelEntity>> getModelsByProvider(String providerId) async =>
      (await _gateway.listModelCatalogModels(
        providerId: providerId,
      )).map(_model).toList(growable: false);

  @override
  Stream<List<ApiModelProviderEntity>> watchAllProviders() =>
      _poll(getAllProviders);

  @override
  Stream<List<ApiModelEntity>> watchModelsByProvider(String providerId) =>
      _poll(() => getModelsByProvider(providerId));

  Stream<T> _poll<T>(Future<T> Function() load) async* {
    while (true) {
      yield await load();
      await Future<void>.delayed(_pollInterval);
    }
  }

  ApiModelProviderEntity _provider(ApiModelProvider provider) =>
      ApiModelProviderEntity(
        id: provider.providerId,
        name: provider.name,
        type: switch (provider.type) {
          '@ai-sdk/openai' ||
          '@ai-sdk/openai-compatible' => ModelProvidersType.openai,
          '@ai-sdk/anthropic' => ModelProvidersType.anthropic,
          '@openrouter/ai-sdk-provider' => ModelProvidersType.openrouter,
          _ => null,
        },
        url: provider.url,
        doc: provider.documentationUrl,
      );

  ApiModelEntity _model(ApiModel model) => ApiModelEntity(
    modelProvider: model.providerId,
    id: model.modelId,
    name: model.name,
    limitContext: model.limitContext,
    limitOutput: model.limitOutput,
    modalitiesInput: model.modalitiesInput,
    modalitiesOutput: model.modalitiesOutput,
    family: model.family,
    costInput: model.costInput,
    costCacheRead: model.costCacheRead,
    costOutput: model.costOutput,
    openWeights: model.openWeights,
    supportsReasoning: model.supportsReasoning,
    isCanonical: model.isCanonical,
    supportsPriorityMode: model.supportsPriorityMode,
    supportsToolCalls: model.supportsToolCalls,
  );
}
