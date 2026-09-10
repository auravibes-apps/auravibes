// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/services/mcp_service/o_auth_discovery_result.dart';
import 'package:auravibes_app/services/mcp_service/oauth_authentication_canceled_exception.dart';

class const BuildMcpServerToCreateUseCase({
  required final OAuthAuthenticate _authenticator,
}) {
  Future<McpServerToCreate> call(McpServerFormToCreate serverToCreate) async {
    final serverInfo = _serverInfo(serverToCreate);

    return switch (serverToCreate.authenticationType) {
      McpAuthenticationTypeOptions.bearerToken => _withBearerToken(
        serverInfo,
        serverToCreate.bearerToken,
      ),
      McpAuthenticationTypeOptions.oauth => await _withOAuth(
        serverInfo,
        serverToCreate.url,
      ),
      _ => serverInfo,
    };
  }

  McpServerToCreate _serverInfo(McpServerFormToCreate serverToCreate) =>
      McpServerToCreate(
        name: serverToCreate.name,
        url: serverToCreate.url,
        transport: serverToCreate.transport,
        authenticationType: const McpAuthenticationTypeNone(),
        description: serverToCreate.description,
      );

  McpServerToCreate _withBearerToken(
    McpServerToCreate serverInfo,
    String? bearerToken,
  ) {
    if (bearerToken == null) throw Exception('Bearer token is required');

    return serverInfo.copyWith(
      authenticationType: McpAuthenticationTypeBearerToken(
        bearerToken: bearerToken,
      ),
    );
  }

  Future<McpServerToCreate> _withOAuth(
    McpServerToCreate serverInfo,
    String url,
  ) async {
    final discover = await _authenticator.discover(url);
    if (discover == null) {
      throw Exception('Failed to discover OAuth endpoints');
    }

    final token = await _authenticator.authenticate(discover);

    return serverInfo.copyWith(
      authenticationType: _oauthAuthentication(discover, token.toEntity()),
    );
  }
}

McpAuthenticationType _oauthAuthentication(
  OAuthDiscoveryResult discover,
  OAuthTokenEntity token,
) => McpAuthenticationTypeOAuth(
  token: token,
  clientId: discover.clientId ?? 'app-client-id',
  authorizationEndpoint: discover.authorizationUrl,
  tokenEndpoint: discover.tokenUrl,
);
