import 'dart:convert';

import 'package:auravibes_server/src/features/mcp_servers/mcp_oauth_credentials.dart';
import 'package:test/test.dart';

void main() {
  const encoded =
      '{"clientId":"client","tokenEndpoint":"https://auth.example.com/token","token":{"accessToken":"access-secret","refreshToken":"refresh-secret","issuedAt":"2026-01-01T00:00:00Z","expiresIn":3600,"tokenType":"Bearer"}}';

  test('parses OAuth payload and keeps tokens out of toString', () {
    final credentials = McpOAuthCredentials.parse(encoded);
    expect(credentials.accessToken, 'access-secret');
    expect(credentials.needsRefresh(DateTime.utc(2026, 1, 1, 0, 30)), isFalse);
    expect(credentials.needsRefresh(DateTime.utc(2026, 1, 1, 0, 55)), isTrue);
    expect(credentials.toString(), isNot(contains('access-secret')));
  });

  test('rotated refresh token replaces old token in encrypted payload', () {
    final credentials = McpOAuthCredentials.parse(encoded);
    final rotated = credentials.withRefreshedToken(
      accessToken: 'new-access',
      refreshToken: 'new-refresh',
      expiresIn: 7200,
      now: DateTime.utc(2026, 1, 1, 1),
    );
    final json = jsonEncode(rotated.toJson());
    expect(json, contains('new-refresh'));
    expect(json, isNot(contains('refresh-secret')));
    expect(rotated.needsRefresh(DateTime.utc(2026, 1, 1, 2)), isFalse);
  });

  test('rejects invalid or unsafe OAuth payload', () {
    for (final raw in [
      encoded.replaceFirst(
        'https://auth.example.com',
        'http://auth.example.com',
      ),
      encoded.replaceFirst('access-secret', 'access\\r\\nInjected'),
      encoded.replaceFirst('"clientId":"client"', '"clientId":""'),
      encoded.replaceFirst(
        '"clientId":"client"',
        '"clientId":"client","resource":42',
      ),
      encoded.replaceFirst('"tokenType":"Bearer"', '"tokenType":42'),
    ]) {
      expect(() => McpOAuthCredentials.parse(raw), throwsFormatException);
    }
  });

  test('missing expiry requires refresh and accepts bearer casing', () {
    final withoutExpiry = encoded
        .replaceFirst('"expiresIn":3600,', '')
        .replaceFirst('"tokenType":"Bearer"', '"tokenType":"bearer"');
    final credentials = McpOAuthCredentials.parse(withoutExpiry);
    expect(credentials.needsRefresh(DateTime.utc(2026, 1, 1)), isTrue);
  });
}
