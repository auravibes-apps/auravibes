import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_mcp_server_to_create_usecase.dart';
import 'package:auravibes_app/services/mcp_service/oauth_authenticate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final authenticator = OauthAuthenticate(
    callbackUrlScheme: 'test',
    clientName: 'test',
  );

  test('returns no-auth server for none auth type', () async {
    final usecase = BuildMcpServerToCreateUseCase(authenticator: authenticator);
    const form = McpServerFormToCreate(
      name: 'Server',
      url: 'https://example.com',
      transport: McpTransportTypeSSE(),
      authenticationType: McpAuthenticationTypeOptions.none,
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
      authenticationType: McpAuthenticationTypeOptions.bearerToken,
      bearerToken: 'secret',
    );

    final result = await usecase.call(form);

    expect(result.authenticationType, isA<McpAuthenticationTypeBearerToken>());
  });

  test('throws when bearer type selected but token is null', () async {
    final usecase = BuildMcpServerToCreateUseCase(authenticator: authenticator);
    const form = McpServerFormToCreate(
      name: 'Server',
      url: 'https://example.com',
      transport: McpTransportTypeSSE(),
      authenticationType: McpAuthenticationTypeOptions.bearerToken,
      bearerToken: null,
    );

    expect(
      () => usecase.call(form),
      throwsA(isA<Exception>()),
    );
  });

  test('throws when oauth discovery fails', () async {
    final usecase = BuildMcpServerToCreateUseCase(authenticator: authenticator);
    const form = McpServerFormToCreate(
      name: 'Server',
      url: 'https://invalid-oauth.example.com',
      transport: McpTransportTypeSSE(),
      authenticationType: McpAuthenticationTypeOptions.oauth,
      bearerToken: null,
    );

    expect(
      () => usecase.call(form),
      throwsA(isA<Exception>()),
    );
  });
}
