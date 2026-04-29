import 'package:auravibes_app/domain/repositories/api_model_repository.dart';
import 'package:auravibes_app/services/model_api_service.dart';
import 'package:auravibes_app/services/model_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'model_sync_service_test.mocks.dart';

@GenerateMocks([ApiModelRepository, ModelApiService])
void main() {
  group('ModelSyncResult', () {
    test('totalChanges sums all change counts', () {
      final result = ModelSyncResult(
        isSuccess: true,
        providersAdded: 2,
        providersUpdated: 1,
        providersRemoved: 1,
        modelsAdded: 5,
        modelsUpdated: 3,
        modelsRemoved: 2,
      );

      expect(result.totalChanges, 14);
    });

    test('totalChanges is zero when no changes', () {
      final result = ModelSyncResult(isSuccess: true);

      expect(result.totalChanges, 0);
    });

    test('summary returns failure message when not successful', () {
      final result = ModelSyncResult(
        isSuccess: false,
        errors: ['API error', 'Timeout'],
      );

      expect(result.summary, 'Synchronization failed with 2 errors');
    });

    test('summary returns no changes when successful with no changes', () {
      final result = ModelSyncResult(isSuccess: true);

      expect(result.summary, 'No changes needed');
    });

    test('summary includes providers added', () {
      final result = ModelSyncResult(
        isSuccess: true,
        providersAdded: 3,
      );

      expect(result.summary, contains('3 providers added'));
    });

    test('summary includes models added', () {
      final result = ModelSyncResult(
        isSuccess: true,
        modelsAdded: 10,
      );

      expect(result.summary, contains('10 models added'));
    });

    test('summary includes duration when present', () {
      final result = ModelSyncResult(
        isSuccess: true,
        modelsAdded: 1,
        duration: const Duration(seconds: 5),
      );

      expect(result.summary, contains('in 5s'));
    });

    test('summary combines multiple change types', () {
      final result = ModelSyncResult(
        isSuccess: true,
        providersAdded: 2,
        modelsAdded: 5,
        modelsRemoved: 1,
      );

      final summary = result.summary;
      expect(summary, contains('2 providers added'));
      expect(summary, contains('5 models added'));
      expect(summary, contains('1 models removed'));
    });

    test('copyWith preserves unchanged values', () {
      final result = ModelSyncResult(
        isSuccess: true,
        providersAdded: 3,
        modelsAdded: 5,
        duration: const Duration(seconds: 10),
      );

      final copy = result.copyWith(modelsAdded: 10);

      expect(copy.isSuccess, true);
      expect(copy.providersAdded, 3);
      expect(copy.modelsAdded, 10);
      expect(copy.duration, const Duration(seconds: 10));
    });

    test('copyWith overrides specified values', () {
      final result = ModelSyncResult(
        isSuccess: true,
        providersAdded: 3,
      );

      final copy = result.copyWith(
        isSuccess: false,
        providersAdded: 0,
        errors: ['Failed'],
      );

      expect(copy.isSuccess, false);
      expect(copy.providersAdded, 0);
      expect(copy.errors, ['Failed']);
    });

    test('defaults are correct', () {
      final result = ModelSyncResult(isSuccess: true);

      expect(result.fullSync, false);
      expect(result.providersAdded, 0);
      expect(result.providersUpdated, 0);
      expect(result.providersRemoved, 0);
      expect(result.modelsAdded, 0);
      expect(result.modelsUpdated, 0);
      expect(result.modelsRemoved, 0);
      expect(result.errors, isEmpty);
      expect(result.duration, isNull);
    });
  });

  group('ModelSyncValidation', () {
    test('totalDiscrepancies sums all discrepancy counts', () {
      final validation = ModelSyncValidation(
        isValid: false,
        missingProviderIds: ['p1', 'p2'],
        extraProviderIds: ['p3'],
        missingModelIds: ['m1', 'm2', 'm3'],
        extraModelIds: ['m4'],
      );

      expect(validation.totalDiscrepancies, 7);
    });

    test('totalDiscrepancies is zero when valid', () {
      final validation = ModelSyncValidation(isValid: true);

      expect(validation.totalDiscrepancies, 0);
    });

    test('summary returns valid when valid', () {
      final validation = ModelSyncValidation(isValid: true);

      expect(validation.summary, 'Sync state is valid');
    });

    test('summary returns error message when error present', () {
      final validation = ModelSyncValidation(
        isValid: false,
        error: 'Network failure',
      );

      expect(validation.summary, 'Validation failed: Network failure');
    });

    test('summary lists discrepancies', () {
      final validation = ModelSyncValidation(
        isValid: false,
        missingProviderIds: ['p1'],
        extraModelIds: ['m1', 'm2'],
      );

      final summary = validation.summary;
      expect(summary, contains('1 missing providers'));
      expect(summary, contains('2 extra models'));
    });

    test('defaults are correct', () {
      final validation = ModelSyncValidation(isValid: true);

      expect(validation.missingProviderIds, isEmpty);
      expect(validation.extraProviderIds, isEmpty);
      expect(validation.missingModelIds, isEmpty);
      expect(validation.extraModelIds, isEmpty);
      expect(validation.apiStatus, isNull);
      expect(validation.error, isNull);
    });
  });

  group('ModelSyncStatus', () {
    test('isHealthy when accessible and no error', () {
      final status = ModelSyncStatus(
        localProviderCount: 5,
        localModelCount: 50,
        isApiAccessible: true,
        lastApiCheck: DateTime(2025),
        apiStatus: 'OK',
      );

      expect(status.isHealthy, true);
    });

    test('isHealthy false when not accessible', () {
      final status = ModelSyncStatus(
        localProviderCount: 5,
        localModelCount: 50,
        isApiAccessible: false,
        lastApiCheck: DateTime(2025),
        apiStatus: 'Down',
      );

      expect(status.isHealthy, false);
    });

    test('isHealthy false when error present', () {
      final status = ModelSyncStatus(
        localProviderCount: 5,
        localModelCount: 50,
        isApiAccessible: true,
        lastApiCheck: DateTime(2025),
        apiStatus: 'OK',
        error: 'Something wrong',
      );

      expect(status.isHealthy, false);
    });

    test('summary returns healthy message', () {
      final status = ModelSyncStatus(
        localProviderCount: 3,
        localModelCount: 25,
        isApiAccessible: true,
        lastApiCheck: DateTime(2025),
        apiStatus: 'OK',
      );

      expect(status.summary, contains('3 providers'));
      expect(status.summary, contains('25 models'));
      expect(status.summary, contains('API accessible'));
    });

    test('summary returns unhealthy message when not accessible', () {
      final status = ModelSyncStatus(
        localProviderCount: 0,
        localModelCount: 0,
        isApiAccessible: false,
        lastApiCheck: DateTime(2025),
        apiStatus: 'Down',
      );

      expect(status.summary, contains('API not accessible'));
    });

    test('summary returns unhealthy message with error', () {
      final status = ModelSyncStatus(
        localProviderCount: 0,
        localModelCount: 0,
        isApiAccessible: true,
        lastApiCheck: DateTime(2025),
        apiStatus: 'OK',
        error: 'Timeout',
      );

      expect(status.summary, contains('Timeout'));
    });
  });

  group('ModelSyncResult summary', () {
    test('summary includes providersUpdated', () {
      final result = ModelSyncResult(
        isSuccess: true,
        providersUpdated: 2,
      );
      expect(result.summary, contains('2 providers updated'));
    });

    test('summary includes providersRemoved', () {
      final result = ModelSyncResult(
        isSuccess: true,
        providersRemoved: 1,
      );
      expect(result.summary, contains('1 providers removed'));
    });

    test('summary includes modelsUpdated', () {
      final result = ModelSyncResult(
        isSuccess: true,
        modelsUpdated: 3,
      );
      expect(result.summary, contains('3 models updated'));
    });

    test('summary includes modelsRemoved', () {
      final result = ModelSyncResult(
        isSuccess: true,
        modelsRemoved: 4,
      );
      expect(result.summary, contains('4 models removed'));
    });

    test('summary omits duration when null', () {
      final result = ModelSyncResult(
        isSuccess: true,
        modelsAdded: 1,
      );
      expect(result.summary, isNot(contains('in')));
    });
  });

  group('ModelSyncValidation summary', () {
    test('summary includes extra providers', () {
      final validation = ModelSyncValidation(
        isValid: false,
        extraProviderIds: ['p1'],
      );
      expect(validation.summary, contains('1 extra providers'));
    });

    test('summary includes missing models', () {
      final validation = ModelSyncValidation(
        isValid: false,
        missingModelIds: ['m1'],
      );
      expect(validation.summary, contains('1 missing models'));
    });

    test('summary includes all discrepancy types', () {
      final validation = ModelSyncValidation(
        isValid: false,
        missingProviderIds: ['p1'],
        extraProviderIds: ['p2'],
        missingModelIds: ['m1'],
        extraModelIds: ['m2'],
      );
      final summary = validation.summary;
      expect(summary, contains('1 missing providers'));
      expect(summary, contains('1 extra providers'));
      expect(summary, contains('1 missing models'));
      expect(summary, contains('1 extra models'));
    });
  });

  group('ModelSyncService', () {
    late MockApiModelRepository repository;
    late MockModelApiService apiService;
    late ModelSyncService service;

    setUp(() {
      repository = MockApiModelRepository();
      apiService = MockModelApiService();
      service = ModelSyncService(
        repository: repository,
        apiService: apiService,
      );
    });

    test('performFullSync returns failure when API not accessible', () async {
      when(apiService.getApiStatus()).thenAnswer(
        (_) async => ModelApiStatus(
          isAccessible: false,
          lastChecked: DateTime(2026),
          error: 'Service down',
        ),
      );

      final result = await service.performFullSync();

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('not accessible'));
    });

    test('performFullSync returns failure on exception', () async {
      when(apiService.getApiStatus()).thenThrow(Exception('Network error'));

      final result = await service.performFullSync();

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('Full sync pre-check failed'));
    });

    test('performFullSync succeeds with accessible API', () async {
      when(apiService.getApiStatus()).thenAnswer(
        (_) async => ModelApiStatus(
          isAccessible: true,
          lastChecked: DateTime(2026),
        ),
      );
      when(apiService.fetchAllModels()).thenAnswer(
        (_) async => ModelApiResponse(providers: []),
      );
      when(repository.getAllProviders()).thenAnswer((_) async => []);
      when(repository.getAllModels()).thenAnswer((_) async => []);
      when(repository.deleteAllData()).thenAnswer((_) async => 0);
      when(repository.batchUpsertProviders(any)).thenAnswer((_) async => []);
      when(repository.batchUpsertModels(any)).thenAnswer((_) async => []);

      final result = await service.performFullSync();

      expect(result.isSuccess, isTrue);
      expect(result.fullSync, isTrue);
      expect(result.duration, isNotNull);
    });

    test('performFullSync handles sync operation exception', () async {
      when(apiService.getApiStatus()).thenAnswer(
        (_) async => ModelApiStatus(
          isAccessible: true,
          lastChecked: DateTime(2026),
        ),
      );
      when(apiService.fetchAllModels()).thenThrow(Exception('Parse error'));

      final result = await service.performFullSync();

      expect(result.isSuccess, isFalse);
    });

    test('dispose calls apiService dispose', () {
      service.dispose();
      verify(apiService.dispose()).called(1);
    });
  });
}
