// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/mcp_service/o_auth_discovery_result.dart';
import 'package:auravibes_app/services/mcp_service/oauth_authentication_canceled_exception.dart';
import 'package:logging/logging.dart';

final _mcpOAuthLogger = Logger('McpOAuth');

class const BuildMcpServerToCreateUseCase({
  required final OAuthAuthenticate _authenticator,
  final void Function(McpOAuthDeviceCode deviceCode)? onDeviceCode,
  final bool Function()? isOAuthCancelled,
}) {
  Future<McpServerToCreate> call(McpServerFormToCreate serverToCreate) async {
    final serverInfo = _serverInfo(serverToCreate);

    return switch (serverToCreate.authenticationType) {
      .bearerToken => _withBearerToken(serverInfo, serverToCreate.bearerToken),
      .oauth => await _withOAuth(
        serverInfo,
        serverToCreate.url,
        serverToCreate.oauthClientId,
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
    String? configuredClientId,
  ) async {
    final discover = await _authenticator.discover(url);
    if (discover == null) {
      _mcpOAuthLogger.warning(
        'MCP OAuth discovery returned no usable configuration '
        'server=${_safeOAuthLogUrl(url)}',
      );
      throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_discovery);
    }

    final hasDiscoveredClientId = _hasClientId(discover.clientId);
    final hasConfiguredClientId = _hasClientId(configuredClientId);
    _mcpOAuthLogger.info(
      'MCP OAuth discovery completed '
      'server=${_safeOAuthLogUrl(url)} '
      'issuer=${_safeOAuthLogUrl(discover.issuer)} '
      'resource=${_safeOAuthLogUrl(discover.resource)} '
      'authorizationEndpoint=${_safeOAuthLogUrl(discover.authorizationUrl)} '
      'tokenEndpoint=${_safeOAuthLogUrl(discover.tokenUrl)} '
      'deviceFlow=${discover.deviceAuthorizationUrl != null} '
      'hasScope=${discover.scope?.trim().isNotEmpty == true} '
      'dynamicRegistration=${discover.supportsDynamicClientRegistration} '
      'discoveryClientId=$hasDiscoveredClientId '
      'manualClientId=$hasConfiguredClientId',
    );
    if (!hasDiscoveredClientId && !hasConfiguredClientId) {
      _mcpOAuthLogger.warning(
        'MCP OAuth cannot start: no client ID was discovered or configured '
        'server=${_safeOAuthLogUrl(url)} '
        'dynamicRegistration=${discover.supportsDynamicClientRegistration}',
      );
    }

    final clientId = _resolveClientId(discover, configuredClientId);
    final authentication = discover.withClientId(clientId);
    final token = authentication.deviceAuthorizationUrl == null
        ? await _authenticator.authenticate(authentication)
        : await _authenticator.authenticateWithDeviceCode(
            authentication,
            clientId: clientId,
            onDeviceCode: onDeviceCode,
            isCancelled: isOAuthCancelled,
          );

    return serverInfo.copyWith(
      authenticationType: _oauthAuthentication(
        authentication,
        token.toEntity(),
        clientId: clientId,
      ),
    );
  }
}

bool _hasClientId(String? value) => value?.trim().isNotEmpty == true;

String _safeOAuthLogUrl(String? value) {
  final uri = Uri.tryParse(value ?? '');
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    return '<none>';
  }

  return '${uri.origin}${uri.path.isEmpty ? '/' : uri.path}';
}

McpAuthenticationType _oauthAuthentication(
  OAuthDiscoveryResult discover,
  OAuthTokenEntity token, {
  required String clientId,
}) => McpAuthenticationTypeOAuth(
  token: token.copyWith(scopes: token.scopes ?? discover.scopes),
  clientId: clientId,
  authorizationEndpoint: discover.authorizationUrl,
  tokenEndpoint: discover.tokenUrl,
  issuer: discover.issuer,
  resource: discover.resource,
);

String _resolveClientId(
  OAuthDiscoveryResult discover,
  String? configuredClientId,
) {
  for (final value in [discover.clientId, configuredClientId]) {
    final clientId = value?.trim();
    if (clientId != null && clientId.isNotEmpty) {
      return clientId;
    }
  }

  throw McpOAuthException(
    discover.supportsDynamicClientRegistration
        ? LocaleKeys.mcp_modal_oauth_registration_failed
        : LocaleKeys.mcp_modal_oauth_client_id_required,
  );
}
