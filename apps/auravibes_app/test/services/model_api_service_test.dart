// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/services/model_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Dio _createDioWithEndpointResponses({
  required Map<String, dynamic> apiData,
  Map<String, dynamic> modelsData = const {},
  int apiStatusCode = 200,
  int modelsStatusCode = 200,
  bool failModels = false,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://models.dev'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path == '/api.json') {
          handler.resolve(
            Response(
              data: apiData,
              requestOptions: options,
              statusCode: apiStatusCode,
            ),
          );

          return;
        }
        if (options.path == '/models.json') {
          if (failModels) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: modelsStatusCode,
                ),
                type: DioExceptionType.badResponse,
              ),
            );

            return;
          }
          handler.resolve(
            Response(
              data: modelsData,
              requestOptions: options,
              statusCode: modelsStatusCode,
            ),
          );

          return;
        }
        handler.next(options);
      },
    ),
  );

  return dio;
}

Dio _createDioWithNullData({int statusCode = 200}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://models.dev'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (options, handler) => handler.resolve(
        Response(
          requestOptions: options.requestOptions,
          statusCode: statusCode,
        ),
      ),
    ),
  );

  return dio;
}

Dio _createDioWithNon200({int statusCode = 500}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://models.dev'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (options, handler) => handler.resolve(
        Response(
          data: {'error': 'fail'},
          requestOptions: options.requestOptions,
          statusCode: statusCode,
        ),
      ),
    ),
  );

  return dio;
}

ApiProviderDto _providerDtoFromJson(Map<String, dynamic> json) {
  return ApiProviderDto.fromJson(
    json,
    modelProvider: ApiModelProviderEntity.fromJson(json),
  );
}

void main() {
  group('ModelApiService', () {
    var dio = Dio(BaseOptions(baseUrl: 'https://models.dev'));
    var service = ModelApiService(dio: dio);

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://models.dev'));
      service = ModelApiService(dio: dio);
    });

    tearDown(() {
      service.dispose();
    });

    test('creates default Dio when none provided', () {
      final defaultService = ModelApiService();
      expect(defaultService, isNotNull);
      defaultService.dispose();
    });

    test('creates with custom Dio', () {
      final customDio = Dio(BaseOptions(baseUrl: 'https://custom.api'));
      final customService = ModelApiService(dio: customDio);
      expect(customService, isNotNull);
      customService.dispose();
    });

    group('ApiProviderDto', () {
      test('fromJson parses provider with models', () {
        final json = <String, dynamic>{
          'id': 'openai',
          'name': 'OpenAI',
          'npm': '@ai-sdk/openai-compatible',
          'api': 'https://api.openai.com/v1',
          'models': <String, dynamic>{
            'gpt-4': <String, dynamic>{
              'id': 'gpt-4',
              'name': 'GPT-4',
              'limit': <String, dynamic>{
                'context': 128000,
                'output': 4096,
              },
              'modalities': <String, dynamic>{
                'input': ['text'],
                'output': ['text'],
              },
            },
          },
        };

        final dto = _providerDtoFromJson(json);

        expect(dto.modelProvider.id, 'openai');
        expect(dto.modelProvider.name, 'OpenAI');
        expect(dto.models, hasLength(1));
        expect(dto.models.first.id, 'gpt-4');
      });

      test('fromJson handles empty models', () {
        final json = <String, dynamic>{
          'id': 'test',
          'name': 'Test',
          'models': <String, dynamic>{},
        };

        final dto = _providerDtoFromJson(json);

        expect(dto.models, isEmpty);
      });

      test('fromJson handles missing models key', () {
        final json = <String, dynamic>{
          'id': 'test',
          'name': 'Test',
        };

        final dto = _providerDtoFromJson(json);

        expect(dto.models, isEmpty);
      });

      test('fromJson skips null model entries', () {
        final json = <String, dynamic>{
          'id': 'test',
          'name': 'Test',
          'models': <String, dynamic>{
            'model-a': null,
            'model-b': <String, dynamic>{
              'id': 'model-b',
              'name': 'Model B',
              'limit': <String, dynamic>{
                'context': 128000,
                'output': 4096,
              },
              'modalities': <String, dynamic>{
                'input': ['text'],
                'output': ['text'],
              },
            },
          },
        };

        final dto = _providerDtoFromJson(json);
        expect(dto.models, hasLength(1));
        expect(dto.models.first.id, 'model-b');
      });

      test('fromJson with multiple models', () {
        final json = <String, dynamic>{
          'id': 'openai',
          'name': 'OpenAI',
          'models': <String, dynamic>{
            'gpt-4': <String, dynamic>{
              'id': 'gpt-4',
              'name': 'GPT-4',
              'limit': <String, dynamic>{'context': 128000, 'output': 4096},
              'modalities': <String, dynamic>{
                'input': ['text'],
                'output': ['text'],
              },
            },
            'gpt-3.5': <String, dynamic>{
              'id': 'gpt-3.5',
              'name': 'GPT-3.5',
              'limit': <String, dynamic>{'context': 16000, 'output': 4096},
              'modalities': <String, dynamic>{
                'input': ['text'],
                'output': ['text'],
              },
            },
          },
        };

        final dto = _providerDtoFromJson(json);
        expect(dto.models, hasLength(2));
      });
    });

    group('fetchAllModels', () {
      test('parses successful response with providers', () async {
        final dio = _createDioWithEndpointResponses(
          apiData: {
            'openai': <String, dynamic>{
              'id': 'openai',
              'name': 'OpenAI',
              'npm': '@ai-sdk/openai-compatible',
              'models': <String, dynamic>{},
            },
          },
        );
        final service = ModelApiService(dio: dio);

        final result = await service.fetchAllModels();
        expect(result.providers, hasLength(1));
        expect(result.providers.first.modelProvider.id, 'openai');

        dio.close();
      });

      test('parses response with multiple providers and models', () async {
        final dio = _createDioWithEndpointResponses(
          apiData: {
            'openai': <String, dynamic>{
              'id': 'openai',
              'name': 'OpenAI',
              'npm': '@ai-sdk/openai-compatible',
              'models': <String, dynamic>{
                'gpt-4': <String, dynamic>{
                  'id': 'gpt-4',
                  'name': 'GPT-4',
                  'limit': <String, dynamic>{
                    'context': 128000,
                    'output': 4096,
                  },
                  'modalities': <String, dynamic>{
                    'input': ['text'],
                    'output': ['text'],
                  },
                },
              },
            },
            'anthropic': <String, dynamic>{
              'id': 'anthropic',
              'name': 'Anthropic',
              'npm': '@ai-sdk/anthropic',
              'models': <String, dynamic>{},
            },
          },
          modelsData: {'openai/gpt-4': <String, dynamic>{}},
        );
        final service = ModelApiService(dio: dio);

        final result = await service.fetchAllModels();
        expect(result.providers, hasLength(2));
        final openai = result.providers.firstWhere(
          (p) => p.modelProvider.id == 'openai',
        );
        expect(openai.models, hasLength(1));
        expect(openai.models.single.isCanonical, isTrue);

        dio.close();
      });

      test('continues when models enrichment fails', () async {
        final dio = _createDioWithEndpointResponses(
          apiData: {
            'openai': <String, dynamic>{
              'id': 'openai',
              'name': 'OpenAI',
              'npm': '@ai-sdk/openai-compatible',
              'models': <String, dynamic>{
                'gpt-4': <String, dynamic>{
                  'id': 'gpt-4',
                  'name': 'GPT-4',
                  'limit': <String, dynamic>{
                    'context': 128000,
                    'output': 4096,
                  },
                  'modalities': <String, dynamic>{
                    'input': ['text'],
                    'output': ['text'],
                  },
                },
              },
            },
          },
          modelsStatusCode: 500,
          failModels: true,
        );
        final service = ModelApiService(dio: dio);

        final result = await service.fetchAllModels();

        expect(result.providers, hasLength(1));
        final models = result.providers.expand((p) => p.models);
        expect(models.single.isCanonical, isTrue);

        dio.close();
      });

      test('skips non-map provider entries', () async {
        final dio = _createDioWithEndpointResponses(
          apiData: {
            'openai': <String, dynamic>{
              'id': 'openai',
              'name': 'OpenAI',
              'npm': '@ai-sdk/openai-compatible',
              'models': <String, dynamic>{},
            },
            'bad': 'unexpected-shape',
          },
        );
        final service = ModelApiService(dio: dio);

        final result = await service.fetchAllModels();

        expect(result.providers, hasLength(1));
        expect(result.providers.single.modelProvider.id, 'openai');

        dio.close();
      });

      test('stores unsupported providers and their models', () async {
        final dio = _createDioWithEndpointResponses(
          apiData: {
            'openrouter': <String, dynamic>{
              'id': 'openrouter',
              'name': 'OpenRouter',
              'npm': '@openrouter/ai-sdk-provider',
              'models': <String, dynamic>{
                'anthropic/claude-sonnet-4': <String, dynamic>{
                  'id': 'anthropic/claude-sonnet-4',
                  'name': 'Claude Sonnet 4',
                  'limit': <String, dynamic>{
                    'context': 200000,
                    'output': 64000,
                  },
                  'modalities': <String, dynamic>{
                    'input': ['text'],
                    'output': ['text'],
                  },
                },
              },
            },
            'gateway': <String, dynamic>{
              'id': 'gateway',
              'name': 'Gateway',
              'npm': '@ai-sdk/gateway',
              'models': <String, dynamic>{
                'unsupported-model': <String, dynamic>{
                  'id': 'unsupported-model',
                  'name': 'Unsupported Model',
                  'limit': <String, dynamic>{'context': 1, 'output': 1},
                  'modalities': <String, dynamic>{
                    'input': ['text'],
                    'output': ['text'],
                  },
                },
              },
            },
          },
        );
        final service = ModelApiService(dio: dio);

        final result = await service.fetchAllModels();

        expect(result.providers, hasLength(2));
        expect(
          result.providers.map((p) => p.modelProvider.id),
          containsAll(['openrouter', 'gateway']),
        );
        final models = result.providers.expand((p) => p.models).toList();
        expect(models, hasLength(2));
        expect(
          models.map((m) => m.modelProvider),
          containsAll(['openrouter', 'gateway']),
        );

        dio.close();
      });

      test('skips invalid model entries while storing provider', () async {
        final dio = _createDioWithEndpointResponses(
          apiData: {
            'gateway': <String, dynamic>{
              'id': 'gateway',
              'name': 'Gateway',
              'npm': '@ai-sdk/gateway',
              'models': 'unexpected-shape',
            },
          },
        );
        final service = ModelApiService(dio: dio);

        final result = await service.fetchAllModels();

        expect(result.providers, hasLength(1));
        expect(result.providers.single.modelProvider.id, 'gateway');
        expect(result.providers.expand((p) => p.models), isEmpty);

        dio.close();
      });

      test('throws on non-200 status code', () {
        final dio = _createDioWithNon200();
        final service = ModelApiService(dio: dio);

        expect(
          service.fetchAllModels,
          throwsA(isA<Exception>()),
        );

        dio.close();
      });

      test('throws on null data', () {
        final dio = _createDioWithNullData();
        final service = ModelApiService(dio: dio);

        expect(
          service.fetchAllModels,
          throwsA(isA<Exception>()),
        );

        dio.close();
      });

      test('throws on 404 status code', () {
        final dio = _createDioWithNon200(statusCode: 404);
        final service = ModelApiService(dio: dio);

        expect(
          service.fetchAllModels,
          throwsA(isA<Exception>()),
        );

        dio.close();
      });
    });

    test('dispose closes dio', () {
      expect(() => service.dispose(), returnsNormally);
    });

    test('dispose can be called multiple times', () {
      service.dispose();
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
