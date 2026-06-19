// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/domain/repositories/api_model_repository.dart';
import 'package:auravibes_app/services/model_api_service.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';

final _log = Logger('service:model_sync');

/// Service for synchronizing model and provider data with the external API.
class ModelSyncService {
  ModelSyncService({required this.repository, required this.apiService});

  /// Repository for local data operations.
  final ApiModelRepository repository;

  /// API service for external data fetching.
  final ModelApiService apiService;

  /// Performs a full synchronization of all models and providers.
  ///
  /// Fetches all data from the API, clears local data, and re-inserts every
  /// provider and model. Errors are logged and swallowed so the periodic timer
  /// never tears down on a transient failure.
  Future<void> performFullSync() async {
    try {
      final apiResponse = await apiService.fetchAllModels();

      final apiProviderEntities = apiResponse.providers
          .map((e) => e.modelProvider)
          .toList();
      final apiModelEntities = apiResponse.providers
          .map((e) => e.models)
          .flattenedToList;

      // Atomic replace: clear + insert run in one transaction so a transient
      // failure rolls back to the previous dataset instead of wiping it.
      await repository.replaceAllData(
        providers: apiProviderEntities,
        models: apiModelEntities,
      );
    } on Exception catch (e, s) {
      _log.severe('model sync failed', e, s);
    }
  }
}
