import 'dart:async';
import 'dart:convert';

import 'package:auravibes_engine/src/agent_rate_limit_retry_exception.dart';
import 'package:auravibes_engine/src/provider_error_sanitizer.dart';
import 'package:genkit/plugin.dart' show GenkitException, StatusCode;

/// Provider failure classes that can be persisted without storing raw errors.
enum ProviderFailureCategory(final String wireValue) {
  authentication('authentication'),
  quotaRateLimit('quota_rate_limit'),
  transientOutage('transient_outage'),
  configuration('configuration'),
  unknown('unknown'),
}

/// Structured provider status and safe retry eligibility for recovery UI.
final class const ProviderFailureRecovery({
  required final ProviderFailureCategory category,
  required final bool retryable,
  final String? providerStatus,
  final int? httpStatusCode,
  final Duration? retryAfter,
}) {
  /// Converts a provider exception to a recovery contract without reading its
  /// message text.
  factory fromError(Object error) {
    if (error is AgentRateLimitRetryException) {
      return ProviderFailureRecovery(
        category: .quotaRateLimit,
        retryable: true,
        providerStatus: error.providerException.status.wireName,
        httpStatusCode: switch (error.providerException) {
          ProviderHttpFailureException(:final httpStatusCode) => httpStatusCode,
          _ => null,
        },
        retryAfter: error.retryAfter,
      );
    }

    if (error is GenkitException) {
      final cause = error.cause;
      if (cause != null) {
        final causeRecovery = ProviderFailureRecovery.fromError(cause);
        if (causeRecovery.category != ProviderFailureCategory.unknown) {
          return causeRecovery;
        }
      }
    }

    if (error is ProviderHttpFailureException) {
      return _fromHttpStatus(
        error.httpStatusCode,
        retryAfter: error.retryAfter,
      );
    }

    if (error is! GenkitException) {
      if (error is TimeoutException ||
          error is ProviderTransientFailureException) {
        return const ProviderFailureRecovery(
          category: .transientOutage,
          retryable: true,
        );
      }

      return const ProviderFailureRecovery(
        category: .unknown,
        retryable: false,
      );
    }

    return switch (error.status) {
      StatusCode.unauthenticated ||
      StatusCode.permissionDenied => ProviderFailureRecovery(
        category: .authentication,
        retryable: false,
        providerStatus: error.status.wireName,
      ),
      StatusCode.resourceExhausted => ProviderFailureRecovery(
        category: .quotaRateLimit,
        retryable: false,
        providerStatus: error.status.wireName,
      ),
      StatusCode.unavailable ||
      StatusCode.deadlineExceeded => ProviderFailureRecovery(
        category: .transientOutage,
        retryable: true,
        providerStatus: error.status.wireName,
      ),
      StatusCode.internal
          when _isStructuredProviderServerError(error.details) =>
        ProviderFailureRecovery(
          category: .transientOutage,
          retryable: true,
          providerStatus: error.status.wireName,
        ),
      StatusCode.invalidArgument ||
      StatusCode.failedPrecondition ||
      StatusCode.notFound ||
      StatusCode.unimplemented ||
      StatusCode.outOfRange => ProviderFailureRecovery(
        category: .configuration,
        retryable: false,
        providerStatus: error.status.wireName,
      ),
      _ => ProviderFailureRecovery(
        category: .unknown,
        retryable: false,
        providerStatus: error.status.wireName,
      ),
    };
  }

  /// Returns bounded, secret-redacted provider detail for selectable UI.
  static String safeDetail(Object error) {
    final detail = switch (error) {
      AgentRateLimitRetryException(:final providerException) =>
        providerException.details ?? providerException.message,
      ProviderHttpFailureException(:final details, :final message) =>
        details ?? message,
      GenkitException(:final details, :final cause, :final message) =>
        details ?? (cause is GenkitException ? cause.details : null) ?? message,
      ProviderTransientFailureException(:final cause) => cause.toString(),
      _ => error.toString(),
    };

    return sanitizeProviderErrorDetail(detail);
  }

  /// JSON-safe provenance for existing app and cloud persistence fields.
  Map<String, Object?> toJson() => {
    'classification': category.wireValue,
    'retryable': retryable,
    'providerStatus': ?providerStatus,
    'httpStatusCode': ?httpStatusCode,
    'retryAfterSeconds': ?retryAfter?.inSeconds,
  };
}

/// Retains an HTTP provider's exact status when Genkit's canonical mapping
/// would otherwise collapse or lose it, such as HTTP 502.
final class ProviderHttpFailureException(
  final int httpStatusCode,
  super.message, {
  super.details,
  final Duration? retryAfter,
}) extends GenkitException {
  @override
  StatusCode get status => _statusForProviderHttp(httpStatusCode);
}

/// Typed transport failure for providers whose SDK does not expose a status.
///
/// Use this only for transport exceptions such as a failed HTTP client request;
/// callers should not wrap arbitrary provider or application exceptions.
final class const ProviderTransientFailureException(final Object cause)
    implements Exception;

ProviderFailureRecovery _fromHttpStatus(
  int statusCode, {
  Duration? retryAfter,
}) {
  final category = switch (statusCode) {
    401 || 403 => ProviderFailureCategory.authentication,
    429 => ProviderFailureCategory.quotaRateLimit,
    400 || 404 || 409 || 422 || 501 => ProviderFailureCategory.configuration,
    408 || 500 || 502 || 503 || 504 => ProviderFailureCategory.transientOutage,
    _ => ProviderFailureCategory.unknown,
  };

  return ProviderFailureRecovery(
    category: category,
    retryable: switch (statusCode) {
      429 => retryAfter != null,
      500 || 502 || 503 || 504 => true,
      _ => false,
    },
    providerStatus: _statusForProviderHttp(statusCode).wireName,
    httpStatusCode: statusCode,
    retryAfter: retryAfter,
  );
}

StatusCode _statusForProviderHttp(int statusCode) => switch (statusCode) {
  // StatusCode.fromHttpStatus maps 502 to UNKNOWN; keep its gateway meaning.
  502 => StatusCode.unavailable,
  _ => StatusCode.fromHttpStatus(statusCode),
};

bool _isStructuredProviderServerError(String? details) {
  if (details == null || details.trim().isEmpty) return false;
  if (details.trim() == 'server_error') return true;

  late final Object? decoded;
  try {
    decoded = jsonDecode(details);
  } on FormatException {
    return false;
  }

  if (decoded == 'server_error') return true;
  if (decoded is! Map<String, dynamic>) return false;

  final error = decoded['error'];
  if (error == 'server_error') return true;
  if (error case {'type': 'server_error'} || {'code': 'server_error'}) {
    return true;
  }

  return decoded['type'] == 'server_error' || decoded['code'] == 'server_error';
}
