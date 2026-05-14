import 'package:auravibes_app/domain/entities/api_model.dart';
import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:auravibes_app/domain/repositories/api_model_repository.dart';
import 'package:auravibes_app/services/model_api_service.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';

final _log = Logger('service:model_sync');

/// Service for synchronizing model and provider data with the external API.
///
/// This service handles the synchronization logic between the local database
/// and the external models.dev API, including incremental updates, conflict
/// resolution, and error handling.
class ModelSyncService {
  ModelSyncService({
    required this.repository,
    required this.apiService,
  });

  /// Repository for local data operations
  final ApiModelRepository repository;

  /// API service for external data fetching
  final ModelApiService apiService;

  /// Performs a full synchronization of all models and providers.
  ///
  /// This method will:
  /// 1. Fetch all data from the API
  /// 2. Compare with local data
  /// 3. Update, add, or remove items as needed
  /// 4. Return a summary of the synchronization results
  ///
  /// Returns a [ModelSyncResult] with details about what was synchronized.
  Future<ModelSyncResult> performFullSync() async {
    final startTime = DateTime.now();

    try {
      final apiStatus = await apiService.getApiStatus();
      if (!apiStatus.isAccessible) {
        return ModelSyncResult(
          isSuccess: false,
          duration: DateTime.now().difference(startTime),
          fullSync: true,
          errors: ['API is not accessible: ${apiStatus.statusMessage}'],
        );
      }

      final apiResponse = await apiService.fetchAllModels();
      final localProviders = await repository.getAllProviders();
      final localModels = await repository.getAllModels();

      final result = await _performSyncOperation(
        apiResponse: apiResponse,
        localProviders: localProviders,
        localModels: localModels,
        fullSync: true,
      );

      return result.withTiming(
        duration: DateTime.now().difference(startTime),
        fullSync: true,
      );
    } on Exception catch (e, s) {
      _log.severe('full sync pre-check failed', e, s);
      return ModelSyncResult(
        isSuccess: false,
        duration: DateTime.now().difference(startTime),
        fullSync: true,
        errors: ['Full sync pre-check failed: $e'],
      );
    }
  }

  /// Performs the actual synchronization operation.
  ///
  /// This is an internal method that handles the core synchronization logic.
  Future<ModelSyncResult> _performSyncOperation({
    required ModelApiResponse apiResponse,
    required List<ApiModelProviderEntity> localProviders,
    required List<ApiModelEntity> localModels,
    required bool fullSync,
  }) async {
    var providersAdded = 0;
    var providersRemoved = 0;
    var modelsAdded = 0;
    final errors = <String>[];

    try {
      // Convert API data to domain entities
      final apiProviderEntities = apiResponse.providers
          .map(
            (e) => e.modelProvider,
          )
          .toList();
      final apiModelEntities = apiResponse.providers
          .map(
            (e) => e.models,
          )
          .flattenedToList;

      // Sync providers (clear and replace for full sync)
      if (fullSync) {
        await repository.deleteAllData();
        providersRemoved = localProviders.length;
      }

      // Batch insert providers and models
      final insertedProviders = await repository.batchUpsertProviders(
        apiProviderEntities,
      );
      final insertedModels = await repository.batchUpsertModels(
        apiModelEntities,
      );

      providersAdded = insertedProviders.length;
      modelsAdded = insertedModels.length;

      return ModelSyncResult(
        isSuccess: true,
        providersAdded: providersAdded,
        providersRemoved: providersRemoved,
        modelsAdded: modelsAdded,
        errors: errors,
      );
    } on Exception catch (e, s) {
      _log.severe('sync failed', e, s);
      errors.add('Sync operation failed: $e');
      return ModelSyncResult(
        isSuccess: false,
        providersAdded: providersAdded,
        providersRemoved: providersRemoved,
        modelsAdded: modelsAdded,
        errors: errors,
      );
    }
  }

  /// Disposes the service and cleans up resources.
  void dispose() {
    apiService.dispose();
  }
}

/// Result of a model synchronization operation.
class ModelSyncResult {
  ModelSyncResult({
    required this.isSuccess,
    this.duration,
    this.fullSync = false,
    this.providersAdded = 0,
    this.providersUpdated = 0,
    this.providersRemoved = 0,
    this.modelsAdded = 0,
    this.modelsUpdated = 0,
    this.modelsRemoved = 0,
    this.errors = const [],
  });

  /// Whether the synchronization was successful
  final bool isSuccess;

  /// How long the synchronization took
  final Duration? duration;

  /// Whether this was a full synchronization
  final bool fullSync;

  /// Number of providers added
  final int providersAdded;

  /// Number of providers updated
  final int providersUpdated;

  /// Number of providers removed
  final int providersRemoved;

  /// Number of models added
  final int modelsAdded;

  /// Number of models updated
  final int modelsUpdated;

  /// Number of models removed
  final int modelsRemoved;

  /// List of errors that occurred during synchronization
  final List<String> errors;

  /// Total number of changes made
  int get totalChanges =>
      providersAdded +
      providersUpdated +
      providersRemoved +
      modelsAdded +
      modelsUpdated +
      modelsRemoved;

  /// Human-readable summary of the sync result
  String get summary {
    if (!isSuccess) {
      return 'Synchronization failed with ${errors.length} errors';
    }

    final changes = <String>[];
    if (providersAdded > 0) changes.add('$providersAdded providers added');
    if (providersUpdated > 0) {
      changes.add('$providersUpdated providers updated');
    }
    if (providersRemoved > 0) {
      changes.add('$providersRemoved providers removed');
    }
    if (modelsAdded > 0) changes.add('$modelsAdded models added');
    if (modelsUpdated > 0) changes.add('$modelsUpdated models updated');
    if (modelsRemoved > 0) changes.add('$modelsRemoved models removed');

    if (changes.isEmpty) {
      return 'No changes needed';
    }

    final changeStr = changes.join(', ');
    final durationStr = duration != null ? ' in ${duration!.inSeconds}s' : '';
    return 'Synchronized $changeStr$durationStr';
  }

  // Null keeps the existing timing value.
  // ignore: unnecessary-nullable
  /// Creates a copy with updated timing values.
  ModelSyncResult withTiming({
    Duration? duration,
    bool? fullSync,
  }) {
    return ModelSyncResult(
      isSuccess: isSuccess,
      duration: duration ?? this.duration,
      fullSync: fullSync ?? this.fullSync,
      providersAdded: providersAdded,
      providersUpdated: providersUpdated,
      providersRemoved: providersRemoved,
      modelsAdded: modelsAdded,
      modelsUpdated: modelsUpdated,
      modelsRemoved: modelsRemoved,
      errors: List.unmodifiable(errors),
    );
  }
}
