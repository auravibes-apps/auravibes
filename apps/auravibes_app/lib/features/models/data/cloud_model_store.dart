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

const _cloudModelPollInterval = Duration(minutes: 15);

class CloudModelStore
    with _CloudModelStoreConnectionMethods, _CloudModelStoreSelectionMethods
    implements ModelConnectionStore, ModelSelectionStore {
  new(this._workspaceId, this._usecases);

  @override
  final String _workspaceId;

  @override
  final CloudModelConnectionUsecases _usecases;

  @override
  Stream<List<ModelConnectionEntity>> watchModelConnections(
    ModelConnectionFilter filter,
  ) => _usecases.watchConnections().map(
    (items) =>
        items.map((item) => _connectionEntity(item, _workspaceId)).toList(),
  );
}

mixin _CloudModelStoreConnectionMethods {
  String get _workspaceId;
  CloudModelConnectionUsecases get _usecases;

  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate connection,
  ) async {
    final id = const Uuid().v4();
    final created = await _createConnection(_usecases, id, connection);

    return _connectionEntity(
      CloudModelConnection.fromView(created),
      _workspaceId,
      hasKeyOverride: connection.authMode == ModelProviderAuthMode.apiKey,
    );
  }

  Future<ModelConnectionForEdit?> getModelConnectionForEdit(String id) async {
    final item = await _connectionById(id);
    return item == null ? null : _modelConnectionForEdit(item, _workspaceId);
  }

  Future<ModelConnectionEntity> updateModelConnection(
    String id,
    ModelConnectionToUpdate update,
  ) async {
    final existing = await _connectionById(id);
    if (existing == null) throw StateError('Model connection not found: $id');

    final updated = await _updateConnection(_usecases, existing, update);

    return _connectionEntity(
      CloudModelConnection.fromView(updated),
      _workspaceId,
      hasKeyOverride: _updatedKeyOverride(update.key),
    );
  }

  Future<void> deleteModelConnection(String id) async {
    final existing = await _connectionById(id);
    if (existing == null) throw StateError('Model connection not found: $id');
    await _usecases.delete(existing);
  }

  Future<CloudModelConnection?> _connectionById(String id) async {
    final items = await _usecases.watchConnections().first;

    return items.where((item) => item.id == id).firstOrNull;
  }
}

mixin _CloudModelStoreSelectionMethods {
  String get _workspaceId;
  CloudModelConnectionUsecases get _usecases;

  Stream<List<WorkspaceModelSelectionWithConnectionEntity>> watch(
    String workspaceId,
  ) => _usecases.watchSelections().map(
    (items) =>
        items.map((item) => _selectionEntity(item, _workspaceId)).toList(),
  );

  Future<WorkspaceModelSelectionWithConnectionEntity?> getById(
    String id,
  ) async {
    final items = await watch(_workspaceId).first;

    return items
        .where((item) => item.workspaceModelSelection.id == id)
        .firstOrNull;
  }
}

Future<ModelConnectionView> _createConnection(
  CloudModelConnectionUsecases usecases,
  String id,
  ModelConnectionToCreate connection,
) => usecases.create((
  id: id,
  name: connection.name,
  providerId: connection.modelId,
  secret: _connectionSecret(connection),
  url: connection.url,
));

Future<ModelConnectionView> _updateConnection(
  CloudModelConnectionUsecases usecases,
  CloudModelConnection existing,
  ModelConnectionToUpdate update,
) => usecases.update((
  connection: existing,
  name: update.name ?? existing.name,
  url: update.url ?? existing.url,
  secret: _updatedSecret(update.key),
));

String? _connectionSecret(ModelConnectionToCreate connection) =>
    connection.authMode == ModelProviderAuthMode.apiKey ? connection.key : null;

String? _updatedSecret(String? key) => key?.isNotEmpty == true ? key : null;

bool? _updatedKeyOverride(String? key) => key?.isNotEmpty == true ? true : null;

ModelConnectionForEdit _modelConnectionForEdit(
  CloudModelConnection item,
  String workspaceId,
) => ModelConnectionForEdit(
  id: item.id,
  name: item.name,
  modelId: item.providerId,
  workspaceId: workspaceId,
  hasKey: item.hasSecret,
  url: item.url,
  keySuffix: item.keySuffix,
);

ModelConnectionEntity _connectionEntity(
  CloudModelConnection item,
  String workspaceId, {
  bool? hasKeyOverride,
}) => ModelConnectionEntity(
  id: item.id,
  name: item.name,
  modelId: item.providerId,
  createdAt: item.createdAt,
  updatedAt: item.updatedAt,
  workspaceId: workspaceId,
  hasKey: hasKeyOverride ?? item.hasSecret,
  url: item.url,
  keySuffix: item.keySuffix,
);

WorkspaceModelSelectionWithConnectionEntity _selectionEntity(
  WorkspaceModelSelectionView selection,
  String workspaceId,
) => .new(
  workspaceModelSelection: _workspaceSelection(selection),
  modelConnection: _selectionConnection(selection, workspaceId),
  modelsProvider: _selectionProvider(selection),
);

WorkspaceModelSelectionEntity _workspaceSelection(
  WorkspaceModelSelectionView selection,
) => .new(
  id: selection.id,
  modelId: selection.modelId,
  createdAt: selection.createdAt,
  updatedAt: selection.updatedAt,
  modelConnectionId: selection.connectionId,
  modelName: selection.modelName,
);

ModelConnectionEntity _selectionConnection(
  WorkspaceModelSelectionView selection,
  String workspaceId,
) => .new(
  id: selection.connectionId,
  name: selection.connectionName,
  modelId: selection.providerId,
  createdAt: selection.createdAt,
  updatedAt: selection.updatedAt,
  workspaceId: workspaceId,
  hasKey: selection.connectionHasSecret,
  url: selection.connectionUrl,
  keySuffix: selection.connectionKeySuffix,
);

ApiModelProviderEntity _selectionProvider(
  WorkspaceModelSelectionView selection,
) => .new(
  id: selection.providerId,
  name: selection.providerId,
  type: _selectionProviderType(selection.providerId),
  url: selection.connectionUrl ?? '',
  doc: '',
);

ModelProvidersType? _selectionProviderType(String providerId) =>
    switch (providerId) {
      'openai' => ModelProvidersType.openai,
      'anthropic' => ModelProvidersType.anthropic,
      'openrouter' => ModelProvidersType.openrouter,
      _ => null,
    };

class CloudModelCatalogStore
    with _CloudModelCatalogMethods
    implements ModelCatalogStore {
  const new(this._gateway);

  @override
  final CloudModelGateway _gateway;

  @override
  Future<List<ApiModelProviderEntity>> getAllProviders() async =>
      (await _gateway.listModelCatalogProviders())
          .map(_catalogProvider)
          .toList(growable: false);
}

mixin _CloudModelCatalogMethods {
  CloudModelGateway get _gateway;

  Future<List<ApiModelProviderEntity>> getAllProviders();

  Future<List<ApiModelEntity>> getAllModels() async =>
      (await _gateway.listModelCatalogModels())
          .map(_catalogModel)
          .toList(growable: false);

  Future<ApiModelEntity?> getModelByProviderAndModelId(
    String providerId,
    String modelId,
  ) async =>
      (await getModelsByProvider(providerId))
          .where((model) => model.id == modelId)
          .firstOrNull;

  Future<List<ApiModelEntity>> getModelsByProvider(String providerId) async =>
      (await _gateway.listModelCatalogModels(providerId: providerId))
          .map(_catalogModel)
          .toList(growable: false);

  Stream<List<ApiModelProviderEntity>> watchAllProviders() =>
      _poll(getAllProviders);

  Stream<List<ApiModelEntity>> watchModelsByProvider(String providerId) =>
      _poll(() => getModelsByProvider(providerId));

  Stream<T> _poll<T>(Future<T> Function() load) async* {
    while (true) {
      yield await load();
      await Future<void>.delayed(_cloudModelPollInterval);
    }
  }
}

ApiModelProviderEntity _catalogProvider(ApiModelProvider provider) =>
    ApiModelProviderEntity(
      id: provider.providerId,
      name: provider.name,
      type: _catalogProviderType(provider.type),
      url: provider.url,
      doc: provider.documentationUrl,
    );

ModelProvidersType? _catalogProviderType(String? type) => switch (type) {
  '@ai-sdk/openai' || '@ai-sdk/openai-compatible' => ModelProvidersType.openai,
  '@ai-sdk/anthropic' => ModelProvidersType.anthropic,
  '@openrouter/ai-sdk-provider' => ModelProvidersType.openrouter,
  _ => null,
};

ApiModelEntity _catalogModel(ApiModel model) =>
    _modelCapabilities(_modelCosts(_modelBase(model), model), model);

ApiModelEntity _modelBase(ApiModel model) => ApiModelEntity(
  modelProvider: model.providerId,
  id: model.modelId,
  name: model.name,
  limitContext: model.limitContext,
  limitOutput: model.limitOutput,
  modalitiesInput: model.modalitiesInput,
  modalitiesOutput: model.modalitiesOutput,
);

ApiModelEntity _modelCosts(ApiModelEntity base, ApiModel model) =>
    base.copyWith(
      family: model.family,
      costInput: model.costInput,
      costCacheRead: model.costCacheRead,
      costOutput: model.costOutput,
      openWeights: model.openWeights,
    );

ApiModelEntity _modelCapabilities(ApiModelEntity base, ApiModel model) =>
    base.copyWith(
      supportsReasoning: model.supportsReasoning,
      isCanonical: model.isCanonical,
      supportsPriorityMode: model.supportsPriorityMode,
      supportsToolCalls: model.supportsToolCalls,
    );
