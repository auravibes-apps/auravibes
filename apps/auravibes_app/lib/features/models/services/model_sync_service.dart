import 'package:auravibes_app/features/models/usecases/sync_api_models_usecase.dart';

/// Service for synchronizing model and provider data with the external API.
class ModelSyncService({
  required final SyncApiModelsUseCase syncApiModelsUseCase,
}) {
  Future<void>? _syncInFlight;

  /// Synchronizes model and provider data with the external API.
  ///
  /// Concurrent callers share one in-flight request. Errors propagate to the
  /// caller so automatic and manual flows can apply different policies.
  Future<void> sync() => _syncInFlight ??= .microtask(_sync);

  Future<void> _sync() async {
    try {
      await syncApiModelsUseCase();
    } finally {
      _syncInFlight = null;
    }
  }
}
