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
      when(() => repository.deleteAllData()).thenAnswer((_) async => 0);
      when(
        () => repository.batchUpsertProviders(any()),
      ).thenAnswer((_) async => []);
      when(
        () => repository.batchUpsertModels(any()),
      ).thenAnswer((_) async => []);

      await expectLater(useCase(), completes);

      verify(() => repository.deleteAllData()).called(1);
      verify(() => repository.batchUpsertProviders(any())).called(1);
      verify(() => repository.batchUpsertModels(any())).called(1);
    });

    test('stops before repository writes when fetch fails', () async {
      when(
        () => apiService.fetchAllModels(),
      ).thenThrow(Exception('Network error'));

      await expectLater(useCase(), throwsA(isA<Exception>()));

      final _ = verifyNever(() => repository.deleteAllData());
    });

    test('stops remaining writes when repository delete fails', () async {
      when(
        () => apiService.fetchAllModels(),
      ).thenAnswer((_) async => ModelApiResponse(providers: []));
      when(() => repository.deleteAllData()).thenThrow(Exception('DB error'));

      await expectLater(useCase(), throwsA(isA<Exception>()));

      final _ = verifyNever(() => repository.batchUpsertProviders(any()));
    });
  });
}
