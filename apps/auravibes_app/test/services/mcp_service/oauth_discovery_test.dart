// Required: Existing test and UI helpers keep compact return flow.

import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/services/mcp_service/o_auth_discovery_result.dart';
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

    test('withClientId preserves discovery metadata', () {
      const result = OAuthDiscoveryResult(
        authorizationUrl: 'https://auth.example.com/authorize',
        tokenUrl: 'https://auth.example.com/token',
        clientId: null,
        scope: 'read write',
        resource: 'https://mcp.example.com/',
        issuer: 'https://auth.example.com',
        deviceAuthorizationUrl: 'https://auth.example.com/device',
        supportsDynamicClientRegistration: true,
        scopes: ['read', 'write'],
        authorizationResponseIssuerSupported: true,
      );

      final configured = result.withClientId('client-id');

      expect(configured.clientId, 'client-id');
      expect(configured.authorizationUrl, result.authorizationUrl);
      expect(configured.tokenUrl, result.tokenUrl);
      expect(configured.scope, result.scope);
      expect(configured.resource, result.resource);
      expect(configured.issuer, result.issuer);
      expect(configured.deviceAuthorizationUrl, result.deviceAuthorizationUrl);
      expect(configured.supportsDynamicClientRegistration, isTrue);
      expect(configured.scopes, result.scopes);
      expect(configured.authorizationResponseIssuerSupported, isTrue);
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
            (result ?? fail('Expected result to be non-null')).authorizationUrl,
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
          expect(
            (result ?? fail('Expected result to be non-null')).scope,
            'read write',
          );
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

    test('discoverOAuth ignores OAuth-shaped direct 401 bodies', () async {
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
            (result ?? fail('Expected result to be non-null')).authorizationUrl,
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

    test('discoverOAuth registers clients from legacy metadata', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://example.com/api',
        redirectUrl: 'auravibes:/',
      );

      await runWithClient(
        () async {
          final result = await OAuthDiscoveryService.discoverOAuth(
            registrer,
            registrationClient: .new(),
          );

          expect(result, isNotNull);
          expect(result?.clientId, 'legacy-dynamic-client');
        },
        () {
          return MockClient((request) async {
            if (request.url.path.contains('/oauth/metadata')) {
              return Response(
                json.encode({
                  'authorization_url': 'https://auth.example.com/authorize',
                  'token_url': 'https://auth.example.com/token',
                  'registration_endpoint': 'https://8.8.8.8/register',
                }),
                HttpStatus.ok,
                headers: {'content-type': 'application/json'},
              );
            }
            if (request.url.path.contains('/register')) {
              return Response(
                json.encode({'client_id': 'legacy-dynamic-client'}),
                HttpStatus.created,
                headers: {'content-type': 'application/json'},
              );
            }

            return Response('{}', HttpStatus.notFound);
          });
        },
      );
    });

    test('discoverOAuth registers client dynamically', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://example.com/sse',
        redirectUrl: 'auravibes:/',
      );
      Map<String, dynamic>? registrationMetadata;

      await runWithClient(
        () async {
          final result = await OAuthDiscoveryService.discoverOAuth(
            registrer,
            registrationClient: .new(),
          );
          if (result == null) {
            fail('Expected result to be non-null');
          }
          expect(result.clientId, 'dynamic-client-123');
          expect(result.supportsDynamicClientRegistration, isTrue);
          expect(registrationMetadata, {
            'client_name': 'TestApp',
            'redirect_uris': ['auravibes:/'],
            'grant_types': ['authorization_code', 'refresh_token'],
            'response_types': ['code'],
            'token_endpoint_auth_method': 'none',
            'application_type': 'native',
          });
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
                  'registration_endpoint': 'https://8.8.8.8/register',
                }),
                200,
              );
            }
            if (request.url.path.contains('/register')) {
              registrationMetadata = Map<String, dynamic>.from(
                json.decode(request.body) as Map,
              );

              return Response(
                json.encode({'client_id': 'dynamic-client-123'}),
                201,
                headers: {'content-type': 'application/json'},
              );
            }

            return Response('{}', 404);
          });
        },
      );
    });

    test(
      'discoverOAuth ignores malformed successful registration responses',
      () async {
        const registrer = OAuthConnector(
          clientName: 'TestApp',
          serverUrl: 'https://example.com/sse',
          redirectUrl: 'auravibes:/',
        );

        await runWithClient(
          () async {
            final result = await OAuthDiscoveryService.discoverOAuth(
              registrer,
              registrationClient: .new(),
            );

            expect(result, isNotNull);
            expect(result?.clientId, isNull);
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
                    'registration_endpoint': 'https://8.8.8.8/register',
                  }),
                  HttpStatus.ok,
                  headers: {'content-type': 'application/json'},
                );
              }
              if (request.url.path.contains('/register')) {
                return Response('<html>not json</html>', HttpStatus.ok);
              }

              return Response('{}', HttpStatus.notFound);
            });
          },
        );
      },
    );

    test(
      'discoverOAuth rejects private dynamic registration endpoints',
      () async {
        const registrer = OAuthConnector(
          clientName: 'TestApp',
          serverUrl: 'https://example.com/sse',
          redirectUrl: 'https://example.com/callback',
        );
        var registrationAttempted = false;

        await runWithClient(
          () async {
            final result = await OAuthDiscoveryService.discoverOAuth(registrer);
            expect(result, isNotNull);
            expect(
              (result ?? fail('Expected result to be non-null')).clientId,
              isNull,
            );
            expect(registrationAttempted, isFalse);
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
                    'registration_endpoint': 'https://127.0.0.1/register',
                  }),
                  200,
                );
              }
              if (request.url.path.contains('/register')) {
                registrationAttempted = true;

                return Response(
                  json.encode({'client_id': 'private-client-123'}),
                  201,
                );
              }

              return Response('{}', 404);
            });
          },
        );
      },
    );

    test('discoverOAuth disables redirects for dynamic registration', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://example.com/sse',
        redirectUrl: 'https://example.com/callback',
      );
      var registrationRequests = 0;
      var registrationFollowRedirects = true;

      await runWithClient(
        () async {
          final result = await OAuthDiscoveryService.discoverOAuth(
            registrer,
            registrationClient: .new(),
          );
          expect(result, isNotNull);
          expect(
            (result ?? fail('Expected result to be non-null')).clientId,
            isNull,
          );
          expect(registrationRequests, 1);
          expect(registrationFollowRedirects, isFalse);
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
                  'registration_endpoint': 'https://8.8.8.8/register',
                }),
                HttpStatus.ok,
              );
            }
            if (request.url.path.contains('/register')) {
              registrationRequests++;
              registrationFollowRedirects = request.followRedirects;

              return Response(
                '',
                HttpStatus.temporaryRedirect,
                headers: {'location': 'https://127.0.0.1/register'},
              );
            }

            return Response('{}', HttpStatus.notFound);
          });
        },
      );
    });

    test('discoverOAuth pins all resolved registration addresses', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://example.com/sse',
        redirectUrl: 'https://example.com/callback',
      );
      final attemptedAddresses = <String>[];
      var injectedClientUsed = false;
      final registrationClient = MockClient((request) async {
        injectedClientUsed = true;

        return Response(
          json.encode({'client_id': 'injected-client'}),
          HttpStatus.created,
        );
      });

      final result = await IOOverrides.runZoned(
        () => runWithClient(
          () => OAuthDiscoveryService.discoverOAuth(
            registrer,
            registrationClient: registrationClient,
            registrationLookup: (_) async => [
              InternetAddress('8.8.8.8'),
              InternetAddress('1.1.1.1'),
            ],
          ),
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
                        'https://registration.example/register',
                  }),
                  HttpStatus.ok,
                );
              }

              return Response('{}', HttpStatus.notFound);
            });
          },
        ),
        socketConnect: (host, port, {sourceAddress, sourcePort = 0, timeout}) {
          attemptedAddresses.add((host as InternetAddress).address);
          throw const SocketException('blocked in test');
        },
      );

      expect(result, isNotNull);
      expect(result?.clientId, isNull);
      expect(attemptedAddresses, ['8.8.8.8', '1.1.1.1']);
      expect(injectedClientUsed, isFalse);
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
          expect(
            (result ?? fail('Expected result to be non-null')).authorizationUrl,
            'https://auth.example.com/auth',
          );
          expect(result.tokenUrl, 'https://auth.example.com/token');
        },
        () {
          return MockClient((request) async {
            if (request.url.path.contains('/sse')) {
              return Response(
                '',
                401,
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
            final result = await OAuthDiscoveryService.discoverOAuth(
              registrer,
              registrationClient: .new(),
            );
            expect(result, isNotNull);
            expect(
              (result ?? fail('Expected result to be non-null')).clientId,
              isNull,
            );
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
                    'registration_endpoint': 'https://8.8.8.8/register',
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

    test(
      'discoverOAuth follows protected-resource and path-aware metadata',
      () async {
        const registrer = OAuthConnector(
          clientName: 'TestApp',
          serverUrl: 'https://api.githubcopilot.com/mcp/',
          redirectUrl: 'https://example.com/callback',
        );

        final metadataRedirectSettings = <bool>[];
        final client = MockClient((request) async {
          if (request.url.path == '/mcp/') {
            const resourceMetadata =
                'https://api.githubcopilot.com/.well-known/'
                'oauth-protected-resource/mcp/';

            return Response(
              '',
              401,
              headers: {
                'www-authenticate':
                    'Bearer resource_metadata="$resourceMetadata", '
                    'scope="repo read:user"',
              },
            );
          }
          if (request.url.path ==
              '/.well-known/oauth-protected-resource/mcp/') {
            metadataRedirectSettings.add(request.followRedirects);

            return Response(
              json.encode({
                'resource': 'https://api.githubcopilot.com/mcp/',
                'authorization_servers': ['https://github.com/login/oauth'],
                'scopes_supported': ['repo', 'read:org'],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path ==
              '/.well-known/oauth-authorization-server/login/oauth') {
            metadataRedirectSettings.add(request.followRedirects);

            return Response(
              json.encode({
                'issuer': 'https://github.com/login/oauth',
                'authorization_endpoint':
                    'https://github.com/login/oauth/authorize',
                'token_endpoint': 'https://github.com/login/oauth/access_token',
                'device_authorization_endpoint':
                    'https://github.com/login/device/code',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return Response('{}', 404);
        });

        await runWithClient(() async {
          final result = await OAuthDiscoveryService.discoverOAuth(
            registrer,
            metadataClient: client,
            metadataLookup: (_) async => [InternetAddress('8.8.8.8')],
          );
          expect(result, isNotNull);
          expect(result?.resource, 'https://api.githubcopilot.com/mcp/');
          expect(result?.issuer, 'https://github.com/login/oauth');
          expect(
            result?.authorizationUrl,
            'https://github.com/login/oauth/authorize',
          );
          expect(
            result?.deviceAuthorizationUrl,
            'https://github.com/login/device/code',
          );
          expect(result?.supportsDynamicClientRegistration, isFalse);
          expect(result?.scope, 'repo read:user');
          expect(metadataRedirectSettings, everyElement(isFalse));
        }, () => client);
      },
    );

    test('discoverOAuth rejects private protected-resource hosts', () async {
      const registrer = OAuthConnector(
        clientName: 'TestApp',
        serverUrl: 'https://mcp.example.com/sse',
        redirectUrl: 'https://example.com/callback',
      );
      var privateMetadataRequested = false;
      final client = MockClient((request) async {
        if (request.url.host == 'internal.example.com') {
          privateMetadataRequested = true;
        }
        if (request.url.path == '/sse') {
          return Response(
            '',
            401,
            headers: {
              'www-authenticate': 'Bearer resource_metadata="https://internal.example.com/metadata"',
            },
          );
        }

        return Response('{}', 404);
      });

      await runWithClient(() async {
        final result = await OAuthDiscoveryService.discoverOAuth(
          registrer,
          metadataClient: client,
          metadataLookup: (host) async => [
            InternetAddress(
              host == 'internal.example.com' ? '127.0.0.1' : '8.8.8.8',
            ),
          ],
        );

        expect(result, isNull);
        expect(privateMetadataRequested, isFalse);
      }, () => client);
    });
  });
}
