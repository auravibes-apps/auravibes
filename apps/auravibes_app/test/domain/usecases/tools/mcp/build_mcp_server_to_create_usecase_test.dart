import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_mcp_server_to_create_use_case.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/mcp_service/o_auth_discovery_result.dart';
import 'package:auravibes_app/services/mcp_service/oauth_authentication_canceled_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

class _FakeOAuthAuthenticate(final OAuthDiscoveryResult? discovery)
    extends OAuthAuthenticate {
  this : super(callbackUrlScheme: 'test', clientName: 'test');
  OAuthDiscoveryResult? authenticatedResult;
  String? deviceClientId;

  @override
  Future<OAuthDiscoveryResult?> discover(String url) async => discovery;

  @override
  Future<OAuthTokenModel> authenticate(OAuthDiscoveryResult result) async {
    authenticatedResult = result;

    return const OAuthTokenModel(accessToken: 'access-token');
  }

  @override
  Future<OAuthTokenModel> authenticateWithDeviceCode(
    OAuthDiscoveryResult result, {
    required String clientId,
    void Function(McpOAuthDeviceCode deviceCode)? onDeviceCode,
    bool Function()? isCancelled,
  }) async {
    authenticatedResult = result;
    deviceClientId = clientId;

    return const OAuthTokenModel(accessToken: 'access-token');
  }
}

void main() {
  final authenticator = OAuthAuthenticate(
    callbackUrlScheme: 'test',
    clientName: 'test',
  );

  test('returns no-auth server for none auth type', () async {
    final usecase = BuildMcpServerToCreateUseCase(authenticator: authenticator);
    const form = McpServerFormToCreate(
      name: 'Server',
      url: 'https://example.com',
      transport: McpTransportTypeSSE(),
      authenticationType: .none,
      bearerToken: '',
    );

    final result = await usecase.call(form);

    expect(result.authenticationType, isA<McpAuthenticationTypeNone>());
  });

  test('returns bearer auth server for bearer type', () async {
    final usecase = BuildMcpServerToCreateUseCase(authenticator: authenticator);
    const form = McpServerFormToCreate(
      name: 'Server',
      url: 'https://example.com',
      transport: McpTransportTypeSSE(),
      authenticationType: .bearerToken,
      bearerToken: 'secret',
    );

    final result = await usecase.call(form);

    expect(result.authenticationType, isA<McpAuthenticationTypeBearerToken>());
  });

  test('throws when bearer type selected but token is null', () {
    final usecase = BuildMcpServerToCreateUseCase(authenticator: authenticator);
    const form = McpServerFormToCreate(
      name: 'Server',
      url: 'https://example.com',
      transport: McpTransportTypeSSE(),
      authenticationType: .bearerToken,
      bearerToken: null,
    );

    expect(() => usecase.call(form), throwsA(isA<Exception>()));
  });

  test('throws when oauth discovery fails', () {
    final usecase = BuildMcpServerToCreateUseCase(authenticator: authenticator);
    const form = McpServerFormToCreate(
      name: 'Server',
      url: 'https://invalid-oauth.example.com',
      transport: McpTransportTypeSSE(),
      authenticationType: .oauth,
      bearerToken: null,
    );

    expect(() => usecase.call(form), throwsA(isA<Exception>()));
  });

  test('prefers the discovered client ID', () async {
    final authenticator = _FakeOAuthAuthenticate(
      const OAuthDiscoveryResult(
        authorizationUrl: 'https://auth.example.com/authorize',
        tokenUrl: 'https://auth.example.com/token',
        clientId: 'discovered-client',
        scope: 'read',
        resource: 'https://mcp.example.com/',
        deviceAuthorizationUrl: 'https://auth.example.com/device',
      ),
    );
    final usecase = BuildMcpServerToCreateUseCase(authenticator: authenticator);
    const form = McpServerFormToCreate(
      name: 'Server',
      url: 'https://mcp.example.com/',
      transport: McpTransportTypeSSE(),
      authenticationType: .oauth,
      bearerToken: null,
      oauthClientId: 'manual-client',
    );

    final result = await usecase.call(form);
    final authentication =
        result.authenticationType as McpAuthenticationTypeOAuth;

    expect(authenticator.deviceClientId, 'discovered-client');
    expect(authentication.clientId, 'discovered-client');
    expect(authentication.resource, 'https://mcp.example.com/');
  });

  test('uses the trimmed form client ID when discovery has none', () async {
    final authenticator = _FakeOAuthAuthenticate(
      const OAuthDiscoveryResult(
        authorizationUrl: 'https://auth.example.com/authorize',
        tokenUrl: 'https://auth.example.com/token',
        clientId: null,
        scope: 'read',
        resource: 'https://mcp.example.com/',
        deviceAuthorizationUrl: 'https://auth.example.com/device',
      ),
    );
    final usecase = BuildMcpServerToCreateUseCase(authenticator: authenticator);
    const form = McpServerFormToCreate(
      name: 'Server',
      url: 'https://mcp.example.com/',
      transport: McpTransportTypeSSE(),
      authenticationType: .oauth,
      bearerToken: null,
      oauthClientId: '  manual-client  ',
    );

    final result = await usecase.call(form);

    expect(authenticator.deviceClientId, 'manual-client');
    expect(
      (result.authenticationType as McpAuthenticationTypeOAuth).clientId,
      'manual-client',
    );
  });

  test('uses the form client ID for browser PKCE authentication', () async {
    final authenticator = _FakeOAuthAuthenticate(
      const OAuthDiscoveryResult(
        authorizationUrl: 'https://auth.example.com/authorize',
        tokenUrl: 'https://auth.example.com/token',
        clientId: null,
        scope: 'read',
        resource: 'https://mcp.example.com/',
      ),
    );
    final usecase = BuildMcpServerToCreateUseCase(authenticator: authenticator);
    const form = McpServerFormToCreate(
      name: 'Server',
      url: 'https://mcp.example.com/',
      transport: McpTransportTypeSSE(),
      authenticationType: .oauth,
      bearerToken: null,
      oauthClientId: 'manual-client',
    );

    final result = await usecase.call(form);

    expect(authenticator.authenticatedResult?.clientId, 'manual-client');
    expect(result.authenticationType, isA<McpAuthenticationTypeOAuth>());
  });

  test('throws a typed error when no client ID is available', () async {
    final authenticator = _FakeOAuthAuthenticate(
      const OAuthDiscoveryResult(
        authorizationUrl: 'https://auth.example.com/authorize',
        tokenUrl: 'https://auth.example.com/token',
        clientId: null,
        scope: null,
        deviceAuthorizationUrl: 'https://auth.example.com/device',
      ),
    );
    final usecase = BuildMcpServerToCreateUseCase(authenticator: authenticator);
    const form = McpServerFormToCreate(
      name: 'Server',
      url: 'https://mcp.example.com/',
      transport: McpTransportTypeSSE(),
      authenticationType: .oauth,
      bearerToken: null,
    );

    await expectLater(
      usecase.call(form),
      throwsA(
        isA<McpOAuthException>().having(
          (error) => error.localizationKey,
          'localizationKey',
          LocaleKeys.mcp_modal_oauth_client_id_required,
        ),
      ),
    );
  });

  test(
    'reports dynamic registration failure when registration was advertised',
    () async {
      final authenticator = _FakeOAuthAuthenticate(
        const OAuthDiscoveryResult(
          authorizationUrl: 'https://auth.example.com/authorize',
          tokenUrl: 'https://auth.example.com/token',
          clientId: null,
          scope: null,
          supportsDynamicClientRegistration: true,
        ),
      );
      final usecase = BuildMcpServerToCreateUseCase(
        authenticator: authenticator,
      );
      const form = McpServerFormToCreate(
        name: 'Server',
        url: 'https://mcp.example.com/',
        transport: McpTransportTypeSSE(),
        authenticationType: .oauth,
        bearerToken: null,
      );

      await expectLater(
        usecase.call(form),
        throwsA(
          isA<McpOAuthException>().having(
            (error) => error.localizationKey,
            'localizationKey',
            LocaleKeys.mcp_modal_oauth_registration_failed,
          ),
        ),
      );
    },
  );

  test(
    'logs OAuth client ID diagnostics without logging URL queries',
    () async {
      final authenticator = _FakeOAuthAuthenticate(
        const OAuthDiscoveryResult(
          authorizationUrl: 'https://auth.example.com/authorize',
          tokenUrl: 'https://auth.example.com/token',
          clientId: null,
          scope: 'read',
          resource: 'https://mcp.example.com/mcp/',
          issuer: 'https://auth.example.com',
          deviceAuthorizationUrl: 'https://auth.example.com/device',
        ),
      );
      final usecase = BuildMcpServerToCreateUseCase(
        authenticator: authenticator,
      );
      const form = McpServerFormToCreate(
        name: 'Server',
        url: 'https://mcp.example.com/mcp?token=secret',
        transport: McpTransportTypeSSE(),
        authenticationType: .oauth,
        bearerToken: null,
      );
      final records = <LogRecord>[];
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(subscription.cancel);
      final previousLevel = Logger.root.level;
      Logger.root.level = .ALL;
      addTearDown(() => Logger.root.level = previousLevel);

      await expectLater(usecase.call(form), throwsA(isA<McpOAuthException>()));

      final summary = records.firstWhere(
        (record) =>
            record.loggerName == 'McpOAuth' &&
            record.message.contains('MCP OAuth discovery completed'),
      );
      expect(summary.message, contains('server=https://mcp.example.com/mcp'));
      expect(summary.message, contains('discoveryClientId=false'));
      expect(summary.message, contains('manualClientId=false'));
      expect(summary.message, contains('deviceFlow=true'));
      expect(summary.message, isNot(contains('token=secret')));

      final failure = records.firstWhere(
        (record) =>
            record.loggerName == 'McpOAuth' &&
            record.message.contains('MCP OAuth cannot start'),
      );
      expect(
        failure.message,
        contains('no client ID was discovered or configured'),
      );
    },
  );
}
