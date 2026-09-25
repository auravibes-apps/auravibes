import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/features/models/usecases/sync_api_models_usecase.dart';
import 'package:auravibes_app/services/model_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('SyncApiModelsUseCase', () {
    var repository = MockApiModelRepository();
    var apiService = MockModelApiService();
    var useCase = SyncApiModelsUseCase(
      repository: repository,
      apiService: apiService,
    );

    setUp(() {
      repository = MockApiModelRepository();
      apiService = MockModelApiService();
      useCase = SyncApiModelsUseCase(
        repository: repository,
        apiService: apiService,
      );
    });

    test('syncs usable models with an empty provider', () async {
      when(() => apiService.fetchAllModels())
          .thenAnswer((_) async => _validCatalogResponse());
      when(
        () => repository.replaceAllData(
          providers: any(named: 'providers'),
          models: any(named: 'models'),
        ),
      ).thenAnswer((_) => Future<void>.value());

      await expectLater(useCase(), completes);

      final [providers, models] = verify(
        () => repository.replaceAllData(
          providers: captureAny(named: 'providers'),
          models: captureAny(named: 'models'),
        ),
      ).captured;
      expect(providers, [_emptyProvider, _openAiProvider]);
      expect(models, [_model]);
    });

    test('rejects catalogs without providers before writing', () async {
      when(() => apiService.fetchAllModels())
          .thenAnswer((_) async => ModelApiResponse(providers: []));

      await expectLater(useCase(), throwsA(isA<FormatException>()));

      final _ = verifyNever(
        () => repository.replaceAllData(
          providers: any(named: 'providers'),
          models: any(named: 'models'),
        ),
      );
    });

    test('rejects provider-only catalogs before writing', () async {
      when(() => apiService.fetchAllModels()).thenAnswer(
        (_) async => ModelApiResponse(
          providers: [
            ApiProviderDto(modelProvider: _openAiProvider, models: const []),
          ],
        ),
      );

      await expectLater(useCase(), throwsA(isA<FormatException>()));

      final _ = verifyNever(
        () => repository.replaceAllData(
          providers: any(named: 'providers'),
          models: any(named: 'models'),
        ),
      );
    });

    test('stops before repository writes when fetch fails', () async {
      when(() => apiService.fetchAllModels())
          .thenThrow(Exception('Network error'));

      await expectLater(useCase(), throwsA(isA<Exception>()));

      final _ = verifyNever(
        () => repository.replaceAllData(
          providers: any(named: 'providers'),
          models: any(named: 'models'),
        ),
      );
    });

    test('forwards atomic write failures', () async {
      when(() => apiService.fetchAllModels())
          .thenAnswer((_) async => _validCatalogResponse());
      when(
        () => repository.replaceAllData(
          providers: any(named: 'providers'),
          models: any(named: 'models'),
        ),
      ).thenThrow(Exception('DB error'));

      await expectLater(useCase(), throwsA(isA<Exception>()));

      verify(
        () => repository.replaceAllData(
          providers: any(named: 'providers'),
          models: any(named: 'models'),
        ),
      ).called(1);
    });
  });
}

const _openAiProvider = ApiModelProviderEntity(
  id: 'openai',
  name: 'OpenAI',
  type: .openai,
);

const _emptyProvider = ApiModelProviderEntity(
  id: 'anthropic',
  name: 'Anthropic',
  type: .anthropic,
);

const _model = ApiModelEntity(
  modelProvider: 'openai',
  id: 'gpt-4',
  name: 'GPT-4',
  limitContext: 128000,
  limitOutput: 4096,
  modalitiesInput: [],
  modalitiesOutput: [],
);

ModelApiResponse _validCatalogResponse() => ModelApiResponse(
  providers: [
    ApiProviderDto(modelProvider: _emptyProvider, models: const []),
    ApiProviderDto(modelProvider: _openAiProvider, models: const [_model]),
  ],
);
