// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.

import 'dart:io';

import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:dio/dio.dart';

/// Service for interacting with the models.dev API.
///
/// This service handles fetching model and provider data from the external API,
/// parsing responses, and handling network errors.
class ModelApiService {
  new({Dio? dio}) : _dio = dio ?? _createDefaultDio();

  /// Dio client for API requests.
  final Dio _dio;

  /// Fetches all models and providers from the API.
  ///
  /// Returns a [ModelApiResponse] containing providers and models data.
  Future<ModelApiResponse> fetchAllModels() async {
    final apiResponseFuture = _dio.get<Map<String, dynamic>>('/api.json');
    final canonicalModelIdsFuture = _fetchCanonicalModelIds();

    return _parseDioResponse(
      await apiResponseFuture,
      await canonicalModelIdsFuture,
    );
  }

  /// Disposes the Dio client.
  void dispose() {
    _dio.close();
  }

  /// Creates a default Dio instance with configuration.
  static Dio _createDefaultDio() {
    return Dio(
      .new(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        baseUrl: 'https://models.dev',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'AuraVibes-App/1.0',
        },
      ),
    );
  }

  Future<Set<String>> _fetchCanonicalModelIds() async {
    try {
      return _canonicalModelIds(
        await _dio.get<Map<String, dynamic>>('/models.json'),
      );
    } on Exception {
      return {};
    }
  }

  /// Parses the Dio response into a ModelApiResponse.
  ///
  /// [response] The Dio response to parse.
  /// Returns a [ModelApiResponse] with the parsed data.
  ModelApiResponse _parseDioResponse(
    Response<Map<String, dynamic>> response,
    Set<String> canonicalModelIds,
  ) {
    final jsonData = response.data;
    if (response.statusCode != HttpStatus.ok || jsonData == null) {
      throw Exception('API request failed with status ${response.statusCode}');
    }

    return _fromCatalog(.parse(jsonData, canonicalModelIds: canonicalModelIds));
  }
}

ModelApiResponse _fromCatalog(ModelsDevCatalogValue catalog) {
  final modelsByProvider = _modelsByProvider(catalog.models);

  return ModelApiResponse(
    providers: catalog.providers
        .map((provider) => _providerDto(provider, modelsByProvider))
        .toList(),
  );
}

Map<String, List<ApiModelEntity>> _modelsByProvider(
  List<ModelsDevModelValue> models,
) {
  final modelsByProvider = <String, List<ApiModelEntity>>{};
  for (final model in models) {
    modelsByProvider
        .putIfAbsent(model.providerId, () => [])
        .add(_modelEntity(model));
  }

  return modelsByProvider;
}

ApiModelEntity _modelEntity(ModelsDevModelValue model) {
  final base = _baseModelEntity(model);
  final withCosts = _modelCosts(base, model.capabilities);

  return _modelFlags(withCosts, model.capabilities);
}

ApiModelEntity _baseModelEntity(ModelsDevModelValue model) {
  final capabilities = model.capabilities;

  return .new(
    modelProvider: model.providerId,
    id: capabilities.id,
    name: capabilities.name,
    limitContext: capabilities.limitContext,
    limitOutput: capabilities.limitOutput,
    modalitiesInput: capabilities.inputModalities,
    modalitiesOutput: capabilities.outputModalities,
  );
}

ApiModelEntity _modelCosts(
  ApiModelEntity model,
  ModelCapabilities capabilities,
) => model.copyWith(
  family: capabilities.family,
  costInput: capabilities.costInput,
  costCacheRead: capabilities.costCacheRead,
  costOutput: capabilities.costOutput,
  openWeights: capabilities.openWeights,
);

ApiModelEntity _modelFlags(
  ApiModelEntity model,
  ModelCapabilities capabilities,
) => model.copyWith(
  supportsReasoning: capabilities.supportsReasoning,
  isCanonical: capabilities.isCanonical,
  supportsPriorityMode: capabilities.supportsPriorityMode,
  supportsToolCalls: capabilities.supportsToolCalls,
);

ApiProviderDto _providerDto(
  ModelsDevProviderValue provider,
  Map<String, List<ApiModelEntity>> modelsByProvider,
) => .new(
  modelProvider: _providerEntity(provider),
  models: modelsByProvider[provider.id] ?? const [],
);

ApiModelProviderEntity _providerEntity(ModelsDevProviderValue provider) =>
    .fromJson(_providerJson(provider));

Map<String, dynamic> _providerJson(ModelsDevProviderValue provider) => {
  'id': provider.id,
  'name': provider.name,
  'npm': provider.type,
  'api': provider.url,
  'doc': provider.documentationUrl,
};

Set<String> _canonicalModelIds(Response<Map<String, dynamic>> response) {
  final jsonData = response.data;
  if (response.statusCode != HttpStatus.ok || jsonData == null) return {};

  return jsonData.keys.toSet();
}

/// Data class representing the API response.
class ModelApiResponse({
  /// List of providers with their models.
  required final List<ApiProviderDto> providers,
}) {
  bool hasProvider(String id) =>
      providers.any((provider) => provider.modelProvider.id == id);
}

/// Data class representing an API provider.
class ApiProviderDto({
  /// Provider name.
  required final ApiModelProviderEntity modelProvider,
  required final List<ApiModelEntity> models,
}) {
  /// Creates an ApiProviderDto from JSON.
  factory fromJson(
    Map<String, dynamic> json, {
    required ApiModelProviderEntity modelProvider,
    Set<String> canonicalModelIds = const {},
  }) {
    final rawModelsData = json['models'];
    final modelsData = rawModelsData is Map<String, dynamic>
        ? rawModelsData
        : <String, dynamic>{};

    final models = _parseModels(modelsData, modelProvider, canonicalModelIds);

    return ApiProviderDto(modelProvider: modelProvider, models: models);
  }

  bool containsModel(String id) => models.any((model) => model.id == id);
}

List<ApiModelEntity> _parseModels(
  Map<String, dynamic> modelsData,
  ApiModelProviderEntity modelProvider,
  Set<String> canonicalModelIds,
) {
  final models = <ApiModelEntity>[];
  for (final modelJson in modelsData.values) {
    if (modelJson is! Map<String, dynamic>) continue;
    models.add(
      ApiModelEntity.fromJson(modelProvider.id, modelJson, canonicalModelIds),
    );
  }

  return models;
}
