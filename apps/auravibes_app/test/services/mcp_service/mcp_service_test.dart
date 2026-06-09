
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/services/mcp_service/mcp_manager_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('McpManagerService', () {
    var service = McpManagerService();

    setUp(() {
      service = McpManagerService();
    });

    test('disconnect does nothing when client is null', () async {
      await expectLater(service.disconnect(null), completes);
    });

    test('can be constructed', () {
      expect(McpManagerService(), isNotNull);
    });
  });

  group('McpTransportType', () {
    test('McpTransportTypeSSE toJson returns correct type', () {
      const transport = McpTransportTypeSSE();
      expect(transport.toJson(), {'type': 'sse'});
    });

    test('McpTransportTypeStreamableHttp toJson includes useHttp2', () {
      const transport = McpTransportTypeStreamableHttp(useHttp2: true);
      expect(transport.toJson(), {'type': 'streamableHttp', 'useHttp2': true});
    });

    test('McpTransportTypeStreamableHttp defaults useHttp2 to false', () {
      const transport = McpTransportTypeStreamableHttp();
      expect(transport.useHttp2, isFalse);
    });

    test('McpTransportType.fromJson creates SSE type', () {
      final transport = McpTransportType.fromJson({'type': 'sse'});
      expect(transport, isA<McpTransportTypeSSE>());
    });

    test('McpTransportType.fromJson creates StreamableHttp type', () {
      final transport = McpTransportType.fromJson({
        'type': 'streamableHttp',
        'useHttp2': true,
      });
      expect(transport, isA<McpTransportTypeStreamableHttp>());
      expect((transport as McpTransportTypeStreamableHttp).useHttp2, isTrue);
    });

    test('McpTransportType.fromJson throws for unknown type', () {
      expect(
        () => McpTransportType.fromJson({'type': 'unknown'}),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('McpServerToCreate', () {
    test('slugServerName lowercases and replaces non-alphanumeric', () {
      const server = McpServerToCreate(
        name: 'My Cool Server!',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationType.none(),
      );
      expect(server.slugServerName, 'my_cool_server_');
    });

    test('slugServerName handles already clean name', () {
      const server = McpServerToCreate(
        name: 'myserver',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationType.none(),
      );
      expect(server.slugServerName, 'myserver');
    });

    test('slugServerName handles spaces and special chars', () {
      const server = McpServerToCreate(
        name: 'Test @ Server #1',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationType.none(),
      );
      expect(server.slugServerName, 'test_server_1');
    });

    test('slugServerName handles consecutive special characters', () {
      const server = McpServerToCreate(
        name: 'A&&B%%C',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationType.none(),
      );
      expect(server.slugServerName, 'a_b_c');
    });

    test('slugServerName handles unicode characters', () {
      final server = McpServerToCreate(
        name: String.fromCharCodes([
          83,
          101,
          114,
          118,
          101,
          117,
          114,
          32,
          70,
          114,
          97,
          110,
          0x00e7,
          97,
          105,
          115,
        ]),
        url: 'http://localhost',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationType.none(),
      );
      expect(server.slugServerName, 'serveur_fran_ais');
    });
  });

  group('McpServerFormToCreate', () {
    test('isValid returns true for none auth with valid fields', () {
      const form = McpServerFormToCreate(
        name: 'Test',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.none,
        bearerToken: null,
      );
      expect(form.isValid, isTrue);
    });

    test('isValid returns false for empty name', () {
      const form = McpServerFormToCreate(
        name: '',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.none,
        bearerToken: null,
      );
      expect(form.isValid, isFalse);
    });

    test('isValid returns false for empty url', () {
      const form = McpServerFormToCreate(
        name: 'Test',
        url: '',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.none,
        bearerToken: null,
      );
      expect(form.isValid, isFalse);
    });

    test('isValid returns true for oauth auth', () {
      const form = McpServerFormToCreate(
        name: 'Test',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.oauth,
        bearerToken: null,
      );
      expect(form.isValid, isTrue);
    });

    test('isValid returns false for bearerToken auth with null token', () {
      const form = McpServerFormToCreate(
        name: 'Test',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.bearerToken,
        bearerToken: null,
      );
      expect(form.isValid, isFalse);
    });

    test('isValid returns false for bearerToken auth with empty token', () {
      const form = McpServerFormToCreate(
        name: 'Test',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.bearerToken,
        bearerToken: '',
      );
      expect(form.isValid, isFalse);
    });

    test('isValid returns true for bearerToken auth with valid token', () {
      const form = McpServerFormToCreate(
        name: 'Test',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.bearerToken,
        bearerToken: 'my-secret-token',
      );
      expect(form.isValid, isTrue);
    });

    test('validationErrors returns empty for valid form', () {
      const form = McpServerFormToCreate(
        name: 'Test',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.none,
        bearerToken: null,
      );
      expect(form.validationErrors, isEmpty);
    });

    test('validationErrors reports empty name', () {
      const form = McpServerFormToCreate(
        name: '',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.none,
        bearerToken: null,
      );
      expect(form.validationErrors, contains(contains('Name')));
    });

    test('validationErrors reports empty url', () {
      const form = McpServerFormToCreate(
        name: 'Test',
        url: '',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.none,
        bearerToken: null,
      );
      expect(form.validationErrors, contains(contains('URL')));
    });

    test('validationErrors reports missing bearer token', () {
      const form = McpServerFormToCreate(
        name: 'Test',
        url: 'http://localhost',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.bearerToken,
        bearerToken: null,
      );
      expect(form.validationErrors, contains(contains('Bearer token')));
    });

    test('validationErrors reports multiple errors', () {
      const form = McpServerFormToCreate(
        name: '',
        url: '',
        transport: McpTransportTypeSSE(),
        authenticationType: McpAuthenticationTypeOptions.bearerToken,
        bearerToken: null,
      );
      expect(form.validationErrors.length, greaterThanOrEqualTo(2));
    });
  });

  group('OAuthTokenEntity', () {
    test('isOAuthTokenExpired returns true when expiresIn is null', () {
      final token = OAuthTokenEntity(
        accessToken: 'abc',
        issuedAt: DateTime(2026),
      );
      expect(token.isOAuthTokenExpired, isTrue);
    });

    test('isOAuthTokenExpired returns false for fresh token', () {
      final token = OAuthTokenEntity(
        accessToken: 'abc',
        issuedAt: DateTime.now(),
        expiresIn: 3600,
      );
      expect(token.isOAuthTokenExpired, isFalse);
    });

    test('isOAuthTokenExpired returns true for expired token', () {
      final token = OAuthTokenEntity(
        accessToken: 'abc',
        issuedAt: DateTime(2020),
        expiresIn: 60,
      );
      expect(token.isOAuthTokenExpired, isTrue);
    });

    test('needsOAuthTokenRefresh is false when no refreshToken', () {
      final token = OAuthTokenEntity(
        accessToken: 'abc',
        issuedAt: DateTime(2020),
        expiresIn: 60,
      );
      expect(token.needsOAuthTokenRefresh, isFalse);
    });

    test('needsOAuthTokenRefresh is true when expired with refreshToken', () {
      final token = OAuthTokenEntity(
        accessToken: 'abc',
        issuedAt: DateTime(2020),
        refreshToken: 'refresh-abc',
        expiresIn: 60,
      );
      expect(token.needsOAuthTokenRefresh, isTrue);
    });

    test(
      'needsOAuthTokenRefresh is false for fresh token with refreshToken',
      () {
        final token = OAuthTokenEntity(
          accessToken: 'abc',
          issuedAt: DateTime.now(),
          refreshToken: 'refresh-abc',
          expiresIn: 3600,
        );
        expect(token.needsOAuthTokenRefresh, isFalse);
      },
    );

    test('copyCryptor encrypts fields', () async {
      final token = OAuthTokenEntity(
        accessToken: 'plain-access',
        issuedAt: DateTime(2026),
        refreshToken: 'plain-refresh',
        expiresIn: 3600,
      );

      final encrypted = await token.copyCryptor((v) async => 'enc($v)');

      expect(encrypted.accessToken, 'enc(plain-access)');
      expect(encrypted.refreshToken, 'enc(plain-refresh)');
      expect(encrypted.expiresIn, 3600);
    });

    test('copyCryptor handles null refreshToken', () async {
      final token = OAuthTokenEntity(
        accessToken: 'plain',
        issuedAt: DateTime(2026),
      );

      final encrypted = await token.copyCryptor((v) async => 'enc($v)');
      expect(encrypted.refreshToken, isNull);
    });

    test('copyCryptor preserves issuedAt', () async {
      final issued = DateTime(2026, 1, 15);
      final token = OAuthTokenEntity(
        accessToken: 'abc',
        issuedAt: issued,
      );

      final encrypted = await token.copyCryptor((v) async => 'enc($v)');
      expect(encrypted.issuedAt, issued);
    });
  });

  group('McpAuthenticationType', () {
    test('copyCryptor returns same for none type', () async {
      const auth = McpAuthenticationType.none();
      final result = await auth.copyCryptor((v) async => 'enc($v)');
      expect(result, isA<McpAuthenticationTypeNone>());
    });

    test('copyCryptor encrypts bearer token', () async {
      const auth = McpAuthenticationType.bearerToken(bearerToken: 'secret');
      final result = await auth.copyCryptor((v) async => 'enc($v)');
      expect(result, isA<McpAuthenticationTypeBearerToken>());
      expect(
        (result as McpAuthenticationTypeBearerToken).bearerToken,
        'enc(secret)',
      );
    });

    test('copyCryptor encrypts oauth token', () async {
      final auth = McpAuthenticationType.oauth(
        token: OAuthTokenEntity(
          accessToken: 'access',
          issuedAt: DateTime(2026),
          refreshToken: 'refresh',
        ),
        clientId: 'client-1',
        authorizationEndpoint: 'https://auth.example.com',
        tokenEndpoint: 'https://token.example.com',
      );
      final result = await auth.copyCryptor((v) async => 'enc($v)');

      expect(result, isA<McpAuthenticationTypeOAuth>());
      final oauthResult = result as McpAuthenticationTypeOAuth;
      expect(oauthResult.token.accessToken, 'enc(access)');
      expect(oauthResult.token.refreshToken, 'enc(refresh)');
      expect(oauthResult.clientId, 'client-1');
    });
  });

  group('McpToolInfo', () {
    test('finalToolName generates correct prefix', () {
      const tool = McpToolInfo(
        toolName: 'read_file',
        description: 'Read',
        inputSchema: {},
      );
      final server = McpServerEntity(
        id: 'srv-1',
        workspaceId: 'ws-1',
        name: 'My Server',
        url: 'http://localhost',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationType.none(),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      expect(
        tool.finalToolName(server),
        'mcp_srv-1_my_server_read_file',
      );
    });

    test('finalToolName sanitizes special characters', () {
      const tool = McpToolInfo(
        toolName: 'read:file/path',
        description: 'Read',
        inputSchema: {},
      );
      final server = McpServerEntity(
        id: 'srv-1',
        workspaceId: 'ws-1',
        name: 'Test',
        url: 'http://localhost',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationType.none(),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final name = tool.finalToolName(server);
      expect(name, contains('read_file_path'));
      expect(name, startsWith('mcp_srv-1_test_'));
    });
  });

  group('McpAuthenticationTypeOptions', () {
    test('has all expected values', () {
      expect(McpAuthenticationTypeOptions.values, hasLength(3));
      expect(
        McpAuthenticationTypeOptions.values,
        containsAll([
          McpAuthenticationTypeOptions.none,
          McpAuthenticationTypeOptions.oauth,
          McpAuthenticationTypeOptions.bearerToken,
        ]),
      );
    });
  });

  group('McpTransportTypeOptions', () {
    test('has all expected values', () {
      expect(McpTransportTypeOptions.values, hasLength(2));
      expect(
        McpTransportTypeOptions.values,
        containsAll([
          McpTransportTypeOptions.streamableHttp,
          McpTransportTypeOptions.sse,
        ]),
      );
    });
  });
}
