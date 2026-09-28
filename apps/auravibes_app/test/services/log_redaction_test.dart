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
}
