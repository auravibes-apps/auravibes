import 'package:auravibes_app/services/model_api_service.dart';
import 'package:auravibes_app/services/model_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('ModelSyncService', () {
    var repository = MockApiModelRepository();
    var apiService = MockModelApiService();
    var service = ModelSyncService(
      repository: repository,
      apiService: apiService,
    );

    setUp(() {
      repository = MockApiModelRepository();
      apiService = MockModelApiService();
      service = ModelSyncService(
        repository: repository,
        apiService: apiService,
      );
    });

    test('performFullSync syncs fetched models to repository', () async {
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

      await expectLater(service.performFullSync(), completes);

      verify(() => repository.deleteAllData()).called(1);
      verify(() => repository.batchUpsertProviders(any())).called(1);
      verify(() => repository.batchUpsertModels(any())).called(1);
    });

    test('performFullSync swallows fetch errors and skips sync', () async {
      when(
        () => apiService.fetchAllModels(),
      ).thenThrow(Exception('Network error'));

      await expectLater(service.performFullSync(), completes);

      final _ = verifyNever(() => repository.deleteAllData());
    });

    test('performFullSync swallows repository errors', () async {
      when(
        () => apiService.fetchAllModels(),
      ).thenAnswer((_) async => ModelApiResponse(providers: []));
      when(() => repository.deleteAllData()).thenThrow(Exception('DB error'));

      await expectLater(service.performFullSync(), completes);

      final _ = verifyNever(() => repository.batchUpsertProviders(any()));
    });
  });
}
