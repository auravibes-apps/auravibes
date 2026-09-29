import 'package:auravibes_app/services/log_redaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('includes safe FormatException details in logs', () {
    expect(
      LogRedaction.redact(
        const FormatException(
          'Input question is required (valueType=missing, keys=args).',
        ),
      ),
      'FormatException: Input question is required '
      '(valueType=missing, keys=args).',
    );
  });

  test('redacts secrets in FormatException details', () {
    expect(
      LogRedaction.redact(const FormatException('token=secret-value')),
      'FormatException: token=[REDACTED]',
    );
  });

  test('redacts authentication token key variants', () {
    expect(
      LogRedaction.redact('authToken=secret-value'),
      'authToken=[REDACTED]',
    );
    expect(
      LogRedaction.redact('{"oauth_token":"secret-value"}'),
      '{"oauth_token":"[REDACTED]"}',
    );
    expect(
      LogRedaction.redact('bearerToken: secret-value'),
      'bearerToken: [REDACTED]',
    );
    expect(
      LogRedaction.redact('?oauthToken=secret-value'),
      '?oauthToken=[REDACTED]',
    );
  });

  test('redacts standalone provider secret keys', () {
    expect(
      LogRedaction.redact(
        'Denied sk-live-secret and rk-live-secret; retry after 30 seconds.',
      ),
      'Denied [REDACTED] and [REDACTED]; retry after 30 seconds.',
    );
  });

  test('keeps provider detail while redacting bearer and named secrets', () {
    expect(
      LogRedaction.redact(
        'Quota exceeded. Authorization: Bearer bearer-secret; '
        'api_key=key-secret',
      ),
      'Quota exceeded. Authorization: Bearer [REDACTED]; '
      'api_key=[REDACTED]',
    );
  });
}
