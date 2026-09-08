import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expiresAt derives from issuedAt and expiresIn', () {
    final issuedAt = DateTime(2026, 1, 2, 3, 4, 5);
    final token = OAuthTokenEntity(
      accessToken: 'access',
      issuedAt: issuedAt,
      expiresIn: 3600,
    );

    expect(token.expiresAt, issuedAt.add(const Duration(hours: 1)));
    expect(
      OAuthTokenEntity(accessToken: 'access', issuedAt: issuedAt).expiresAt,
      isNull,
    );
  });

  test('copyCryptor encrypts optional OAuth tokens', () async {
    final token = OAuthTokenEntity(
      accessToken: 'access',
      issuedAt: DateTime(2026),
      refreshToken: 'refresh',
      idToken: 'id',
      expiresIn: 3600,
      tokenType: 'Bearer',
      scopes: const ['openid'],
    );

    final encrypted = await token.copyCryptor(
      (value) async => 'encrypted-$value',
    );

    expect(encrypted.accessToken, 'encrypted-access');
    expect(encrypted.refreshToken, 'encrypted-refresh');
    expect(encrypted.idToken, 'encrypted-id');
    expect(encrypted.scopes, ['openid']);
  });
}
