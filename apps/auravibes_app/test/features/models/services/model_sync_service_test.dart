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

    test('sync delegates to the use case', () async {
      when(() => syncApiModelsUseCase())
          .thenAnswer((_) => Future<void>.value());

      await expectLater(service.sync(), completes);

      verify(() => syncApiModelsUseCase()).called(1);
    });

    test('sync forwards errors and permits a later retry', () async {
      var attempts = 0;
      when(() => syncApiModelsUseCase()).thenAnswer((_) async {
        if (attempts++ == 0) throw Exception('Network error');
      });

      await expectLater(service.sync(), throwsA(isA<Exception>()));
      await expectLater(service.sync(), completes);

      verify(() => syncApiModelsUseCase()).called(2);
    });

    test('sync shares an in-flight request', () async {
      final completer = Completer<void>();
      when(() => syncApiModelsUseCase()).thenAnswer((_) => completer.future);

      final first = service.sync();
      final second = service.sync();

      await Future<void>.delayed(.zero);
      verify(() => syncApiModelsUseCase()).called(1);

      completer.complete();
      final _ = await Future.wait([first, second]);
    });
  });
}
