import 'dart:async';

import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/models/cloud_model_resources.dart';
import 'package:auravibes_app/features/models/models/model_provider_verification.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/services/cloud_model_gateway.dart';
import 'package:auravibes_app/features/models/usecases/cloud_model_connection_usecases.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_app/services/model_provider_services/model_provider.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

const _cloudModelPollInterval = Duration(minutes: 15);

class CloudModelStore
    with
        _CloudModelStoreVerificationMethods,
        _CloudModelStoreConnectionMethods,
        _CloudModelStoreSelectionMethods
    implements ModelConnectionStore, ModelSelectionStore {
  new(
    this._workspaceId,
    this._usecases, {
    ModelProviderServices? modelProviderServices,
  }) : _modelProviderServices =
           modelProviderServices ?? ModelProviderServices();

  @override
  final String _workspaceId;

  @override
  final CloudModelConnectionUsecases _usecases;

  @override
  final ModelProviderServices _modelProviderServices;

  @override
  Stream<List<ModelConnectionEntity>> watchModelConnections(
    ModelConnectionFilter filter,
  ) => _usecases.watchConnections().map(
    (items) =>
        items.map((item) => _connectionEntity(item, _workspaceId)).toList(),
  );
}

mixin _CloudModelStoreVerificationMethods {
  String get _workspaceId;
  CloudModelConnectionUsecases get _usecases;
  ModelProviderServices get _modelProviderServices;

  Future<ModelProviderVerification> verifyModelConnection(
    ModelProviderVerificationRequest request,
  ) {
    final key = request.key?.trim();
    final connectionId = request.connectionId;
    if (connectionId != null && (key == null || key.isEmpty)) {
      return _verifyCloudDraftModelConnection(_usecases, request, connectionId);
    }
    if (key == null || key.isEmpty) {
      throw StateError('Model provider API key is required');
    }

    return _verifyApiKeyModelConnection(_modelProviderServices, request, key);
  }

  Future<void> _requireCreateVerification(
    ModelConnectionToCreate connection,
    ModelProviderVerification? verification,
  ) async {
    final verificationRequest = ModelProviderVerificationRequest(
      workspaceId: connection.workspaceId,
      providerId: connection.modelId,
      connectionId: null,
      expectedRevision: null,
      url: connection.url,
      key: connection.key,
    );
    if (verification == null) {
      await _testApiKeyConnection(connection);

      return;
    }

    _requireVerification(verification, verificationRequest);
  }

  Future<void> _testApiKeyConnection(ModelConnectionToCreate connection) async {
    if (connection.authMode != ModelProviderAuthMode.apiKey) return;

    final key = connection.key.trim();
    if (key.isEmpty) throw StateError('Model provider API key is required');

    final models = await _modelProviderServices.getWorkspaceModelSelections(
      .new(
        type: .fromString(connection.modelId),
        key: key,
        url: connection.url,
      ),
    );
    if (models == null) {
      throw StateError('Model provider connection test failed');
    }
  }

  Future<String?> _verificationReceiptForUpdate(
    CloudModelConnection existing,
    ModelConnectionToUpdate update,
    ModelProviderVerification? verification,
  ) async {
    final nextUrl = update.url ?? existing.url;
    final key = _updatedSecret(update.key);
    if (key == null && (update.url == null || nextUrl == existing.url)) {
      return null;
    }

    if (verification != null) {
      return _verificationReceiptFromVerifiedUpdate(
        existing,
        update,
        verification,
      );
    }

    return await _verifyUnverifiedUpdate(existing, key, nextUrl);
  }

  String? _verificationReceiptFromVerifiedUpdate(
    CloudModelConnection existing,
    ModelConnectionToUpdate update,
    ModelProviderVerification verification,
  ) {
    _requireUpdateVerification(_workspaceId, existing, update, verification);

    return verification.serverReceipt;
  }

  Future<String?> _verifyUnverifiedUpdate(
    CloudModelConnection existing,
    String? key,
    String? nextUrl,
  ) async {
    if (key != null) {
      await _testApiKeyConnection(
        .new(
          name: existing.name,
          workspaceId: _workspaceId,
          modelId: existing.providerId,
          key: key,
          url: nextUrl,
        ),
      );

      return null;
    }

    final result = await _usecases.verifyDraft(
      connectionId: existing.id,
      expectedRevision: existing.revision,
      url: nextUrl,
    );

    return result.verificationReceipt;
  }
}

mixin _CloudModelStoreConnectionMethods on _CloudModelStoreVerificationMethods {
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate connection, {
    ModelProviderVerification? verification,
  }) async {
    await _requireCreateVerification(connection, verification);
    final id = const Uuid().v4();
    final created = await _createConnection(
      _usecases,
      id,
      connection.copyWith(key: connection.key.trim()),
    );

    return _connectionEntity(
      .fromView(created),
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
    ModelConnectionToUpdate update, {
    ModelProviderVerification? verification,
  }) async {
    final existing = await _connectionById(id);
    if (existing == null) throw StateError('Model connection not found: $id');

    final verificationReceipt = await _verificationReceiptForUpdate(
      existing,
      update,
      verification,
    );
    final updated = await _updateConnection(
      _usecases,
      existing,
      update,
      verificationReceipt: verificationReceipt,
    );

    return _connectionEntity(
      .fromView(updated),
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

Future<ModelProviderVerification> _verifyCloudDraftModelConnection(
  CloudModelConnectionUsecases usecases,
  ModelProviderVerificationRequest request,
  String connectionId,
) async {
  final revision = request.expectedRevision;
  if (revision == null) throw const ProviderVerificationMismatchException();
  final result = await usecases.verifyDraft(
    connectionId: connectionId,
    expectedRevision: revision,
    url: request.url,
  );

  return ModelProviderVerification.fromRequest(
    request: request,
    modelIds: result.modelIds,
    serverReceipt: result.verificationReceipt,
  );
}

Future<ModelProviderVerification> _verifyApiKeyModelConnection(
  ModelProviderServices services,
  ModelProviderVerificationRequest request,
  String key,
) async {
  final models = await services.getWorkspaceModelSelections(
    .new(type: .fromString(request.providerId), key: key, url: request.url),
  );
  if (models == null) {
    throw StateError('Model provider connection test failed');
  }

  return ModelProviderVerification.fromRequest(
    request: request,
    modelIds: models.map((model) => model.modelId).toList(),
  );
}

mixin _CloudModelStoreSelectionMethods {
  String get _workspaceId;
  CloudModelConnectionUsecases get _usecases;

  Stream<List<WorkspaceModelSelectionWithConnectionEntity>> watch(String _) =>
      _usecases.watchSelections().map(
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
  ModelConnectionToUpdate update, {
  String? verificationReceipt,
}) => usecases.update((
  connection: existing,
  name: update.name ?? existing.name,
  url: update.url ?? existing.url,
  secret: _updatedSecret(update.key),
  verificationReceipt: verificationReceipt,
));

String? _connectionSecret(ModelConnectionToCreate connection) =>
    connection.authMode == ModelProviderAuthMode.apiKey ? connection.key : null;

String? _updatedSecret(String? key) {
  final trimmed = key?.trim();

  return trimmed?.isNotEmpty == true ? trimmed : null;
}

bool? _updatedKeyOverride(String? key) =>
    key?.trim().isNotEmpty == true ? true : null;

void _requireUpdateVerification(
  String workspaceId,
  CloudModelConnection existing,
  ModelConnectionToUpdate update,
  ModelProviderVerification verification,
) => _requireVerification(
  verification,
  .new(
    workspaceId: workspaceId,
    providerId: existing.providerId,
    connectionId: existing.id,
    expectedRevision: existing.revision,
    url: update.url ?? existing.url,
    key: _updatedSecret(update.key),
  ),
);

void _requireVerification(
  ModelProviderVerification verification,
  ModelProviderVerificationRequest request,
) {
  if (verification.isExpired) {
    throw const ProviderVerificationExpiredException();
  }
  if (!verification.matches(request)) {
    throw const ProviderVerificationMismatchException();
  }
}

ModelConnectionForEdit _modelConnectionForEdit(
  CloudModelConnection item,
  String workspaceId,
) => ModelConnectionForEdit(
  id: item.id,
  name: item.name,
  modelId: item.providerId,
  workspaceId: workspaceId,
  hasKey: item.hasSecret,
  revision: item.revision,
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
