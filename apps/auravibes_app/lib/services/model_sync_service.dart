// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/features/models/usecases/sync_api_models_usecase.dart';
import 'package:logging/logging.dart';

final _log = Logger('service:model_sync');

/// Service for synchronizing model and provider data with the external API.
class ModelSyncService {
  ModelSyncService({required this.syncApiModelsUseCase});

  final SyncApiModelsUseCase syncApiModelsUseCase;

  /// Performs a full synchronization of all models and providers.
  ///
  /// Errors are logged and swallowed so the periodic timer never tears down on
  /// a transient failure.
  Future<void> performFullSync() async {
    try {
      await syncApiModelsUseCase();
    } on Exception catch (e, s) {
      _log.severe('model sync failed', e, s);
    }
  }
}
