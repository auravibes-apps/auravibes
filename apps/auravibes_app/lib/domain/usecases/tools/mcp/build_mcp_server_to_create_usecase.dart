import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/services/mcp_service/oauth_authenticate.dart';

class BuildMcpServerToCreateUseCase {
  const BuildMcpServerToCreateUseCase({
    required OauthAuthenticate authenticator,
  }) : _authenticator = authenticator;

  final OauthAuthenticate _authenticator;

  Future<McpServerToCreate> call(McpServerFormToCreate serverToCreate) async {
    final serverInfo = McpServerToCreate(
      name: serverToCreate.name,
      url: serverToCreate.url,
      transport: serverToCreate.transport,
      authenticationType: const McpAuthenticationTypeNone(),
      description: serverToCreate.description,
    );

    if (serverToCreate.authenticationType ==
        McpAuthenticationTypeOptions.bearerToken) {
      final bearerToken = serverToCreate.bearerToken;
      if (bearerToken == null) {
        throw Exception('Bearer token is required');
      }
      return serverInfo.copyWith(
        authenticationType: McpAuthenticationTypeBearerToken(
          bearerToken: bearerToken,
        ),
      );
    }

    if (serverToCreate.authenticationType !=
        McpAuthenticationTypeOptions.oauth) {
      return serverInfo;
    }

    final discover = await _authenticator.discover(serverToCreate.url);
    if (discover == null) {
      throw Exception('Failed to discover OAuth endpoints');
    }

    final token = await _authenticator.authenticate(discover);
    return serverInfo.copyWith(
      authenticationType: McpAuthenticationTypeOAuth(
        clientId: discover.clientId ?? 'app-client-id',
        authorizationEndpoint: discover.authorizationUrl,
        tokenEndpoint: discover.tokenUrl,
        token: token.toEntity(),
      ),
    );
  }
}
