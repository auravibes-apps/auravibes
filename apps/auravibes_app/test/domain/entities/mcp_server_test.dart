import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('McpTransportType', () {
    test('fromJson parses SSE type', () {
      final json = <String, dynamic>{'type': 'sse'};
      final transport = McpTransportType.fromJson(json);
      expect(transport, isA<McpTransportTypeSSE>());
    });

    test('fromJson parses streamableHttp type', () {
      final json = <String, dynamic>{
        'type': 'streamableHttp',
        'useHttp2': true,
      };
      final transport = McpTransportType.fromJson(json);
      expect(transport, isA<McpTransportTypeStreamableHttp>());
      expect((transport as McpTransportTypeStreamableHttp).useHttp2, isTrue);
    });

    test('fromJson throws for unknown type', () {
      final json = <String, dynamic>{'type': 'unknown'};
      expect(() => McpTransportType.fromJson(json), throwsUnsupportedError);
    });

    test('SSE toJson', () {
      const transport = McpTransportTypeSSE();
      expect(transport.toJson(), {'type': 'sse'});
    });

    test('streamableHttp toJson', () {
      const transport = McpTransportTypeStreamableHttp(useHttp2: true);
      expect(
        transport.toJson(),
        {'type': 'streamableHttp', 'useHttp2': true},
      );
    });
  });

  group('McpServerToCreate', () {
    test('slugServerName creates URL-safe slug', () {
      const create = McpServerToCreate(
        name: 'My Server!',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeNone(),
      );
      expect(create.slugServerName, 'my_server_');
    });

    test('slugServerName lowercases and replaces non-alphanumeric', () {
      const create = McpServerToCreate(
        name: 'Hello World 2025',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeNone(),
      );
      expect(create.slugServerName, 'hello_world_2025');
    });
  });

  group('McpServerEntity', () {
    final server = McpServerEntity(
      id: 'srv_1',
      workspaceId: 'ws_1',
      name: 'My Server',
      url: 'http://localhost:8080',
      transport: const McpTransportTypeSSE(),
      authenticationType: const McpAuthenticationTypeNone(),
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

    test('basic fields', () {
      expect(server.id, 'srv_1');
      expect(server.workspaceId, 'ws_1');
      expect(server.name, 'My Server');
      expect(server.url, 'http://localhost:8080');
    });

    test('isEnabled defaults to true', () {
      expect(server.isEnabled, isTrue);
    });

    test('description is optional', () {
      expect(server.description, isNull);
    });
  });

  group('McpAuthenticationTypeOptions', () {
    test('has none, oauth, bearerToken', () {
      expect(McpAuthenticationTypeOptions.none, isNotNull);
      expect(McpAuthenticationTypeOptions.oauth, isNotNull);
      expect(McpAuthenticationTypeOptions.bearerToken, isNotNull);
    });
  });

  group('McpTransportTypeOptions', () {
    test('has streamableHttp, sse', () {
      expect(McpTransportTypeOptions.streamableHttp, isNotNull);
      expect(McpTransportTypeOptions.sse, isNotNull);
    });
  });

  group('McpServerFormToCreate', () {
    test('isValid true for none auth with name and url', () {
      const form = McpServerFormToCreate(
        name: 'Server',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.none,
        bearerToken: null,
      );
      expect(form.isValid, isTrue);
    });

    test('isValid false when name is empty', () {
      const form = McpServerFormToCreate(
        name: '',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.none,
        bearerToken: null,
      );
      expect(form.isValid, isFalse);
    });

    test('isValid false when url is empty', () {
      const form = McpServerFormToCreate(
        name: 'Server',
        url: '',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.none,
        bearerToken: null,
      );
      expect(form.isValid, isFalse);
    });

    test('isValid true for oauth without bearer', () {
      const form = McpServerFormToCreate(
        name: 'Server',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.oauth,
        bearerToken: null,
      );
      expect(form.isValid, isTrue);
    });

    test('isValid true for bearerToken with non-null token', () {
      const form = McpServerFormToCreate(
        name: 'Server',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.bearerToken,
        bearerToken: 'secret',
      );
      expect(form.isValid, isTrue);
    });

    test('isValid false for bearerToken with null token', () {
      const form = McpServerFormToCreate(
        name: 'Server',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.bearerToken,
        bearerToken: null,
      );
      expect(form.isValid, isFalse);
    });

    test('isValid false for bearerToken with empty token', () {
      const form = McpServerFormToCreate(
        name: 'Server',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.bearerToken,
        bearerToken: '',
      );
      expect(form.isValid, isFalse);
    });

    group('validationErrors', () {
      test('empty when name and url are provided', () {
        const form = McpServerFormToCreate(
          name: 'S',
          url: 'http://x',
          transport: McpTransportTypeSSE(),
          authenticationType: McpAuthenticationTypeOptions.none,
          bearerToken: null,
        );
        expect(form.validationErrors, isEmpty);
      });

      test('reports missing name and url', () {
        const form = McpServerFormToCreate(
          name: '',
          url: '',
          transport: McpTransportTypeSSE(),
          authenticationType: McpAuthenticationTypeOptions.none,
          bearerToken: null,
        );
        final errors = form.validationErrors;
        expect(errors, contains('Name is required.'));
        expect(errors, contains('URL is required.'));
        expect(errors.length, 2);
      });

      test('reports bearer token required for bearer auth', () {
        const form = McpServerFormToCreate(
          name: 'S',
          url: 'http://x',
          transport: McpTransportTypeSSE(),
          authenticationType: McpAuthenticationTypeOptions.bearerToken,
          bearerToken: null,
        );
        final errors = form.validationErrors;
        expect(
          errors,
          contains(
            'Bearer token is required for Bearer Token authentication.',
          ),
        );
      });

      test('reports bearer token required for empty bearer auth', () {
        const form = McpServerFormToCreate(
          name: 'S',
          url: 'http://x',
          transport: McpTransportTypeSSE(),
          authenticationType: McpAuthenticationTypeOptions.bearerToken,
          bearerToken: '',
        );
        final errors = form.validationErrors;
        expect(
          errors,
          contains(
            'Bearer token is required for Bearer Token authentication.',
          ),
        );
      });

      test('oauth auth has no errors with valid name and url', () {
        const form = McpServerFormToCreate(
          name: 'S',
          url: 'http://x',
          transport: McpTransportTypeSSE(),
          authenticationType: McpAuthenticationTypeOptions.oauth,
          bearerToken: null,
        );
        expect(form.validationErrors, isEmpty);
      });

      test('none auth has no errors with valid name and url', () {
        const form = McpServerFormToCreate(
          name: 'S',
          url: 'http://x',
          transport: McpTransportTypeSSE(),
          authenticationType: McpAuthenticationTypeOptions.none,
          bearerToken: null,
        );
        expect(form.validationErrors, isEmpty);
      });
    });
  });

  group('OAuthTokenEntity', () {
    test('isOAuthTokenExpired returns true when expiresIn is null', () {
      final token = OAuthTokenEntity(
        accessToken: 'access',
        issuedAt: DateTime(2026),
      );
      expect(token.isOAuthTokenExpired, isTrue);
    });

    test('isOAuthTokenExpired returns true when token is old', () {
      final token = OAuthTokenEntity(
        accessToken: 'access',
        issuedAt: DateTime(2020),
        expiresIn: 60,
      );
      expect(token.isOAuthTokenExpired, isTrue);
    });

    test('isOAuthTokenExpired returns false for fresh token', () {
      final token = OAuthTokenEntity(
        accessToken: 'access',
        issuedAt: DateTime.now(),
        expiresIn: 3600,
      );
      expect(token.isOAuthTokenExpired, isFalse);
    });

    test('needsOAuthTokenRefresh true when expired with refresh token', () {
      final token = OAuthTokenEntity(
        accessToken: 'access',
        issuedAt: DateTime(2020),
        expiresIn: 60,
        refreshToken: 'refresh',
      );
      expect(token.needsOAuthTokenRefresh, isTrue);
    });

    test('needsOAuthTokenRefresh false when expired without refresh token', () {
      final token = OAuthTokenEntity(
        accessToken: 'access',
        issuedAt: DateTime(2020),
        expiresIn: 60,
      );
      expect(token.needsOAuthTokenRefresh, isFalse);
    });

    test('needsOAuthTokenRefresh false for fresh token with refresh token', () {
      final token = OAuthTokenEntity(
        accessToken: 'access',
        issuedAt: DateTime.now(),
        expiresIn: 3600,
        refreshToken: 'refresh',
      );
      expect(token.needsOAuthTokenRefresh, isFalse);
    });

    test('copyCryptor encrypts accessToken and refreshToken', () async {
      final token = OAuthTokenEntity(
        accessToken: 'plain-access',
        issuedAt: DateTime(2026),
        refreshToken: 'plain-refresh',
        expiresIn: 3600,
        tokenType: 'Bearer',
        scopes: ['read'],
      );

      final encrypted = await token.copyCryptor((v) async => 'enc-$v');

      expect(encrypted.accessToken, 'enc-plain-access');
      expect(encrypted.refreshToken, 'enc-plain-refresh');
      expect(encrypted.expiresIn, 3600);
      expect(encrypted.tokenType, 'Bearer');
      expect(encrypted.scopes, ['read']);
    });

    test('copyCryptor handles null refreshToken', () async {
      final token = OAuthTokenEntity(
        accessToken: 'access',
        issuedAt: DateTime(2026),
      );

      final encrypted = await token.copyCryptor((v) async => 'enc-$v');
      expect(encrypted.accessToken, 'enc-access');
      expect(encrypted.refreshToken, isNull);
    });
  });

  group('OAuthTokenModel', () {
    test('toEntity converts correctly', () {
      const model = OAuthTokenModel(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresIn: 3600,
        tokenType: 'Bearer',
        scope: 'read write',
      );

      final entity = model.toEntity();
      expect(entity.accessToken, 'access');
      expect(entity.refreshToken, 'refresh');
      expect(entity.expiresIn, 3600);
      expect(entity.tokenType, 'Bearer');
      expect(entity.scopes, ['read', 'write']);
    });

    test('toEntity handles null optional fields', () {
      const model = OAuthTokenModel(
        accessToken: 'access',
      );

      final entity = model.toEntity();
      expect(entity.accessToken, 'access');
      expect(entity.refreshToken, isNull);
      expect(entity.expiresIn, isNull);
      expect(entity.tokenType, isNull);
      expect(entity.scopes, isNull);
    });
  });

  group('McpAuthenticationType copyCryptor', () {
    test('none returns self', () async {
      const auth = McpAuthenticationTypeNone();
      final result = await auth.copyCryptor((v) async => 'enc-$v');
      expect(result, isA<McpAuthenticationTypeNone>());
    });

    test('bearerToken encrypts token', () async {
      const auth = McpAuthenticationTypeBearerToken(bearerToken: 'secret');
      final result = await auth.copyCryptor((v) async => 'enc-$v');
      expect(result, isA<McpAuthenticationTypeBearerToken>());
      expect(
        (result as McpAuthenticationTypeBearerToken).bearerToken,
        'enc-secret',
      );
    });

    test('oauth encrypts token fields', () async {
      final auth = McpAuthenticationTypeOAuth(
        token: OAuthTokenEntity(
          accessToken: 'access',
          issuedAt: DateTime(2026),
          refreshToken: 'refresh',
        ),
        clientId: 'client-1',
        authorizationEndpoint: 'https://auth.example.com',
        tokenEndpoint: 'https://token.example.com',
      );

      final result = await auth.copyCryptor((v) async => 'enc-$v');
      expect(result, isA<McpAuthenticationTypeOAuth>());
      final oauth = result as McpAuthenticationTypeOAuth;
      expect(oauth.token.accessToken, 'enc-access');
      expect(oauth.token.refreshToken, 'enc-refresh');
      expect(oauth.clientId, 'client-1');
    });
  });

  group('McpServerEntity', () {
    test('copyWith preserves fields', () {
      final server = McpServerEntity(
        id: 'srv_1',
        workspaceId: 'ws_1',
        name: 'My Server',
        url: 'http://localhost:8080',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationTypeNone(),
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      final updated = server.copyWith(name: 'Updated Server');
      expect(updated.name, 'Updated Server');
      expect(updated.id, 'srv_1');
      expect(updated.url, 'http://localhost:8080');
    });

    test('isEnabled can be set to false', () {
      final server = McpServerEntity(
        id: 'srv_1',
        workspaceId: 'ws_1',
        name: 'My Server',
        url: 'http://localhost:8080',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationTypeNone(),
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        isEnabled: false,
      );
      expect(server.isEnabled, isFalse);
    });
  });
}
