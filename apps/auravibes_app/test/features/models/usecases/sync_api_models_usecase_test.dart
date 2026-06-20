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

    test('syncs fetched models to repository', () async {
      when(
        () => apiService.fetchAllModels(),
      ).thenAnswer((_) async => ModelApiResponse(providers: []));
      when(
        () => repository.replaceAllData(
          providers: any(named: 'providers'),
          models: any(named: 'models'),
        ),
      ).thenAnswer((_) => Future<void>.value());

      await expectLater(useCase(), completes);

      verify(
        () => repository.replaceAllData(
          providers: any(named: 'providers'),
          models: any(named: 'models'),
        ),
      ).called(1);
    });

    test('stops before repository writes when fetch fails', () async {
      when(
        () => apiService.fetchAllModels(),
      ).thenThrow(Exception('Network error'));

      await expectLater(useCase(), throwsA(isA<Exception>()));

      final _ = verifyNever(
        () => repository.replaceAllData(
          providers: any(named: 'providers'),
          models: any(named: 'models'),
        ),
      );
    });

    test('forwards atomic write failures', () async {
      when(
        () => apiService.fetchAllModels(),
      ).thenAnswer((_) async => ModelApiResponse(providers: []));
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
