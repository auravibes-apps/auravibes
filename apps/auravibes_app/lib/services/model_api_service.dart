import 'package:auravibes_app/domain/entities/api_model.dart';
import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

/// Service for interacting with the models.dev API.
///
/// This service handles fetching model and provider data from the external API,
/// parsing responses, and handling network errors and retries.
class ModelApiService {
  ModelApiService({Dio? dio}) : _dio = dio ?? _createDefaultDio();

  /// Dio client for API requests
  final Dio _dio;

  /// Creates a default Dio instance with configuration
  static Dio _createDefaultDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://models.dev',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'AuraVibes-App/1.0',
        },
      ),
    );

    // Add retry interceptor
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
      ),
    );

    return dio;
  }

  /// Fetches all models and providers from the API.
  ///
  /// Returns a [ModelApiResponse] containing providers and models data.
  Future<ModelApiResponse> fetchAllModels() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api.json',
    );
    return _parseDioResponse(
      response,
    );
  }

  /// Gets API status and basic information.
  ///
  /// Returns a [ModelApiStatus] with API health information.
  Future<ModelApiStatus> getApiStatus() async {
    try {
      final startTime = DateTime.now();
      final response = await _dio.head<void>('/api.json');
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime);

      return ModelApiStatus(
        isAccessible: response.statusCode == 200,
        statusCode: response.statusCode,
        responseTime: responseTime,
        lastChecked: DateTime.now(),
      );
    } on Exception catch (e) {
      return ModelApiStatus(
        isAccessible: false,
        lastChecked: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Parses the Dio response into a ModelApiResponse.
  ///
  /// [response] The Dio response to parse.
  /// Returns a [ModelApiResponse] with the parsed data.
  ModelApiResponse _parseDioResponse(
    Response<Map<String, dynamic>> response,
  ) {
    if (response.statusCode != 200 || response.data == null) {
      throw Exception(
        'API request failed with status ${response.statusCode}',
      );
    }

    final jsonData = response.data!;

    // Parse providers
    final providersData = jsonData;

    final providers = providersData.entries
        .map((e) {
          return e.value as Map<String, dynamic>?;
        })
        .nonNulls
        .map(ApiProviderDto.fromJson)
        .toList();

    return ModelApiResponse(providers: providers);
  }

  /// Disposes the Dio client.
  void dispose() {
    _dio.close();
  }
}

/// Data class representing the API response.
class ModelApiResponse {
  ModelApiResponse({required this.providers});

  /// List of providers with their models
  final List<ApiProviderDto> providers;

  /// Gets all models from all providers
  List<ApiModelEntity> get allModels {
    return providers.expand((provider) => provider.models).toList();
  }

  /// Gets the total count of providers
  int get providerCount => providers.length;

  /// Gets the total count of models
  int get modelCount => allModels.length;
}

/// Data class representing an API provider.
class ApiProviderDto {
  ApiProviderDto({required this.modelProvider, required this.models});

  /// Creates an ApiProviderDto from JSON
  factory ApiProviderDto.fromJson(Map<String, dynamic> json) {
    final modelProvider = ApiModelProviderEntity.fromJson(json);
    final modelsData = json['models'] as Map<String, dynamic>? ?? {};

    final models = modelsData.entries
        .map(
          (e) {
            return e.value as Map<String, dynamic>?;
          },
        )
        .nonNulls
        .map((e) => ApiModelEntity.fromJson(modelProvider.id, e))
        .toList();

    return ApiProviderDto(
      modelProvider: modelProvider,
      models: models,
    );
  }

  final List<ApiModelEntity> models;

  /// Provider name
  final ApiModelProviderEntity modelProvider;
}

/// Data class representing API status information.
class ModelApiStatus {
  ModelApiStatus({
    required this.isAccessible,
    required this.lastChecked,
    this.statusCode,
    this.responseTime,
    this.error,
  });

  /// Whether the API is accessible
  final bool isAccessible;

  /// HTTP status code from the last check
  final int? statusCode;

  /// Response time from the last check
  final Duration? responseTime;

  /// When the status was last checked
  final DateTime lastChecked;

  /// Error message if the check failed
  final String? error;

  /// Returns a human-readable status message
  String get statusMessage {
    if (isAccessible) {
      final responseTimeMs = responseTime?.inMilliseconds ?? 0;
      return 'Accessible (${responseTimeMs}ms)';
    } else {
      return error ?? 'Unknown error';
    }
  }
}
