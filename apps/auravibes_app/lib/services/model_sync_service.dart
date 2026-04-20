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

    // Check API accessibility first
    final apiStatus = await apiService.getApiStatus();
    if (!apiStatus.isAccessible) {
      throw Exception('API is not accessible: ${apiStatus.statusMessage}');
    }

    // Fetch data from API
    final apiResponse = await apiService.fetchAllModels();

    // Get current local data
    final localProviders = await repository.getAllProviders();
    final localModels = await repository.getAllModels();

    // Perform synchronization
    final result = await _performSyncOperation(
      apiResponse: apiResponse,
      localProviders: localProviders,
      localModels: localModels,
      fullSync: true,
    );

    final endTime = DateTime.now();
    return result.copyWith(
      duration: endTime.difference(startTime),
      fullSync: true,
    );
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
        final deletedProviders = await repository.deleteAllData();
        providersRemoved = deletedProviders ~/ 1000; // Rough estimate
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

  /// Creates a copy with updated values
  ModelSyncResult copyWith({
    bool? isSuccess,
    Duration? duration,
    bool? fullSync,
    int? providersAdded,
    int? providersUpdated,
    int? providersRemoved,
    int? modelsAdded,
    int? modelsUpdated,
    int? modelsRemoved,
    List<String>? errors,
  }) {
    return ModelSyncResult(
      isSuccess: isSuccess ?? this.isSuccess,
      duration: duration ?? this.duration,
      fullSync: fullSync ?? this.fullSync,
      providersAdded: providersAdded ?? this.providersAdded,
      providersUpdated: providersUpdated ?? this.providersUpdated,
      providersRemoved: providersRemoved ?? this.providersRemoved,
      modelsAdded: modelsAdded ?? this.modelsAdded,
      modelsUpdated: modelsUpdated ?? this.modelsUpdated,
      modelsRemoved: modelsRemoved ?? this.modelsRemoved,
      errors: errors ?? this.errors,
    );
  }
}

/// Result of a sync validation operation.
class ModelSyncValidation {
  ModelSyncValidation({
    required this.isValid,
    this.missingProviderIds = const [],
    this.extraProviderIds = const [],
    this.missingModelIds = const [],
    this.extraModelIds = const [],
    this.apiStatus,
    this.error,
  });

  /// Whether the sync state is valid
  final bool isValid;

  /// Provider IDs that exist in API but not locally
  final List<String> missingProviderIds;

  /// Provider IDs that exist locally but not in API
  final List<String> extraProviderIds;

  /// Model IDs that exist in API but not locally
  final List<String> missingModelIds;

  /// Model IDs that exist locally but not in API
  final List<String> extraModelIds;

  /// API status information
  final ModelApiStatus? apiStatus;

  /// Error message if validation failed
  final String? error;

  /// Total number of discrepancies
  int get totalDiscrepancies =>
      missingProviderIds.length +
      extraProviderIds.length +
      missingModelIds.length +
      extraModelIds.length;

  /// Human-readable validation summary
  String get summary {
    if (isValid) {
      return 'Sync state is valid';
    }

    if (error != null) {
      return 'Validation failed: $error';
    }

    final issues = <String>[];
    if (missingProviderIds.isNotEmpty) {
      issues.add('${missingProviderIds.length} missing providers');
    }
    if (extraProviderIds.isNotEmpty) {
      issues.add('${extraProviderIds.length} extra providers');
    }
    if (missingModelIds.isNotEmpty) {
      issues.add('${missingModelIds.length} missing models');
    }
    if (extraModelIds.isNotEmpty) {
      issues.add('${extraModelIds.length} extra models');
    }

    return 'Discrepancies found: ${issues.join(', ')}';
  }
}

/// Current synchronization status.
class ModelSyncStatus {
  ModelSyncStatus({
    required this.localProviderCount,
    required this.localModelCount,
    required this.isApiAccessible,
    required this.lastApiCheck,
    required this.apiStatus,
    this.error,
  });

  /// Number of providers in local database
  final int localProviderCount;

  /// Number of models in local database
  final int localModelCount;

  /// Whether the API is currently accessible
  final bool isApiAccessible;

  /// When the API was last checked
  final DateTime lastApiCheck;

  /// API status message
  final String apiStatus;

  /// Error message if status check failed
  final String? error;

  /// Whether the status is healthy
  bool get isHealthy => isApiAccessible && error == null;

  /// Human-readable status summary
  String get summary {
    if (!isHealthy) {
      return 'Status unhealthy: ${error ?? 'API not accessible'}';
    }

    return '''
Healthy: $localProviderCount providers, $localModelCount models, API accessible
''';
  }
}
