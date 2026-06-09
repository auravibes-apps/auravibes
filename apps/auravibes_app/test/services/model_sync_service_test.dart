// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: missing-test-assertion
// Required: Tests verify sync behavior through repository side effects.

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
        duration: const Duration(seconds: 5),
        modelsAdded: 1,
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

    test('withTiming preserves unchanged values', () {
      final result = ModelSyncResult(
        isSuccess: true,
        duration: const Duration(seconds: 10),
        providersAdded: 3,
        modelsAdded: 5,
      );

      final copy = result.withTiming(fullSync: true);

      expect(copy.isSuccess, true);
      expect(copy.providersAdded, 3);
      expect(copy.modelsAdded, 5);
      expect(copy.duration, const Duration(seconds: 10));
      expect(copy.fullSync, true);
    });

    test('withTiming overrides specified values', () {
      final result = ModelSyncResult(
        isSuccess: true,
        duration: const Duration(seconds: 10),
        providersAdded: 3,
      );

      final copy = result.withTiming(
        duration: const Duration(seconds: 20),
        fullSync: true,
      );

      expect(copy.isSuccess, true);
      expect(copy.providersAdded, 3);
      expect(copy.duration, const Duration(seconds: 20));
      expect(copy.fullSync, true);
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
