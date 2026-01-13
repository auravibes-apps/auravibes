import 'package:auravibes_app/domain/entities/credentials_entities.dart';

/// Repository interface for credentialsModel data operations.
///
/// This abstract class defines the contract for credentialsModel data access,
/// following the Repository pattern from Clean Architecture.
/// Implementations should handle data persistence, retrieval, and
/// business logic validation for credentialsModel operations.
abstract class CredentialsRepository {
  Future<List<CredentialsEntity>> getCredentials(
    ModelProviderFilter filter,
  );

  Future<CredentialsEntity> createCredential(
    CredentialsToCreate credentials,
  );

  /// Deletes a credential and its associated API key from secure storage
  Future<void> deleteCredential(String credentialsId);
}

/// Base exception for credentialsModel-related operations.
class ModelProviderException implements Exception {
  /// Creates a new ModelProviderException
  const ModelProviderException(this.message, [this.cause]);

  /// Error message describing the exception
  final String message;

  /// Optional original exception that caused this exception
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';
    return 'ModelProviderException: $message$causedBy';
  }
}

/// Exception thrown when modelProvider validation fails.
class ModelProviderValidationException extends ModelProviderException {
  /// Creates a new ModelProviderValidationException
  const ModelProviderValidationException(super.message, [super.cause]);
}

/// Exception thrown when a modelProvider is not found.
class ModelProviderNotFoundException extends ModelProviderException {
  /// Creates a new ModelProviderNotFoundException
  const ModelProviderNotFoundException(this.modelProviderId, [Exception? cause])
    : super('ModelProvider with ID "$modelProviderId" not found', cause);

  /// ID of the credentialsModel that was not found
  final int modelProviderId;
}

/// Exception thrown when a modelProvider is not found.
class ModelProviderNotModelsException extends ModelProviderException {
  /// Creates a new ModelProviderNotModelsException
  const ModelProviderNotModelsException(this.modelId, [Exception? cause])
    : super('ModelProvider with type "$modelId" not found models', cause);

  /// ID of the credentialsModel that was not found
  final String modelId;
}

class ModelProviderNotModelIdException extends ModelProviderException {
  const ModelProviderNotModelIdException(this.modelId, [Exception? cause])
    : super('ModelProvider with id "$modelId" not found', cause);

  final String modelId;
}

class ModelProviderNoTypeException extends ModelProviderException {
  const ModelProviderNoTypeException(this.modelId, [Exception? cause])
    : super('ModelProvider with id "$modelId" not found', cause);

  final String modelId;
}
