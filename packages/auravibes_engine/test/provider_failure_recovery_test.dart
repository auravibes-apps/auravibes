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

  for (final detail in [
    'Cookie: session=sentinel-cookie; other=sentinel-other\nRequest failed.',
    'sEt-CoOkIe: session=sentinel-cookie; Path=/; HttpOnly\nRequest failed.',
    'Cookie: session=left}sentinel-tail\nRequest failed.',
    '{"Cookie":"session=sentinel-cookie","message":"Request failed."}',
    "'SET-COOKIE'='session=sentinel-cookie; Path=/', Request failed.",
    '{Cookie: session=sentinel-cookie, message: Request failed.}',
    "https://user:sentinel'password@example.com/path Request failed.",
    '"https://sentinel\'password@example.com/path" Request failed.',
    'https://user:sentinel-password@example.com/path Request failed.',
    'HTTPS://sentinel-user:sentinel-password@example.com/path Request failed.',
    'https://example.com/path?sig=sentinel-sig&region=west Request failed.',
    'https://ex.com/?X-Amz-Signature=sentinel-sig Request failed.',
    '"X-Goog-Signature": "sentinel-sig", "message": "Request failed."',
    "'SIGNATURE'='sentinel-sig', Request failed.",
    'signature=sentinel-sig Request failed.',
    '{"signature":"left,sentinel-tail","message":"Request failed."}',
    '{"sig":"left sentinel-tail","message":"Request failed."}',
    r'{"signature":"left\"sentinel-tail","message":"Request failed."}',
  ]) {
    test('redacts provider detail $detail', () {
      final sanitized = ProviderFailureRecovery.safeDetail(
        GenkitException('Request failed.', details: detail),
      );

      expect(sanitized, isNot(contains('sentinel-')));
      expect(sanitized, contains('[REDACTED]'));
      expect(sanitized, contains('Request failed.'));
      if (detail.contains('example.com')) {
        expect(sanitized, contains('example.com/path'));
      }
      if (detail.contains('region=west')) {
        expect(sanitized, contains('region=west'));
      }
    });
  }

  test('bounds persisted provider details', () {
    expect(sanitizeProviderErrorDetail('x' * 600), hasLength(500));
  });

  test('does not persist arbitrary exception text as provider detail', () {
    final unknown = StateError('Bearer private-token from user input');
    final transport = ProviderTransientFailureException(
      StateError('request URL contains a private query'),
    );

    expect(ProviderFailureRecovery.safeDetail(unknown), 'StateError');
    expect(ProviderFailureRecovery.safeDetail(transport), 'StateError');
  });
}
