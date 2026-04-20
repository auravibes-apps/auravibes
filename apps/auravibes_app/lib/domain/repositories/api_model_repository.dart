import 'package:auravibes_app/domain/entities/api_model.dart';
import 'package:auravibes_app/domain/entities/api_model_provider.dart';

/// Repository interface for API model and provider data operations.
///
/// This abstract class defines the contract for API model data access,
/// following the Repository pattern from Clean Architecture.
/// Implementations should handle data persistence, retrieval, and
/// business logic validation for API model operations.
abstract class ApiModelRepository {
  // Provider operations

  /// Retrieves all API model providers from the data source.
  ///
  /// Returns a list of all providers ordered by their name.
  /// Throws [ApiModelException] if there's an error retrieving providers.
  Future<List<ApiModelProviderEntity>> getAllProviders();

  /// Retrieves providers filtered by their type.
  ///
  /// [type] The type of providers to retrieve.
  /// Returns a list of providers with the specified [type] ordered by name.
  /// Throws [ApiModelException] if there's an error retrieving providers.
  Future<List<ApiModelProviderEntity>> getProvidersByType(String type);

  // Model operations

  /// Retrieves all API models from the data source.
  ///
  /// Returns a list of all models ordered by provider and name.
  /// Throws [ApiModelException] if there's an error retrieving models.
  Future<List<ApiModelEntity>> getAllModels();

  /// Retrieves a model by provider + model ID.
  ///
  /// [providerId] Provider ID (for example: openai).
  /// [modelId] Model ID inside that provider.
  /// Returns the matching model, or null if not found.
  /// Throws [ApiModelException] if there's an error retrieving the model.
  Future<ApiModelEntity?> getModelByProviderAndModelId(
    String providerId,
    String modelId,
  );

  /// Retrieves all models for a specific provider.
  ///
  /// [providerId] Provider ID to filter by.
  /// Returns a list of models ordered by model name.
  /// Throws [ApiModelException] if there's an error retrieving models.
  Future<List<ApiModelEntity>> getModelsByProvider(String providerId);

  // Batch operations for synchronization

  /// Batch inserts or updates multiple providers.
  ///
  /// [providers] List of providers to upsert.
  /// For each provider, it will update if it exists or insert if it doesn't.
  /// Returns the list of inserted/updated providers.
  /// Throws [ApiModelException] if there's an error during batch operations.
  Future<List<ApiModelProviderEntity>> batchUpsertProviders(
    List<ApiModelProviderEntity> providers,
  );

  /// Batch inserts or updates multiple models.
  ///
  /// [models] List of models to upsert.
  /// For each model, it will update if it exists or insert if it doesn't.
  /// Returns the list of inserted/updated models.
  /// Throws [ApiModelException] if there's an error during batch operations.
  Future<List<ApiModelEntity>> batchUpsertModels(List<ApiModelEntity> models);

  /// Deletes all providers and models from the data source.
  ///
  /// This is typically used during full resynchronization operations.
  /// Returns the number of deleted items (providers + models).
  /// Throws [ApiModelException] if there's an error during deletion.
  Future<int> deleteAllData();
}

/// Base exception for API model-related operations.
class ApiModelException implements Exception {
  /// Creates a new ApiModelException
  const ApiModelException(this.message, [this.cause]);

  /// Error message describing the exception
  final String message;

  /// Optional original exception that caused this exception
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';
    return 'ApiModelException: $message$causedBy';
  }
}

/// Exception thrown when API model validation fails.
class ApiModelValidationException extends ApiModelException {
  /// Creates a new ApiModelValidationException
  const ApiModelValidationException(super.message, [super.cause]);
}

/// Exception thrown when an API model or provider is not found.
class ApiModelNotFoundException extends ApiModelException {
  /// Creates a new ApiModelNotFoundException
  const ApiModelNotFoundException(this.id, [Exception? cause])
    : super('API model/provider with ID "$id" not found', cause);

  /// ID of the item that was not found
  final String id;
}

/// Exception thrown when attempting to create a duplicate API model or
/// provider.
class ApiModelDuplicateException extends ApiModelException {
  /// Creates a new ApiModelDuplicateException
  const ApiModelDuplicateException(this.id, [Exception? cause])
    : super('API model/provider with ID "$id" already exists', cause);

  /// ID of the duplicate item
  final String id;
}
