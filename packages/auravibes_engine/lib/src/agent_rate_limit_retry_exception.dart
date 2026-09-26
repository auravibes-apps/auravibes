import 'package:genkit/plugin.dart' show GenkitException;

/// Carries a provider-suggested retry delay with the original provider error.
final class AgentRateLimitRetryException extends GenkitException {
  /// Creates a retry hint that preserves [providerException].
  new({required this.providerException, required this.retryAfter})
    : super(
        providerException.message,
        status: providerException.status,
        details: providerException.details,
        underlyingException: providerException.underlyingException,
        stackTrace: providerException.stackTrace,
      );

  /// The original provider error to surface after retries are exhausted.
  final GenkitException providerException;

  /// The provider-suggested delay before retrying.
  final Duration retryAfter;

  @override
  String toString() => providerException.toString();
}
