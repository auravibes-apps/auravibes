import 'package:auravibes_app/features/models/notifiers/model_catalog_sync_failure.dart';
import 'package:auravibes_app/features/models/notifiers/model_catalog_sync_state.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _logger = Logger('notifier:model_catalog_sync');
const _retryDelays = [Duration(milliseconds: 250), Duration(milliseconds: 500)];
const _firstServerErrorStatusCode = 500;
const _firstNonServerErrorStatusCode = 600;

final modelCatalogSyncNotifierProvider =
    NotifierProvider<ModelCatalogSyncNotifier, ModelCatalogSyncState>(
      ModelCatalogSyncNotifier.new,
    );

class ModelCatalogSyncNotifier extends Notifier<ModelCatalogSyncState> {
  Future<void>? _syncInFlight;

  @override
  ModelCatalogSyncState build() => const ModelCatalogSyncState();

  /// Runs startup sync with bounded retries for transient network failures.
  Future<void> syncAutomatically() async {
    try {
      await _startSync(retryTransientErrors: true);
    } on Object catch (error, stackTrace) {
      _logger.warning('Automatic model catalog sync failed', error, stackTrace);
    }
  }

  /// Runs a single user-requested attempt and propagates failure to the UI.
  Future<void> retryManually() => _startSync(retryTransientErrors: false);

  Future<void> _startSync({required bool retryTransientErrors}) {
    final inFlight = _syncInFlight;
    if (inFlight != null) return inFlight;

    final sync = Future<void>.microtask(
      () => _sync(retryTransientErrors: retryTransientErrors),
    );
    final trackedSync = sync.whenComplete(() {
      _syncInFlight = null;
    });
    _syncInFlight = trackedSync;

    return trackedSync;
  }

  Future<void> _sync({required bool retryTransientErrors}) async {
    state = state.copyWith(isSyncing: true, clearFailure: true);

    var retries = 0;
    while (true) {
      try {
        await _syncAttempt();

        return;
      } on Object catch (error, stackTrace) {
        await _retryOrFail(error, stackTrace, retryTransientErrors, retries++);
      }
    }
  }

  Future<void> _syncAttempt() async {
    if (!ref.mounted) return;
    state = state.copyWith(lastAttemptAt: .now());
    await ref.read(modelSyncServiceProvider).sync();
    if (!ref.mounted) return;

    state = state.copyWith(
      isSyncing: false,
      lastSuccessfulSyncAt: .now(),
      clearFailure: true,
    );
  }

  Future<void> _retryOrFail(
    Object error,
    StackTrace stackTrace,
    bool retryTransientErrors,
    int retries,
  ) async {
    if (retryTransientErrors &&
        retries < _retryDelays.length &&
        _isTransient(error)) {
      await Future<void>.delayed(_retryDelays[retries]);

      return;
    }

    _recordFailure(error);
    Error.throwWithStackTrace(error, stackTrace);
  }

  void _recordFailure(Object error) {
    if (!ref.mounted) return;
    state = state.copyWith(isSyncing: false, failure: _failureFor(error));
  }

  bool _isTransient(Object error) {
    if (error is! DioException) return false;
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return statusCode == 429 ||
          (statusCode >= _firstServerErrorStatusCode &&
              statusCode < _firstNonServerErrorStatusCode);
    }

    return _isTransientDioExceptionType(error.type);
  }

  ModelCatalogSyncFailure _failureFor(Object error) => switch (error) {
    FormatException() => .invalidCatalog,
    DioException() => .unavailable,
    _ => .unexpected,
  };
}

bool _isTransientDioExceptionType(DioExceptionType type) => switch (type) {
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout ||
  DioExceptionType.connectionError => true,
  _ => false,
};
