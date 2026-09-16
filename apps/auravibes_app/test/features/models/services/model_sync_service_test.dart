import 'dart:async';

import 'package:auravibes_app/features/models/services/model_sync_service.dart';
import 'package:auravibes_app/features/models/usecases/sync_api_models_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_mocks.dart';

class _MockSyncApiModelsUseCase extends Mock implements SyncApiModelsUseCase;

void main() {
  setUpAll(registerTestFallbackValues);

  group('ModelSyncService', () {
    var syncApiModelsUseCase = _MockSyncApiModelsUseCase();
    var service = ModelSyncService(syncApiModelsUseCase: syncApiModelsUseCase);

    setUp(() {
      syncApiModelsUseCase = _MockSyncApiModelsUseCase();
      service = ModelSyncService(syncApiModelsUseCase: syncApiModelsUseCase);
    });

    test('performFullSync delegates sync orchestration', () async {
      when(() => syncApiModelsUseCase())
          .thenAnswer((_) => Future<void>.value());

      await expectLater(service.performFullSync(), completes);

      verify(() => syncApiModelsUseCase()).called(1);
    });

    test('performFullSync swallows sync errors', () async {
      when(() => syncApiModelsUseCase()).thenThrow(Exception('Network error'));

      await expectLater(service.performFullSync(), completes);

      verify(() => syncApiModelsUseCase()).called(1);
    });

    test(
      'performManualSync forwards sync errors and permits a retry',
      () async {
        when(() => syncApiModelsUseCase())
            .thenThrow(Exception('Network error'));

        await expectLater(
          service.performManualSync(),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          service.performManualSync(),
          throwsA(isA<Exception>()),
        );

        verify(() => syncApiModelsUseCase()).called(2);
      },
    );

    test('performManualSync shares an in-flight request', () async {
      final completer = Completer<void>();
      when(() => syncApiModelsUseCase()).thenAnswer((_) => completer.future);

      final first = service.performManualSync();
      final second = service.performManualSync();

      await Future<void>.delayed(.zero);
      verify(() => syncApiModelsUseCase()).called(1);

      completer.complete();
      final _ = await Future.wait([first, second]);
    });
  });
}
