// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/mcp_service/o_auth_discovery_result.dart';
import 'package:auravibes_app/services/mcp_service/oauth_authentication_canceled_exception.dart';
import 'package:logging/logging.dart';

final _mcpOAuthLogger = Logger('McpOAuth');

class const BuildMcpServerToCreateUseCase({
  required final OAuthAuthenticate _authenticator,
  final void Function(McpOAuthDeviceCode deviceCode) onDeviceCode =
      _ignoreOAuthDeviceCode,
  final bool Function() isOAuthCancelled = _neverCancelOAuth,
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
    final authentication = await _authenticateMcpOAuth((
      authenticator: _authenticator,
      url: url,
      configuredClientId: configuredClientId,
      onDeviceCode: onDeviceCode,
      isCancelled: isOAuthCancelled,
    ));

    return serverInfo.copyWith(
      authenticationType: _oauthAuthentication(
        authentication.result,
        authentication.token.toEntity(),
        clientId: authentication.clientId,
      ),
    );
  }
}

typedef _McpOAuthResolutionInput = ({
  OAuthAuthenticate authenticator,
  String url,
  String? configuredClientId,
  void Function(McpOAuthDeviceCode deviceCode) onDeviceCode,
  bool Function() isCancelled,
});

typedef _McpOAuthAuthentication = ({
  OAuthDiscoveryResult result,
  String clientId,
  OAuthTokenModel token,
});

typedef _McpOAuthAuthenticationInput = ({
  OAuthAuthenticate authenticator,
  OAuthDiscoveryResult authentication,
  String clientId,
  void Function(McpOAuthDeviceCode deviceCode) onDeviceCode,
  bool Function() isCancelled,
});

void _ignoreOAuthDeviceCode(McpOAuthDeviceCode _) {
  return;
}

bool _neverCancelOAuth() => false;

Future<OAuthTokenModel> _authenticateOAuth(_McpOAuthAuthenticationInput input) {
  final authentication = input.authentication;

  return authentication.deviceAuthorizationUrl == null
      ? input.authenticator.authenticate(authentication)
      : input.authenticator.authenticateWithDeviceCode(
          input.authentication,
          clientId: input.clientId,
          onDeviceCode: input.onDeviceCode,
          isCancelled: input.isCancelled,
        );
}

Future<_McpOAuthAuthentication> _authenticateMcpOAuth(
  _McpOAuthResolutionInput input,
) async {
  final discover = await _discoverMcpOAuth(input);

  final clientId = _resolveClientId(discover, input.configuredClientId);
  final authentication = discover.withClientId(clientId);

  return await _completeMcpOAuth(input, authentication, clientId);
}

Future<_McpOAuthAuthentication> _completeMcpOAuth(
  _McpOAuthResolutionInput input,
  OAuthDiscoveryResult authentication,
  String clientId,
) async {
  final token = await _authenticateOAuth((
    authenticator: input.authenticator,
    authentication: authentication,
    clientId: clientId,
    onDeviceCode: input.onDeviceCode,
    isCancelled: input.isCancelled,
  ));

  return (result: authentication, clientId: clientId, token: token);
}

Future<OAuthDiscoveryResult> _discoverMcpOAuth(
  _McpOAuthResolutionInput input,
) async {
  final discover = await input.authenticator.discover(input.url);
  if (discover == null) return _throwOAuthDiscoveryError(input.url);

  _logOAuthDiscovery((
    url: input.url,
    discover: discover,
    hasDiscoveredClientId: _hasClientId(discover.clientId),
    hasConfiguredClientId: _hasClientId(input.configuredClientId),
  ));

  return discover;
}

Never _throwOAuthDiscoveryError(String url) {
  _mcpOAuthLogger.warning(
    'MCP OAuth discovery returned no usable configuration '
    'server=${_safeOAuthLogUrl(url)}',
  );
  throw const McpOAuthException(LocaleKeys.mcp_modal_oauth_discovery);
}

typedef _McpOAuthLogInput = ({
  String url,
  OAuthDiscoveryResult discover,
  bool hasDiscoveredClientId,
  bool hasConfiguredClientId,
});

void _logOAuthDiscovery(_McpOAuthLogInput input) {
  final discover = input.discover;
  final server = _safeOAuthLogUrl(input.url);
  _mcpOAuthLogger.info(
    'MCP OAuth discovery completed '
    'server=$server '
    'issuer=${_safeOAuthLogUrl(discover.issuer)} '
    'resource=${_safeOAuthLogUrl(discover.resource)} '
    'discoveryClientId=${input.hasDiscoveredClientId} '
    'manualClientId=${input.hasConfiguredClientId} '
    '${_oauthEndpointLogDetails(discover)}',
  );
  if (!input.hasDiscoveredClientId && !input.hasConfiguredClientId) {
    _logMissingOAuthClientId(server, discover);
  }
}

String _oauthEndpointLogDetails(OAuthDiscoveryResult discover) {
  final hasScope = discover.scope?.trim().isNotEmpty == true;

  return 'authorizationEndpoint=${_safeOAuthLogUrl(discover.authorizationUrl)} '
      'tokenEndpoint=${_safeOAuthLogUrl(discover.tokenUrl)} '
      'deviceFlow=${discover.deviceAuthorizationUrl != null} '
      'hasScope=$hasScope '
      'dynamicRegistration=${discover.supportsDynamicClientRegistration}';
}

void _logMissingOAuthClientId(String server, OAuthDiscoveryResult discover) =>
    _mcpOAuthLogger.warning(
      'MCP OAuth cannot start: no client ID was discovered or configured '
      'server=$server '
      'dynamicRegistration=${discover.supportsDynamicClientRegistration}',
    );

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
