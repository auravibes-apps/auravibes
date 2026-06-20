import 'package:auravibes_app/features/models/usecases/sync_api_models_usecase.dart';
import 'package:auravibes_app/services/model_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../test_mocks.dart';

class _MockSyncApiModelsUseCase extends Mock implements SyncApiModelsUseCase {}

void main() {
  setUpAll(registerTestFallbackValues);

  group('ModelSyncService', () {
    var syncApiModelsUseCase = _MockSyncApiModelsUseCase();
    var service = ModelSyncService(
      syncApiModelsUseCase: syncApiModelsUseCase,
    );

    setUp(() {
      syncApiModelsUseCase = _MockSyncApiModelsUseCase();
      service = ModelSyncService(
        syncApiModelsUseCase: syncApiModelsUseCase,
      );
    });

    test('performFullSync delegates sync orchestration', () async {
      when(() => syncApiModelsUseCase()).thenAnswer(
        (_) => Future<void>.value(),
      );

      await expectLater(service.performFullSync(), completes);

      verify(() => syncApiModelsUseCase()).called(1);
    });

    test('performFullSync swallows sync errors', () async {
      when(() => syncApiModelsUseCase()).thenThrow(Exception('Network error'));

      await expectLater(service.performFullSync(), completes);

      verify(() => syncApiModelsUseCase()).called(1);
    });
  });
}
