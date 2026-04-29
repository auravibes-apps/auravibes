import 'dart:convert';

import 'package:auravibes_app/services/mcp_service/oauth_discovery.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

void main() {
  group('OAuthDiscoveryResult', () {
    test('stores all fields', () {
      const result = OAuthDiscoveryResult(
        authorizationUrl: 'https://auth.example.com/authorize',
        tokenUrl: 'https://auth.example.com/token',
        clientId: 'client-123',
        scope: 'read write',
      );

      expect(result.authorizationUrl, 'https://auth.example.com/authorize');
      expect(result.tokenUrl, 'https://auth.example.com/token');
      expect(result.clientId, 'client-123');
      expect(result.scope, 'read write');
    });

    test('allows nullable clientId and scope', () {
      const result = OAuthDiscoveryResult(
        authorizationUrl: 'https://auth.example.com/authorize',
        tokenUrl: 'https://auth.example.com/token',
        clientId: null,
        scope: null,
      );

      expect(result.clientId, isNull);
      expect(result.scope, isNull);
    });
  });

  group('OAuthConnector', () {
    test('stores all fields', () {
      const connector = OAuthConnector(
        clientName: 'AuraVibes',
        serverUrl: 'https://mcp.example.com/sse',
        redirectUrl: 'auravibes:///',
      );

      expect(connector.clientName, 'AuraVibes');
      expect(connector.serverUrl, 'https://mcp.example.com/sse');
      expect(connector.redirectUrl, 'auravibes:///');
    });
  });

  group('OAuthDiscoveryService', () {
    test('discoverOAuth returns null when all endpoints return 404', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://example.com/sse',
        redirectUrl: 'https://example.com/callback',
      );

      await runWithClient(() async {
        final result = await OAuthDiscoveryService.discoverOAuth(registrer);
        expect(result, isNull);
      }, () => MockClient((request) async => Response('{}', 404)));
    });

    test('discoverOAuth returns null for invalid URL', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'not-a-valid-url',
        redirectUrl: 'https://example.com/callback',
      );

      final result = await OAuthDiscoveryService.discoverOAuth(registrer);
      expect(result, isNull);
    });

    test('discoverOAuth finds OAuth via well-known endpoint', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://example.com/sse',
        redirectUrl: 'https://example.com/callback',
      );

      await runWithClient(
        () async {
          final result = await OAuthDiscoveryService.discoverOAuth(registrer);
          expect(result, isNotNull);
          expect(
            result!.authorizationUrl,
            'https://auth.example.com/authorize',
          );
          expect(result.tokenUrl, 'https://auth.example.com/token');
        },
        () {
          return MockClient((request) async {
            if (request.url.path.contains(
              '.well-known/oauth-authorization-server',
            )) {
              return Response(
                json.encode({
                  'authorization_endpoint':
                      'https://auth.example.com/authorize',
                  'token_endpoint': 'https://auth.example.com/token',
                }),
                200,
              );
            }
            return Response('{}', 404);
          });
        },
      );
    });

    test('discoverOAuth finds OAuth with scope from well-known', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://example.com/sse',
        redirectUrl: 'https://example.com/callback',
      );

      await runWithClient(
        () async {
          final result = await OAuthDiscoveryService.discoverOAuth(registrer);
          expect(result, isNotNull);
          expect(result!.scope, 'read write');
          expect(result.clientId, isNull);
        },
        () {
          return MockClient((request) async {
            if (request.url.path.contains(
              '.well-known/oauth-authorization-server',
            )) {
              return Response(
                json.encode({
                  'authorization_endpoint':
                      'https://auth.example.com/authorize',
                  'token_endpoint': 'https://auth.example.com/token',
                  'scope': 'read write',
                }),
                200,
              );
            }
            return Response('{}', 404);
          });
        },
      );
    });

    test('discoverOAuth finds OAuth via direct server probe 401', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://example.com/sse',
        redirectUrl: 'https://example.com/callback',
      );

      await runWithClient(
        () async {
          final result = await OAuthDiscoveryService.discoverOAuth(registrer);
          expect(result, isNotNull);
          expect(
            result!.authorizationUrl,
            'https://auth.example.com/authorize',
          );
        },
        () {
          return MockClient((request) async {
            if (request.url.path.contains('/sse')) {
              return Response(
                json.encode({
                  'authorization_url': 'https://auth.example.com/authorize',
                  'token_url': 'https://auth.example.com/token',
                }),
                401,
              );
            }
            return Response('{}', 404);
          });
        },
      );
    });

    test('discoverOAuth finds OAuth via metadata endpoint', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://example.com/api',
        redirectUrl: 'https://example.com/callback',
      );

      await runWithClient(
        () async {
          final result = await OAuthDiscoveryService.discoverOAuth(registrer);
          expect(result, isNotNull);
          expect(
            result!.authorizationUrl,
            'https://auth.example.com/authorize',
          );
          expect(result.tokenUrl, 'https://auth.example.com/token');
        },
        () {
          return MockClient((request) async {
            if (request.url.path.contains('/oauth/metadata')) {
              return Response(
                json.encode({
                  'authorization_url': 'https://auth.example.com/authorize',
                  'token_url': 'https://auth.example.com/token',
                }),
                200,
              );
            }
            return Response('{}', 404);
          });
        },
      );
    });

    test('discoverOAuth registers client dynamically', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://example.com/sse',
        redirectUrl: 'https://example.com/callback',
      );

      await runWithClient(
        () async {
          final result = await OAuthDiscoveryService.discoverOAuth(registrer);
          expect(result, isNotNull);
          expect(result!.clientId, 'dynamic-client-123');
        },
        () {
          return MockClient((request) async {
            if (request.url.path.contains(
              '.well-known/oauth-authorization-server',
            )) {
              return Response(
                json.encode({
                  'authorization_endpoint':
                      'https://auth.example.com/authorize',
                  'token_endpoint': 'https://auth.example.com/token',
                  'registration_endpoint': 'https://auth.example.com/register',
                }),
                200,
              );
            }
            if (request.url.path.contains('/register')) {
              return Response(
                json.encode({'client_id': 'dynamic-client-123'}),
                201,
              );
            }
            return Response('{}', 404);
          });
        },
      );
    });

    test('discoverOAuth handles well-known missing endpoints', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://example.com/sse',
        redirectUrl: 'https://example.com/callback',
      );

      await runWithClient(
        () async {
          final result = await OAuthDiscoveryService.discoverOAuth(registrer);
          expect(result, isNull);
        },
        () {
          return MockClient((request) async {
            if (request.url.path.contains(
              '.well-known/oauth-authorization-server',
            )) {
              return Response(
                json.encode({
                  'authorization_endpoint':
                      'https://auth.example.com/authorize',
                }),
                200,
              );
            }
            return Response('{}', 404);
          });
        },
      );
    });

    test('discoverOAuth finds OAuth via direct probe bearer header', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://example.com/sse',
        redirectUrl: 'https://example.com/callback',
      );

      await runWithClient(
        () async {
          final result = await OAuthDiscoveryService.discoverOAuth(registrer);
          expect(result, isNotNull);
          expect(result!.authorizationUrl, 'https://auth.example.com/auth');
          expect(result.tokenUrl, 'https://auth.example.com/token');
        },
        () {
          return MockClient((request) async {
            if (request.url.path.contains('/sse')) {
              return Response(
                '',
                200,
                headers: {
                  'www-authenticate': 'Bearer realm="mcp"',
                  'x-oauth-authorization-url': 'https://auth.example.com/auth',
                  'x-oauth-token-url': 'https://auth.example.com/token',
                  'x-oauth-client-id': 'test-client',
                },
              );
            }
            return Response('{}', 404);
          });
        },
      );
    });

    test(
      'discoverOAuth returns null for dynamic registration failure',
      () async {
        const registrer = OAuthConnector(
          clientName: 'TestApp',
          serverUrl: 'https://example.com/sse',
          redirectUrl: 'https://example.com/callback',
        );

        await runWithClient(
          () async {
            final result = await OAuthDiscoveryService.discoverOAuth(registrer);
            expect(result, isNotNull);
            expect(result!.clientId, isNull);
          },
          () {
            return MockClient((request) async {
              if (request.url.path.contains(
                '.well-known/oauth-authorization-server',
              )) {
                return Response(
                  json.encode({
                    'authorization_endpoint':
                        'https://auth.example.com/authorize',
                    'token_endpoint': 'https://auth.example.com/token',
                    'registration_endpoint':
                        'https://auth.example.com/register',
                  }),
                  200,
                );
              }
              if (request.url.path.contains('/register')) {
                return Response('{"error": "forbidden"}', 403);
              }
              return Response('{}', 404);
            });
          },
        );
      },
    );

    test('discoverOAuth returns null for non-SSE/MCP server probe', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://example.com/api/data',
        redirectUrl: 'https://example.com/callback',
      );

      await runWithClient(
        () async {
          final result = await OAuthDiscoveryService.discoverOAuth(registrer);
          expect(result, isNull);
        },
        () {
          return MockClient((request) async => Response('{}', 404));
        },
      );
    });

    test('discoverOAuth handles direct probe 401 with non-JSON body', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://example.com/sse',
        redirectUrl: 'https://example.com/callback',
      );

      await runWithClient(
        () async {
          final result = await OAuthDiscoveryService.discoverOAuth(registrer);
          expect(result, isNull);
        },
        () {
          return MockClient((request) async {
            if (request.url.path.contains('/sse')) {
              return Response('Not JSON', 401);
            }
            return Response('{}', 404);
          });
        },
      );
    });
  });
}
