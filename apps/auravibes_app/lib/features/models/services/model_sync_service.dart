// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/features/models/usecases/sync_api_models_usecase.dart';
import 'package:logging/logging.dart';

final _log = Logger('service:model_sync');

/// Service for synchronizing model and provider data with the external API.
class ModelSyncService({
  required final SyncApiModelsUseCase syncApiModelsUseCase,
}) {
  Future<void>? _syncInFlight;

  /// Performs a full synchronization of all models and providers.
  ///
  /// Errors are logged and swallowed so automatic callers survive transient
  /// failures.
  Future<void> performFullSync() async {
    try {
      await performManualSync();
    } on Exception catch (e, s) {
      _log.severe('model sync failed', e, s);
    }
  }

  /// Synchronizes the catalog and forwards failures to the user-triggered UI.
  ///
  /// Concurrent callers share one in-flight request.
  Future<void> performManualSync() => _syncInFlight ??= .microtask(_sync);

  Future<void> _sync() async {
    try {
      await syncApiModelsUseCase();
    } finally {
      _syncInFlight = null;
    }
  }
}
