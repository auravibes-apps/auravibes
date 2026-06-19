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

    test('performFullSync atomically replaces local data', () async {
      when(
        () => apiService.fetchAllModels(),
      ).thenAnswer((_) async => ModelApiResponse(providers: []));
      when(
        () => repository.replaceAllData(
          providers: any(named: 'providers'),
          models: any(named: 'models'),
        ),
      ).thenAnswer((_) => Future<void>.value());

      await expectLater(service.performFullSync(), completes);

      verify(
        () => repository.replaceAllData(
          providers: any(named: 'providers'),
          models: any(named: 'models'),
        ),
      ).called(1);
    });

    test('performFullSync swallows fetch errors and skips sync', () async {
      when(
        () => apiService.fetchAllModels(),
      ).thenThrow(Exception('Network error'));

      await expectLater(service.performFullSync(), completes);

      final _ = verifyNever(
        () => repository.replaceAllData(
          providers: any(named: 'providers'),
          models: any(named: 'models'),
        ),
      );
    });

    test('performFullSync swallows repository errors', () async {
      when(
        () => apiService.fetchAllModels(),
      ).thenAnswer((_) async => ModelApiResponse(providers: []));
      when(
        () => repository.replaceAllData(
          providers: any(named: 'providers'),
          models: any(named: 'models'),
        ),
      ).thenThrow(Exception('DB error'));

      await expectLater(service.performFullSync(), completes);
    });
  });
}
