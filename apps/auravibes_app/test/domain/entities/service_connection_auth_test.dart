import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceConnectionSecret', () {
    test('throws when required API key field is missing', () {
      expect(
        () => ServiceConnectionSecret.fromJson({'type': 'apiKey'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when required bearer token field is empty', () {
      expect(
        () => ServiceConnectionSecret.fromJson({
          'type': 'bearerToken',
          'bearer_token': '',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when required OAuth access token field is missing', () {
      expect(
        () => ServiceConnectionSecret.fromJson({'type': 'oauth2'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ServiceConnectionMetadata', () {
    test('ignores unexpected scalar field types', () {
      final metadata = ServiceConnectionMetadata.fromJson({
        'client_id': 123,
        'issuer': true,
        'authorization_endpoint': ['https://auth.example.com'],
        'token_endpoint': {'url': 'https://token.example.com'},
        'account_id': 456,
        'tenant_id': false,
        'provider': 789,
      });

      expect(metadata.clientId, isNull);
      expect(metadata.issuer, isNull);
      expect(metadata.authorizationEndpoint, isNull);
      expect(metadata.tokenEndpoint, isNull);
      expect(metadata.accountId, isNull);
      expect(metadata.tenantId, isNull);
      expect(metadata.provider, isNull);
    });
  });
}
