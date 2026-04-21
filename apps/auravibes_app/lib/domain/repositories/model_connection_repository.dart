import 'package:auravibes_app/domain/entities/model_connection_entities.dart';

/// Repository interface for model connection data operations.
///
/// This abstract class defines the contract for model connection data access,
/// following the Repository pattern from Clean Architecture.
/// Implementations should handle data persistence, retrieval, and
/// business logic validation for model connection operations.
abstract class ModelConnectionRepository {
  Future<List<ModelConnectionEntity>> getModelConnections(
    ModelConnectionFilter filter,
  );

  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate modelConnection,
  );

  /// Deletes a model connection
  Future<void> deleteModelConnection(String modelConnectionId);
}

/// Base exception for model connection-related operations.
class ModelConnectionException implements Exception {
  /// Creates a new ModelConnectionException
  const ModelConnectionException(this.message, [this.cause]);

  /// Error message describing the exception
  final String message;

  /// Optional original exception that caused this exception
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';
    return 'ModelConnectionException: $message$causedBy';
  }
}

/// Exception thrown when model connection validation fails.
class ModelConnectionValidationException extends ModelConnectionException {
  /// Creates a new ModelConnectionValidationException
  const ModelConnectionValidationException(super.message, [super.cause]);
}

/// Exception thrown when a model connection is not found.
class ModelConnectionNotFoundException extends ModelConnectionException {
  /// Creates a new ModelConnectionNotFoundException
  const ModelConnectionNotFoundException(
    this.modelConnectionId, [
    Exception? cause,
  ]) : super('Model connection with ID "$modelConnectionId" not found', cause);

  /// ID of the model connection that was not found
  final String modelConnectionId;
}

/// Exception thrown when a model connection has no models.
class ModelConnectionNoModelsException extends ModelConnectionException {
  /// Creates a new ModelConnectionNoModelsException
  const ModelConnectionNoModelsException(this.modelId, [Exception? cause])
    : super('ModelProvider with type "$modelId" not found models', cause);

  /// ID of the workspaceModelSelection that was not found
  final String modelId;
}

class ModelConnectionModelNotFoundException extends ModelConnectionException {
  const ModelConnectionModelNotFoundException(this.modelId, [Exception? cause])
    : super('ModelProvider with id "$modelId" not found', cause);

  final String modelId;
}

class ModelConnectionNoTypeException extends ModelConnectionException {
  const ModelConnectionNoTypeException(this.modelId, [Exception? cause])
    : super('ModelProvider with id "$modelId" has no type', cause);

  final String modelId;
}
