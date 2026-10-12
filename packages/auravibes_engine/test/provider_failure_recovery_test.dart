import 'dart:async';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/plugin.dart' show GenkitException;
import 'package:test/test.dart';

void main() {
  test('classifies authentication failures as non-retryable', () {
    final recovery = ProviderFailureRecovery.fromError(
      GenkitException('Credentials rejected.', status: .unauthenticated),
    );

    expect(recovery.category, ProviderFailureCategory.authentication);
    expect(recovery.retryable, isFalse);
    expect(recovery.providerStatus, 'UNAUTHENTICATED');
  });

  test('requires an explicit Retry-After for retryable rate limits', () {
    final quota = ProviderFailureRecovery.fromError(
      GenkitException('Quota exhausted.', status: .resourceExhausted),
    );
    final rateLimit = ProviderFailureRecovery.fromError(
      AgentRateLimitRetryException(
        providerException: GenkitException(
          'Rate limit exceeded.',
          status: .resourceExhausted,
        ),
        retryAfter: const Duration(seconds: 12),
      ),
    );

    expect(quota.category, ProviderFailureCategory.quotaRateLimit);
    expect(quota.retryable, isFalse);
    expect(rateLimit.category, ProviderFailureCategory.quotaRateLimit);
    expect(rateLimit.retryable, isTrue);
    expect(rateLimit.retryAfter, const Duration(seconds: 12));
    expect(rateLimit.toJson(), {
      'classification': 'quota_rate_limit',
      'retryable': true,
      'providerStatus': 'RESOURCE_EXHAUSTED',
      'retryAfterSeconds': 12,
    });
  });

  test('classifies structured transient statuses as retryable', () {
    final recovery = ProviderFailureRecovery.fromError(
      ProviderHttpFailureException(502, 'Provider gateway failed.'),
    );

    expect(recovery.category, ProviderFailureCategory.transientOutage);
    expect(recovery.retryable, isTrue);
    expect(recovery.httpStatusCode, 502);
  });

  test('uses HTTP Retry-After to make quota recovery retryable', () {
    final recovery = ProviderFailureRecovery.fromError(
      ProviderHttpFailureException(
        429,
        'Rate limit exceeded.',
        retryAfter: const Duration(seconds: 42),
      ),
    );

    expect(recovery.category, ProviderFailureCategory.quotaRateLimit);
    expect(recovery.retryable, isTrue);
    expect(recovery.retryAfter, const Duration(seconds: 42));
  });

  test('classifies HTTP request timeout without assuming retry is safe', () {
    final recovery = ProviderFailureRecovery.fromError(
      ProviderHttpFailureException(408, 'Request timed out.'),
    );

    expect(recovery.category, ProviderFailureCategory.transientOutage);
    expect(recovery.retryable, isFalse);
  });

  test('classifies provider configuration errors as non-retryable', () {
    final recovery = ProviderFailureRecovery.fromError(
      GenkitException('Invalid model settings.', status: .invalidArgument),
    );

    expect(recovery.category, ProviderFailureCategory.configuration);
    expect(recovery.retryable, isFalse);
  });

  test('classifies typed timeouts as transient outages', () {
    final recovery = ProviderFailureRecovery.fromError(
      TimeoutException('Request timed out.'),
    );

    expect(recovery.category, ProviderFailureCategory.transientOutage);
    expect(recovery.retryable, isTrue);
  });

  test('does not infer retry safety from unknown error text', () {
    final recovery = ProviderFailureRecovery.fromError(
      GenkitException(
        'HTTP 429 rate limit, try again in 1 minute.',
        status: .unknown,
      ),
    );

    expect(recovery.category, ProviderFailureCategory.unknown);
    expect(recovery.retryable, isFalse);
  });

  test('requires a structured server error to retry an internal status', () {
    final unstructured = ProviderFailureRecovery.fromError(
      GenkitException(
        'The provider says try again later.',
        status: .internal,
        details: 'server_error: try again later',
      ),
    );
    final structured = ProviderFailureRecovery.fromError(
      GenkitException(
        'Request failed.',
        status: .internal,
        details: '{"error":{"type":"server_error"}}',
      ),
    );
    final exactCode = ProviderFailureRecovery.fromError(
      GenkitException(
        'Request failed.',
        status: .internal,
        details: 'server_error',
      ),
    );

    expect(unstructured.category, ProviderFailureCategory.unknown);
    expect(unstructured.retryable, isFalse);
    expect(structured.category, ProviderFailureCategory.transientOutage);
    expect(structured.retryable, isTrue);
    expect(exactCode.category, ProviderFailureCategory.transientOutage);
    expect(exactCode.retryable, isTrue);
  });

  test('redacts secrets from provider details', () {
    expect(
      sanitizeProviderErrorDetail(
        'api_key=secret-value Bearer header-secret sk-proj-sensitive',
      ),
      'api_key=[REDACTED] [REDACTED] [REDACTED]',
    );
  });

  test('bounds persisted provider details', () {
    expect(sanitizeProviderErrorDetail('x' * 600), hasLength(500));
  });
}
