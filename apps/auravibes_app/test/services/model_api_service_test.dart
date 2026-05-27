// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/services/model_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Dio _createDioWithResponse(Map<String, dynamic> data, {int statusCode = 200}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://models.dev'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (options, handler) => handler.resolve(
        Response(
          data: data,
          requestOptions: options.requestOptions,
          statusCode: statusCode,
        ),
      ),
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

Dio _createDioWithHeadResponse({int statusCode = 200}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://models.dev'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.method == 'HEAD') {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: statusCode,
            ),
          );
        } else {
          handler.next(options);
        }
      },
    ),
  );
  return dio;
}

Dio _createDioWithError() {
  final dio = Dio(BaseOptions(baseUrl: 'https://models.dev'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: Exception('Connection refused'),
        ),
      ),
    ),
  );
  return dio;
}

void main() {
  group('ModelApiService', () {
    late Dio dio;
    late ModelApiService service;

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

    group('ModelApiResponse', () {
      test('allModels returns models from all providers', () {
        final response = ModelApiResponse(
          providers: [
            ApiProviderDto(
              modelProvider: const ApiModelProviderEntity(
                id: 'openai',
                name: 'OpenAI',
                type: ModelProvidersType.openai,
              ),
              models: [
                const ApiModelEntity(
                  modelProvider: 'openai',
                  id: 'gpt-4',
                  name: 'GPT-4',
                  limitContext: 128000,
                  limitOutput: 4096,
                  modalitiesInput: [],
                  modalitiesOuput: [],
                ),
              ],
            ),
            ApiProviderDto(
              modelProvider: const ApiModelProviderEntity(
                id: 'anthropic',
                name: 'Anthropic',
                type: ModelProvidersType.anthropic,
              ),
              models: [
                const ApiModelEntity(
                  modelProvider: 'anthropic',
                  id: 'claude-3',
                  name: 'Claude 3',
                  limitContext: 200000,
                  limitOutput: 4096,
                  modalitiesInput: [],
                  modalitiesOuput: [],
                ),
              ],
            ),
          ],
        );

        expect(response.allModels, hasLength(2));
        expect(response.allModels.first.id, 'gpt-4');
        expect(response.allModels[1].id, 'claude-3');
      });

      test('providerCount returns correct count', () {
        final response = ModelApiResponse(
          providers: [
            ApiProviderDto(
              modelProvider: const ApiModelProviderEntity(
                id: 'openai',
                name: 'OpenAI',
                type: null,
              ),
              models: [],
            ),
            ApiProviderDto(
              modelProvider: const ApiModelProviderEntity(
                id: 'anthropic',
                name: 'Anthropic',
                type: null,
              ),
              models: [],
            ),
          ],
        );

        expect(response.providerCount, 2);
      });

      test('modelCount returns total models', () {
        final response = ModelApiResponse(
          providers: [
            ApiProviderDto(
              modelProvider: const ApiModelProviderEntity(
                id: 'openai',
                name: 'OpenAI',
                type: null,
              ),
              models: [
                const ApiModelEntity(
                  modelProvider: 'openai',
                  id: 'gpt-4',
                  name: 'GPT-4',
                  limitContext: 128000,
                  limitOutput: 4096,
                  modalitiesInput: [],
                  modalitiesOuput: [],
                ),
                const ApiModelEntity(
                  modelProvider: 'openai',
                  id: 'gpt-3.5',
                  name: 'GPT-3.5',
                  limitContext: 16000,
                  limitOutput: 4096,
                  modalitiesInput: [],
                  modalitiesOuput: [],
                ),
              ],
            ),
          ],
        );

        expect(response.modelCount, 2);
      });

      test('empty providers returns empty models', () {
        final response = ModelApiResponse(providers: []);

        expect(response.allModels, isEmpty);
        expect(response.providerCount, 0);
        expect(response.modelCount, 0);
      });
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

        final dto = ApiProviderDto.fromJson(json);

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

        final dto = ApiProviderDto.fromJson(json);

        expect(dto.models, isEmpty);
      });

      test('fromJson handles missing models key', () {
        final json = <String, dynamic>{
          'id': 'test',
          'name': 'Test',
        };

        final dto = ApiProviderDto.fromJson(json);

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

        final dto = ApiProviderDto.fromJson(json);
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

        final dto = ApiProviderDto.fromJson(json);
        expect(dto.models, hasLength(2));
      });
    });

    group('ModelApiStatus', () {
      test('statusMessage returns accessible with response time', () {
        final status = ModelApiStatus(
          isAccessible: true,
          lastChecked: DateTime(2025),
          statusCode: 200,
          responseTime: const Duration(milliseconds: 150),
        );

        expect(status.statusMessage, 'Accessible (150ms)');
      });

      test('statusMessage returns accessible with zero response time', () {
        final status = ModelApiStatus(
          isAccessible: true,
          lastChecked: DateTime(2025),
        );

        expect(status.statusMessage, 'Accessible (0ms)');
      });

      test('statusMessage returns error message when not accessible', () {
        final status = ModelApiStatus(
          isAccessible: false,
          lastChecked: DateTime(2025),
          error: 'Connection refused',
        );

        expect(status.statusMessage, 'Connection refused');
      });

      test('statusMessage returns unknown error when no error message', () {
        final status = ModelApiStatus(
          isAccessible: false,
          lastChecked: DateTime(2025),
        );

        expect(status.statusMessage, 'Unknown error');
      });

      test('statusCode is stored correctly', () {
        final status = ModelApiStatus(
          isAccessible: true,
          lastChecked: DateTime(2025),
          statusCode: 200,
        );
        expect(status.statusCode, 200);
      });

      test('error is stored correctly', () {
        final status = ModelApiStatus(
          isAccessible: false,
          lastChecked: DateTime(2025),
          error: 'timeout',
        );
        expect(status.error, 'timeout');
      });

      test('responseTime is stored correctly', () {
        final status = ModelApiStatus(
          isAccessible: true,
          lastChecked: DateTime(2025),
          responseTime: const Duration(milliseconds: 250),
        );
        expect(status.responseTime, const Duration(milliseconds: 250));
      });

      test('lastChecked is stored correctly', () {
        final now = DateTime(2025, 6, 15);
        final status = ModelApiStatus(
          isAccessible: true,
          lastChecked: now,
        );
        expect(status.lastChecked, now);
      });
    });

    group('fetchAllModels', () {
      test('parses successful response with providers', () async {
        final dio = _createDioWithResponse({
          'openai': <String, dynamic>{
            'id': 'openai',
            'name': 'OpenAI',
            'models': <String, dynamic>{},
          },
        });
        final service = ModelApiService(dio: dio);

        final result = await service.fetchAllModels();
        expect(result.providers, hasLength(1));
        expect(result.providers.first.modelProvider.id, 'openai');

        dio.close();
      });

      test('parses response with multiple providers and models', () async {
        final dio = _createDioWithResponse({
          'openai': <String, dynamic>{
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
            },
          },
          'anthropic': <String, dynamic>{
            'id': 'anthropic',
            'name': 'Anthropic',
            'models': <String, dynamic>{},
          },
        });
        final service = ModelApiService(dio: dio);

        final result = await service.fetchAllModels();
        expect(result.providers, hasLength(2));
        expect(result.modelCount, 1);
        expect(result.providerCount, 2);

        dio.close();
      });

      test('throws on non-200 status code', () async {
        final dio = _createDioWithNon200();
        final service = ModelApiService(dio: dio);

        expect(
          service.fetchAllModels,
          throwsA(isA<Exception>()),
        );

        dio.close();
      });

      test('throws on null data', () async {
        final dio = _createDioWithNullData();
        final service = ModelApiService(dio: dio);

        expect(
          service.fetchAllModels,
          throwsA(isA<Exception>()),
        );

        dio.close();
      });

      test('throws on 404 status code', () async {
        final dio = _createDioWithNon200(statusCode: 404);
        final service = ModelApiService(dio: dio);

        expect(
          service.fetchAllModels,
          throwsA(isA<Exception>()),
        );

        dio.close();
      });
    });

    group('getApiStatus', () {
      test('returns accessible on 200', () async {
        final dio = _createDioWithHeadResponse();
        final service = ModelApiService(dio: dio);

        final status = await service.getApiStatus();
        expect(status.isAccessible, isTrue);
        expect(status.statusCode, 200);

        dio.close();
      });

      test('returns not accessible on non-200', () async {
        final dio = _createDioWithHeadResponse(statusCode: 503);
        final service = ModelApiService(dio: dio);

        final status = await service.getApiStatus();
        expect(status.isAccessible, isFalse);
        expect(status.statusCode, 503);

        dio.close();
      });

      test('returns not accessible on connection error', () async {
        final dio = _createDioWithError();
        final service = ModelApiService(dio: dio);

        final status = await service.getApiStatus();
        expect(status.isAccessible, isFalse);
        expect(status.error, isNotNull);
        expect(status.statusCode, isNull);

        dio.close();
      });

      test('responseTime is set on success', () async {
        final dio = _createDioWithHeadResponse();
        final service = ModelApiService(dio: dio);

        final status = await service.getApiStatus();
        expect(status.responseTime, isNotNull);
        expect(status.responseTime!.inMilliseconds, greaterThanOrEqualTo(0));

        dio.close();
      });

      test('lastChecked is set on success', () async {
        final dio = _createDioWithHeadResponse();
        final service = ModelApiService(dio: dio);

        final status = await service.getApiStatus();
        expect(status.lastChecked, isNotNull);

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

    group('ModelApiResponse additional', () {
      test('allModels flattens across providers correctly', () {
        final response = ModelApiResponse(
          providers: [
            ApiProviderDto(
              modelProvider: const ApiModelProviderEntity(
                id: 'a',
                name: 'A',
                type: null,
              ),
              models: [
                const ApiModelEntity(
                  modelProvider: 'a',
                  id: 'm1',
                  name: 'M1',
                  limitContext: 1,
                  limitOutput: 1,
                  modalitiesInput: [],
                  modalitiesOuput: [],
                ),
                const ApiModelEntity(
                  modelProvider: 'a',
                  id: 'm2',
                  name: 'M2',
                  limitContext: 1,
                  limitOutput: 1,
                  modalitiesInput: [],
                  modalitiesOuput: [],
                ),
              ],
            ),
            ApiProviderDto(
              modelProvider: const ApiModelProviderEntity(
                id: 'b',
                name: 'B',
                type: null,
              ),
              models: [
                const ApiModelEntity(
                  modelProvider: 'b',
                  id: 'm3',
                  name: 'M3',
                  limitContext: 1,
                  limitOutput: 1,
                  modalitiesInput: [],
                  modalitiesOuput: [],
                ),
              ],
            ),
          ],
        );

        expect(response.allModels, hasLength(3));
        expect(response.modelCount, 3);
        expect(response.providerCount, 2);
      });
    });
  });
}
