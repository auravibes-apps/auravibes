import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
