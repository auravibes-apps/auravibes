import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/services/codex_oauth_service.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CodexOAuthService', () {
    test('builds Codex authorize URL', () {
      final service = CodexOAuthService();

      final uri = service.buildAuthorizeUri(
        redirectUri: 'http://localhost:1455/auth/callback',
        codeChallenge: 'challenge',
        state: 'state',
      );

      expect(uri.toString(), startsWith(openAICodexAuthorizationEndpoint));
      expect(uri.queryParameters['client_id'], openAICodexClientId);
      expect(
        uri.queryParameters['redirect_uri'],
        'http://localhost:1455/auth/callback',
      );
      expect(uri.queryParameters['scope'], openAICodexScopes.join(' '));
      expect(uri.queryParameters['code_challenge'], 'challenge');
      expect(uri.queryParameters['state'], 'state');
      expect(uri.queryParameters['originator'], 'auravibes');
    });

    test('authenticates with browser callback', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter(
          onFetch: (_) async => _json({'access_token': 'access'}),
        );

      final token = await CodexOAuthService(
        dio: dio,
        openBrowser: (uri) async {
          final redirectUri = Uri.parse(uri.queryParameters['redirect_uri']!);
          expect(redirectUri.host, 'localhost');
          final callbackUri = redirectUri.replace(
            queryParameters: {
              'state': uri.queryParameters['state'],
              'code': 'browser-code',
            },
          );
          final client = HttpClient();
          addTearDown(client.close);
          final request = await client.getUrl(callbackUri);
          final response = await request.close();
          final _ = await response.drain<void>();
        },
      ).authenticateWithBrowser();

      expect(token.accessToken, 'access');
    });

    test('exchanges code response into OAuth token', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter(
          onFetch: (options) async {
            expect(options.uri.toString(), openAICodexTokenEndpoint);

            return _json({
              'access_token': 'access',
              'refresh_token': 'refresh',
              'id_token': _jwt({'chatgpt_account_id': 'account-1'}),
              'expires_in': 3600.5,
              'token_type': 'Bearer',
              'scope': 'openid email',
            });
          },
        );

      final token = await CodexOAuthService(dio: dio).exchangeCodeForToken(
        code: 'code',
        redirectUri: CodexOAuthService.deviceCallback,
        codeVerifier: 'verifier',
      );

      expect(token.accessToken, 'access');
      expect(token.refreshToken, 'refresh');
      expect(token.expiresIn, 3600);
      expect(token.tokenType, 'Bearer');
      expect(token.scopes, ['openid', 'email']);
      expect(CodexOAuthService.accountIdFromToken(token), 'account-1');
    });

    test('authenticates with device code', () async {
      CodexDeviceCode? shownCode;
      var calls = 0;
      final dio = Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter(
          onFetch: (options) async {
            calls++;
            if (options.uri.path.endsWith('/usercode')) {
              return _json({
                'device_auth_id': 'device-1',
                'user_code': 'ABCD-EFGH',
                'interval': '1',
              });
            }
            if (options.uri.path.endsWith('/token') && calls == 2) {
              return _json({
                'authorization_code': 'auth-code',
                'code_verifier': 'verifier',
              });
            }

            return _json({'access_token': 'access'});
          },
        );

      final token =
          await CodexOAuthService(
            dio: dio,
          ).authenticateWithDeviceCode(
            onDeviceCode: (deviceCode) {
              shownCode = deviceCode;
            },
          );

      expect(shownCode?.verificationUrl, '$openAICodexIssuer/codex/device');
      expect(shownCode?.userCode, 'ABCD-EFGH');
      expect(token.accessToken, 'access');
    });

    test('keeps polling while device code is pending', () async {
      var tokenPolls = 0;
      final dio = Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter(
          onFetch: (options) async {
            if (options.uri.path.endsWith('/usercode')) {
              return _json({
                'device_auth_id': 'device-1',
                'user_code': 'ABCD-EFGH',
                'interval': 0,
              });
            }
            if (options.uri.path.endsWith('/deviceauth/token')) {
              tokenPolls++;
              if (tokenPolls == 1) return _json({}, HttpStatus.forbidden);

              return _json({
                'authorization_code': 'auth-code',
                'code_verifier': 'verifier',
              });
            }

            return _json({'access_token': 'access'});
          },
        );

      final token = await CodexOAuthService(
        dio: dio,
      ).authenticateWithDeviceCode();

      expect(tokenPolls, 2);
      expect(token.accessToken, 'access');
    });

    test('cancels device code polling', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter(
          onFetch: (options) async {
            if (options.uri.path.endsWith('/usercode')) {
              return _json({
                'device_auth_id': 'device-1',
                'user_code': 'ABCD-EFGH',
              });
            }

            return _json({}, 403);
          },
        );

      await expectLater(
        CodexOAuthService(dio: dio).authenticateWithDeviceCode(
          isCancelled: () => true,
        ),
        throwsA(isA<CodexOAuthCanceledException>()),
      );
    });

    test('returns null for invalid account token', () {
      expect(
        CodexOAuthService.accountIdFromToken(
          OAuthTokenEntity(accessToken: 'access', issuedAt: DateTime(2026)),
        ),
        isNull,
      );
    });
  });
}

ResponseBody _json(Map<String, Object?> body, [int statusCode = 200]) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

String _jwt(Map<String, Object?> claims) {
  final payload = base64Url.encode(utf8.encode(jsonEncode(claims)));

  return 'header.$payload.signature';
}

final class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({required this.onFetch});

  final Future<ResponseBody> Function(RequestOptions options) onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {
    final _ = Object();
  }
}
