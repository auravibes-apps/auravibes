import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/services/mcp_service/oauth_authenticate.dart';
import 'package:auravibes_app/services/mcp_service/oauth_discovery.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OauthAuthenticate', () {
    test('stores callbackUrlScheme and clientName', () {
      final auth = OauthAuthenticate(
        callbackUrlScheme: 'auravibes',
        clientName: 'AuraVibes',
      );

      expect(auth.callbackUrlScheme, 'auravibes');
      expect(auth.clientName, 'AuraVibes');
    });

    test('can be constructed', () {
      expect(
        () => OauthAuthenticate(
          callbackUrlScheme: 'myapp',
          clientName: 'MyApp',
        ),
        returnsNormally,
      );
    });

    group('validateGetCode', () {
      test('returns code when URL has valid code and matching state', () {
        final code = OauthAuthenticate.validateGetCode(
          urlResult: 'test:/?state=abc123&code=auth_code_123',
          stateParam: 'abc123',
        );

        expect(code, 'auth_code_123');
      });

      test('returns code regardless of parameter order', () {
        final code = OauthAuthenticate.validateGetCode(
          urlResult: 'test:/?code=auth_code&state=mystate',
          stateParam: 'mystate',
        );

        expect(code, 'auth_code');
      });

      test('throws when error parameter is present', () {
        expect(
          () => OauthAuthenticate.validateGetCode(
            urlResult:
                'test:/?error=access_denied&error_description=User+cancelled',
            stateParam: 'abc123',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              allOf(contains('access_denied'), contains('User cancelled')),
            ),
          ),
        );
      });

      test('throws when error is present without description', () {
        expect(
          () => OauthAuthenticate.validateGetCode(
            urlResult: 'test:/?error=unauthorized',
            stateParam: 'abc123',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('unauthorized'),
            ),
          ),
        );
      });

      test('throws when state parameter does not match', () {
        expect(
          () => OauthAuthenticate.validateGetCode(
            urlResult: 'test:/?state=wrong_state&code=auth_code',
            stateParam: 'expected_state',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('state mismatch'),
            ),
          ),
        );
      });

      test('throws when state is missing from URL', () {
        expect(
          () => OauthAuthenticate.validateGetCode(
            urlResult: 'test:/?code=auth_code',
            stateParam: 'expected_state',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('state mismatch'),
            ),
          ),
        );
      });

      test('throws when code parameter is missing', () {
        expect(
          () => OauthAuthenticate.validateGetCode(
            urlResult: 'test:/?state=abc123',
            stateParam: 'abc123',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('code not found'),
            ),
          ),
        );
      });

      test('throws when code parameter is empty', () {
        expect(
          () => OauthAuthenticate.validateGetCode(
            urlResult: 'test:/?state=abc123&code=',
            stateParam: 'abc123',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('code not found'),
            ),
          ),
        );
      });
    });

    group('generateCodeChallenge', () {
      test('produces base64url string without padding', () {
        final challenge = OauthAuthenticate.generateCodeChallenge(
          'test_verifier',
        );

        expect(challenge, isNot(contains('=')));
      });

      test('output is valid base64url', () {
        final challenge = OauthAuthenticate.generateCodeChallenge(
          'test_verifier',
        );
        final padded = challenge.padRight((challenge.length + 3) ~/ 4 * 4, '=');

        expect(() => base64Url.decode(padded), returnsNormally);
      });

      test('is deterministic for same input', () {
        final a = OauthAuthenticate.generateCodeChallenge('same_input');
        final b = OauthAuthenticate.generateCodeChallenge('same_input');

        expect(a, b);
      });

      test('different inputs produce different outputs', () {
        final a = OauthAuthenticate.generateCodeChallenge('input_a');
        final b = OauthAuthenticate.generateCodeChallenge('input_b');

        expect(a, isNot(b));
      });

      test('matches RFC 7636 test vector', () {
        final challenge = OauthAuthenticate.generateCodeChallenge(
          'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk',
        );

        expect(challenge, 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM');
      });

      test('handles empty string', () {
        final challenge = OauthAuthenticate.generateCodeChallenge('');

        expect(challenge, isNotEmpty);
        expect(challenge, isNot(contains('=')));
      });

      test(
        'produces different results for sequential calls with different inputs',
        () {
          final a = OauthAuthenticate.generateCodeChallenge('input1');
          final b = OauthAuthenticate.generateCodeChallenge('input2');
          final c = OauthAuthenticate.generateCodeChallenge('input3');
          expect({a, b, c}.length, 3);
        },
      );

      test('handles long input string', () {
        final longInput = 'a' * 1000;
        final challenge = OauthAuthenticate.generateCodeChallenge(longInput);
        expect(challenge, isNotEmpty);
        expect(challenge, isNot(contains('=')));
      });
    });

    group('generateCodeChallenge', () {
      test('generated verifier-like values are URL-safe and PKCE-sized', () {
        final values = List.generate(
          10,
          (_) => OauthAuthenticate.generateCodeChallenge(
            DateTime.now().microsecondsSinceEpoch.toString(),
          ),
        );

        final allowed = RegExp(r'^[A-Za-z0-9\-_]+$');
        for (final value in values) {
          expect(value, isNotEmpty);
          expect(value.length, inInclusiveRange(43, 128));
          expect(value, matches(allowed));
          expect(value, isNot(contains('=')));
          expect(value, isNot(contains('+')));
          expect(value, isNot(contains('/')));
        }
      });

      test('sequential generations produce varied values', () {
        final results = List.generate(
          12,
          (_) => OauthAuthenticate.generateCodeChallenge(
            DateTime.now().microsecondsSinceEpoch.toString(),
          ),
        );

        expect(results.toSet().length, greaterThan(1));
      });
    });

    group('exchangeCodeForToken', () {
      test('uses injected dio instance for token exchange', () async {
        final adapter = _FakeHttpClientAdapter(
          onFetch: (options, _, _) async {
            expect(
              options.responseType,
              ResponseType.json,
            );
            return ResponseBody.fromString(
              '{"access_token":"token-123","token_type":"Bearer"}',
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final auth = OauthAuthenticate(
          callbackUrlScheme: 'auravibes',
          clientName: 'AuraVibes',
          dio: dio,
        );

        final token = await auth.exchangeCodeForToken(
          code: 'auth-code',
          oAuthResult: const OAuthDiscoveryResult(
            authorizationUrl: 'https://example.com/authorize',
            tokenUrl: 'https://example.com/token',
            clientId: 'client-id',
            scope: null,
          ),
          codeVerifier: 'verifier',
          redirectUrl: 'auravibes:/',
        );

        expect(token.accessToken, 'token-123');
        expect(token.tokenType, 'Bearer');
      });
    });
  });
}

typedef _FetchCallback =
    Future<ResponseBody> Function(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture,
    );

final class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({required _FetchCallback onFetch})
    : _onFetch = onFetch;

  final _FetchCallback _onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _onFetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}
