import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/services/mcp_service/oauth_authenticate.dart';
import 'package:auravibes_app/services/mcp_service/oauth_discovery.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _FetchCallback =
    Future<ResponseBody> Function(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture,
    );

final class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({required _FetchCallback onFetch})
    : _fetchCallback = onFetch;

  final _FetchCallback _fetchCallback;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _fetchCallback(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('OAuthAuthenticate', () {
    test('stores callbackUrlScheme and clientName', () {
      final auth = OAuthAuthenticate(
        callbackUrlScheme: 'auravibes',
        clientName: 'AuraVibes',
      );

      expect(auth.callbackUrlScheme, 'auravibes');
      expect(auth.clientName, 'AuraVibes');
    });

    test('can be constructed', () {
      expect(
        () => OAuthAuthenticate(
          callbackUrlScheme: 'myapp',
          clientName: 'MyApp',
        ),
        returnsNormally,
      );
    });

    group('validateGetCode', () {
      test('returns code when URL has valid code and matching state', () {
        final code = OAuthAuthenticate.validateGetCode(
          urlResult: 'test:/?state=abc123&code=auth_code_123',
          stateParam: 'abc123',
        );

        expect(code, 'auth_code_123');
      });

      test('returns code regardless of parameter order', () {
        final code = OAuthAuthenticate.validateGetCode(
          urlResult: 'test:/?code=auth_code&state=mystate',
          stateParam: 'mystate',
        );

        expect(code, 'auth_code');
      });

      test('throws when error parameter is present', () {
        expect(
          () => OAuthAuthenticate.validateGetCode(
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
          () => OAuthAuthenticate.validateGetCode(
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
          () => OAuthAuthenticate.validateGetCode(
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
          () => OAuthAuthenticate.validateGetCode(
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
          () => OAuthAuthenticate.validateGetCode(
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
          () => OAuthAuthenticate.validateGetCode(
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
        final challenge = OAuthAuthenticate.generateCodeChallenge(
          'test_verifier',
        );

        expect(challenge, isNot(contains('=')));
      });

      test('output is valid base64url', () {
        final challenge = OAuthAuthenticate.generateCodeChallenge(
          'test_verifier',
        );
        final padded = challenge.padRight((challenge.length + 3) ~/ 4 * 4, '=');

        expect(() => base64Url.decode(padded), returnsNormally);
      });

      test('is deterministic for same input', () {
        final a = OAuthAuthenticate.generateCodeChallenge('same_input');
        final b = OAuthAuthenticate.generateCodeChallenge('same_input');

        expect(a, b);
      });

      test('different inputs produce different outputs', () {
        final a = OAuthAuthenticate.generateCodeChallenge('input_a');
        final b = OAuthAuthenticate.generateCodeChallenge('input_b');

        expect(a, isNot(b));
      });

      test('matches RFC 7636 test vector', () {
        final challenge = OAuthAuthenticate.generateCodeChallenge(
          'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk',
        );

        expect(challenge, 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM');
      });

      test('handles empty string', () {
        final challenge = OAuthAuthenticate.generateCodeChallenge('');

        expect(challenge, isNotEmpty);
        expect(challenge, isNot(contains('=')));
      });

      test(
        'produces different results for sequential calls with different inputs',
        () {
          final a = OAuthAuthenticate.generateCodeChallenge('input1');
          final b = OAuthAuthenticate.generateCodeChallenge('input2');
          final c = OAuthAuthenticate.generateCodeChallenge('input3');
          expect({a, b, c}.length, 3);
        },
      );

      test('handles long input string', () {
        final longInput = 'a' * 1000;
        final challenge = OAuthAuthenticate.generateCodeChallenge(longInput);
        expect(challenge, isNotEmpty);
        expect(challenge, isNot(contains('=')));
      });
    });

    group('generateCodeChallenge variability', () {
      test('generated verifier-like values are URL-safe and PKCE-sized', () {
        final values = List.generate(
          10,
          (i) => OAuthAuthenticate.generateCodeChallenge('seed_$i'),
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
          (index) => OAuthAuthenticate.generateCodeChallenge('seed-$index'),
        );

        expect(results.toSet().length, results.length);
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
            expect(options.method, 'POST');
            expect(options.path, 'https://example.com/token');

            final data = options.data;
            final Map<String, dynamic> body;
            if (data is FormData) {
              body = {
                for (final field in data.fields) field.key: field.value,
              };
            } else if (data is Map) {
              body = Map<String, dynamic>.from(data);
            } else {
              fail('Unexpected token request body type: ${data.runtimeType}');
            }

            expect(body['grant_type'], 'authorization_code');
            expect(body['code'], 'auth-code');
            expect(body['code_verifier'], 'verifier');
            expect(body['redirect_uri'], 'auravibes:/');
            expect(body['client_id'], 'client-id');

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
        final auth = OAuthAuthenticate(
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

      test(
        'throws when token exchange fails due to network/client error',
        () async {
          final adapter = _FakeHttpClientAdapter(
            onFetch: (_, _, _) async {
              throw DioException(
                requestOptions: RequestOptions(
                  path: 'https://example.com/token',
                ),
                type: DioExceptionType.connectionError,
                error: 'network down',
              );
            },
          );
          final dio = Dio()..httpClientAdapter = adapter;
          final auth = OAuthAuthenticate(
            callbackUrlScheme: 'auravibes',
            clientName: 'AuraVibes',
            dio: dio,
          );

          await expectLater(
            () => auth.exchangeCodeForToken(
              code: 'auth-code',
              oAuthResult: const OAuthDiscoveryResult(
                authorizationUrl: 'https://example.com/authorize',
                tokenUrl: 'https://example.com/token',
                clientId: 'client-id',
                scope: null,
              ),
              codeVerifier: 'verifier',
              redirectUrl: 'auravibes:/',
            ),
            throwsA(
              isA<DioException>().having(
                (error) => error.type,
                'type',
                DioExceptionType.connectionError,
              ),
            ),
          );
        },
      );

      test('throws when token response is missing required fields', () async {
        final adapter = _FakeHttpClientAdapter(
          onFetch: (_, _, _) async {
            return ResponseBody.fromString(
              '{"token_type":"Bearer"}',
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final auth = OAuthAuthenticate(
          callbackUrlScheme: 'auravibes',
          clientName: 'AuraVibes',
          dio: dio,
        );

        await expectLater(
          () => auth.exchangeCodeForToken(
            code: 'auth-code',
            oAuthResult: const OAuthDiscoveryResult(
              authorizationUrl: 'https://example.com/authorize',
              tokenUrl: 'https://example.com/token',
              clientId: 'client-id',
              scope: null,
            ),
            codeVerifier: 'verifier',
            redirectUrl: 'auravibes:/',
          ),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('access_token'),
            ),
          ),
        );
      });

      test('throws when token response is not a JSON object', () async {
        final adapter = _FakeHttpClientAdapter(
          onFetch: (_, _, _) async {
            return ResponseBody.fromString(
              '["not-an-object"]',
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final auth = OAuthAuthenticate(
          callbackUrlScheme: 'auravibes',
          clientName: 'AuraVibes',
          dio: dio,
        );

        await expectLater(
          () => auth.exchangeCodeForToken(
            code: 'auth-code',
            oAuthResult: const OAuthDiscoveryResult(
              authorizationUrl: 'https://example.com/authorize',
              tokenUrl: 'https://example.com/token',
              clientId: 'client-id',
              scope: null,
            ),
            codeVerifier: 'verifier',
            redirectUrl: 'auravibes:/',
          ),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('JSON object'),
            ),
          ),
        );
      });

      test('handles token response with optional OAuth fields', () async {
        final adapter = _FakeHttpClientAdapter(
          onFetch: (_, _, _) async {
            return ResponseBody.fromString(
              jsonEncode(<String, Object?>{
                'access_token': 'access-token',
                'token_type': 'Bearer',
                'refresh_token': 'refresh-token',
                'expires_in': 3600,
                'scope': 'profile email',
              }),
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final auth = OAuthAuthenticate(
          callbackUrlScheme: 'auravibes',
          clientName: 'AuraVibes',
          dio: dio,
        );

        final result = await auth.exchangeCodeForToken(
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

        expect(result.accessToken, 'access-token');
        expect(result.tokenType, 'Bearer');
        expect(result.refreshToken, 'refresh-token');
        expect(result.expiresIn, 3600);
        expect(result.scope, 'profile email');
      });
    });
  });
}
