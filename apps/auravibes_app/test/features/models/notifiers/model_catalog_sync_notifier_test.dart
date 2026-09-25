import 'dart:async';

import 'package:auravibes_app/features/models/notifiers/model_catalog_sync_failure.dart';
import 'package:auravibes_app/features/models/notifiers/model_catalog_sync_notifier.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/services/model_sync_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class _MockModelSyncService extends Mock implements ModelSyncService;

void main() {
  group('ModelCatalogSyncNotifier', () {
    test('records attempt and successful sync timestamps', () async {
      final service = _MockModelSyncService();
      when(service.sync).thenAnswer((_) => Future<void>.value());
      final container = _containerFor(service);
      addTearDown(container.dispose);

      await container
          .read(modelCatalogSyncNotifierProvider.notifier)
          .retryManually();

      final state = container.read(modelCatalogSyncNotifierProvider);
      expect(state.isSyncing, isFalse);
      expect(state.failure, isNull);
      expect(state.lastAttemptAt, isNotNull);
      expect(state.lastSuccessfulSyncAt, isNotNull);
      verify(service.sync).called(1);
    });

    test('manual failure keeps success and allows retry', () async {
      final service = _MockModelSyncService();
      var attempts = 0;
      when(service.sync).thenAnswer(
        (_) => attempts++ == 1
            ? Future<void>.error(_serviceUnavailable())
            : Future<void>.value(),
      );
      final container = _containerFor(service);
      addTearDown(container.dispose);
      final notifier = container.read(
        modelCatalogSyncNotifierProvider.notifier,
      );

      await notifier.retryManually();
      final lastSuccessfulSyncAt =
          container.read(modelCatalogSyncNotifierProvider).lastSuccessfulSyncAt;
      await expectLater(
        notifier.retryManually(),
        throwsA(isA<DioException>()),
      );

      final state = container.read(modelCatalogSyncNotifierProvider);
      expect(state.failure, ModelCatalogSyncFailure.unavailable);
      expect(state.lastSuccessfulSyncAt, lastSuccessfulSyncAt);
      expect(state.lastAttemptAt, isNotNull);
      expect(state.isSyncing, isFalse);
      verify(service.sync).called(2);
    });

    test('automatic retries transient errors three times', () async {
      final service = _MockModelSyncService();
      when(service.sync).thenThrow(_serviceUnavailable());
      final container = _containerFor(service);
      addTearDown(container.dispose);

      await container
          .read(modelCatalogSyncNotifierProvider.notifier)
          .syncAutomatically();

      final state = container.read(modelCatalogSyncNotifierProvider);
      expect(state.failure, ModelCatalogSyncFailure.unavailable);
      expect(state.lastAttemptAt, isNotNull);
      expect(state.isSyncing, isFalse);
      verify(service.sync).called(3);
    });

    test('automatic sync does not retry invalid catalog data', () async {
      final service = _MockModelSyncService();
      when(service.sync).thenThrow(const FormatException('empty'));
      final container = _containerFor(service);
      addTearDown(container.dispose);

      await container
          .read(modelCatalogSyncNotifierProvider.notifier)
          .syncAutomatically();

      final state = container.read(modelCatalogSyncNotifierProvider);
      expect(state.failure, ModelCatalogSyncFailure.invalidCatalog);
      verify(service.sync).called(1);
    });

    test('concurrent automatic callers share one sync sequence', () async {
      final service = _MockModelSyncService();
      final completer = Completer<void>();
      when(service.sync).thenAnswer((_) => completer.future);
      final container = _containerFor(service);
      addTearDown(container.dispose);
      final notifier = container.read(
        modelCatalogSyncNotifierProvider.notifier,
      );

      final first = notifier.syncAutomatically();
      final second = notifier.syncAutomatically();
      await Future<void>.delayed(.zero);
      verify(service.sync).called(1);

      completer.complete();
      final _ = await Future.wait([first, second]);
      expect(
        container.read(modelCatalogSyncNotifierProvider).lastSuccessfulSyncAt,
        isNotNull,
      );
    });
  });
}

ProviderContainer _containerFor(ModelSyncService service) =>
    ProviderContainer(
      overrides: [modelSyncServiceProvider.overrideWithValue(service)],
    );

DioException _serviceUnavailable() {
  final request = RequestOptions(path: '/api.json');

  return DioException(
    requestOptions: request,
    response: Response<void>(
      requestOptions: request,
      statusCode: 503,
    ),
    type: .badResponse,
  );
}
