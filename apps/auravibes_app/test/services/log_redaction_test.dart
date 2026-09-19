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
}
