import 'package:auravibes_app/domain/enums/credentials_model_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CredentialsModelType', () {
    group('value', () {
      test('openai has value openai', () {
        expect(CredentialsModelType.openai.value, 'openai');
      });

      test('anthropic has value anthropic', () {
        expect(CredentialsModelType.anthropic.value, 'anthropic');
      });

      test('google has value google', () {
        expect(CredentialsModelType.google.value, 'google');
      });
    });

    group('toString', () {
      test('returns the value', () {
        expect(CredentialsModelType.openai.toString(), 'openai');
        expect(CredentialsModelType.anthropic.toString(), 'anthropic');
      });
    });

    group('fromString', () {
      test('creates openai from string', () {
        expect(
          CredentialsModelType.fromString('openai'),
          CredentialsModelType.openai,
        );
      });

      test('creates anthropic from string', () {
        expect(
          CredentialsModelType.fromString('anthropic'),
          CredentialsModelType.anthropic,
        );
      });

      test('is case-insensitive', () {
        expect(
          CredentialsModelType.fromString('OPENAI'),
          CredentialsModelType.openai,
        );
        expect(
          CredentialsModelType.fromString('Anthropic'),
          CredentialsModelType.anthropic,
        );
      });

      test('throws ArgumentError for invalid value', () {
        expect(
          () => CredentialsModelType.fromString('invalid'),
          throwsArgumentError,
        );
      });
    });
  });
}
