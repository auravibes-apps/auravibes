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
  ModelApiService({Dio? dio}) : _dio = dio ?? _createDefaultDio();

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
      BaseOptions(
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

    return _fromCatalog(
      ModelsDevCatalogValue.parse(
        jsonData,
        canonicalModelIds: canonicalModelIds,
      ),
    );
  }
}

ModelApiResponse _fromCatalog(ModelsDevCatalogValue catalog) {
  final modelsByProvider = <String, List<ApiModelEntity>>{};
  for (final model in catalog.models) {
    modelsByProvider
        .putIfAbsent(model.providerId, () => [])
        .add(
          ApiModelEntity(
            modelProvider: model.providerId,
            id: model.capabilities.id,
            name: model.capabilities.name,
            limitContext: model.capabilities.limitContext,
            limitOutput: model.capabilities.limitOutput,
            modalitiesInput: model.capabilities.inputModalities,
            modalitiesOutput: model.capabilities.outputModalities,
            family: model.capabilities.family,
            costInput: model.capabilities.costInput,
            costCacheRead: model.capabilities.costCacheRead,
            costOutput: model.capabilities.costOutput,
            openWeights: model.capabilities.openWeights,
            supportsReasoning: model.capabilities.supportsReasoning,
            isCanonical: model.capabilities.isCanonical,
            supportsPriorityMode: model.capabilities.supportsPriorityMode,
            supportsToolCalls: model.capabilities.supportsToolCalls,
          ),
        );
  }

  return ModelApiResponse(
    providers: [
      for (final provider in catalog.providers)
        ApiProviderDto(
          modelProvider: ApiModelProviderEntity.fromJson({
            'id': provider.id,
            'name': provider.name,
            'npm': provider.type,
            'api': provider.url,
            'doc': provider.documentationUrl,
          }),
          models: modelsByProvider[provider.id] ?? const [],
        ),
    ],
  );
}

Set<String> _canonicalModelIds(Response<Map<String, dynamic>> response) {
  final jsonData = response.data;
  if (response.statusCode != HttpStatus.ok || jsonData == null) return {};

  return jsonData.keys.toSet();
}

/// Data class representing the API response.
class ModelApiResponse {
  ModelApiResponse({required this.providers});

  /// List of providers with their models.
  final List<ApiProviderDto> providers;
}

/// Data class representing an API provider.
class ApiProviderDto {
  ApiProviderDto({required this.modelProvider, required this.models});

  /// Creates an ApiProviderDto from JSON.
  factory ApiProviderDto.fromJson(
    Map<String, dynamic> json, {
    required ApiModelProviderEntity modelProvider,
    Set<String> canonicalModelIds = const {},
  }) {
    final rawModelsData = json['models'];
    final modelsData = rawModelsData is Map<String, dynamic>
        ? rawModelsData
        : <String, dynamic>{};

    final models = modelsData.entries
        .map((e) {
          final modelJson = e.value;
          if (modelJson is! Map<String, dynamic>) {
            return null;
          }

          return modelJson;
        })
        .nonNulls
        .map(
          (e) =>
              ApiModelEntity.fromJson(modelProvider.id, e, canonicalModelIds),
        )
        .toList();

    return ApiProviderDto(modelProvider: modelProvider, models: models);
  }

  final List<ApiModelEntity> models;

  /// Provider name.
  final ApiModelProviderEntity modelProvider;
}
