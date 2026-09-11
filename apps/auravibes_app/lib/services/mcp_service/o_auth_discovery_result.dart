// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

const _jsonAcceptHeader = {'Accept': 'application/json'};
final _oauthDiscoveryLogger = Logger('OAuthDiscoveryService');

/// Result of OAuth discovery for an MCP server.
class const OAuthDiscoveryResult({
  /// OAuth authorization endpoint URL.
  required final String authorizationUrl,

  /// OAuth token endpoint URL.
  required final String tokenUrl,

  /// OAuth client ID (may be null for public clients).
  required final String? clientId,

  /// OAuth scope string.
  required final String? scope,
});

class const OAuthConnector({
  required final String clientName,
  required final String serverUrl,
  required final String redirectUrl,
});

/// Service for automatically discovering OAuth configuration from MCP servers
///
/// Implements RFC 8414 (OAuth 2.0 Authorization Server Metadata) and RFC 7591
/// (OAuth 2.0 Dynamic Client Registration) for automatic OAuth discovery.
class OAuthDiscoveryService {
  /// Automatically discovers OAuth configuration for an MCP server URL.
  static Future<OAuthDiscoveryResult?> discoverOAuth(
    OAuthConnector registrer,
  ) async {
    try {
      _oauthDiscoveryLogger.info(
        'Discovering OAuth configuration for MCP server',
      );

      return await _discoverFromEndpoints(registrer);
    } on Exception catch (error, stackTrace) {
      _oauthDiscoveryLogger.warning(
        'OAuth discovery failed',
        error,
        stackTrace,
      );

      return null;
    }
  }

  /// Try RFC 8414 OAuth 2.0 Authorization Server Metadata.
  static Future<OAuthDiscoveryResult?> _tryWellKnownEndpoint(
    OAuthConnector connector,
  ) async {
    try {
      _oauthDiscoveryLogger.info('Trying well-known OAuth endpoint');

      return await _wellKnownDiscovery(connector);
    } on Exception catch (error, stackTrace) {
      _oauthDiscoveryLogger.fine(
        'Well-known endpoint not available',
        error,
        stackTrace,
      );
    }

    return null;
  }

  static Future<OAuthDiscoveryResult?> _wellKnownDiscovery(
    OAuthConnector connector,
  ) async {
    final response = await _requestWellKnown(
      _wellKnownUrl(_baseUrl(connector.serverUrl)),
    );

    return await _wellKnownResponse(
      response,
      redirectUrl: connector.redirectUrl,
      clientName: connector.clientName,
    );
  }

  /// Try probing the MCP server directly for OAuth requirements.
  static Future<OAuthDiscoveryResult?> _tryDirectServerProbe(
    String serverUrl,
  ) async {
    try {
      _oauthDiscoveryLogger.info('Probing MCP server directly');
      final uri = _probeUri(serverUrl);
      if (uri == null) return null;

      return _parseDirectProbeResponse(await _requestDirectProbe(uri));
    } on Exception catch (error, stackTrace) {
      _oauthDiscoveryLogger.fine(
        'Direct server probe failed',
        error,
        stackTrace,
      );
    }

    return null;
  }

  static OAuthDiscoveryResult? _parseDirectProbeResponse(
    http.Response response,
  ) {
    if (response.statusCode != 401) return null;

    final headerResult = _parseOAuthHeaderChallenge(response);
    if (headerResult != null) return headerResult;

    _oauthDiscoveryLogger.info('Server returned 401, may require OAuth');

    return _parseOAuthBodyChallenge(response.body);
  }

  static OAuthDiscoveryResult? _parseOAuthHeaderChallenge(
    http.Response response,
  ) {
    if (!_hasBearerChallenge(response)) return null;

    _oauthDiscoveryLogger.info('Server requires OAuth authentication');

    return _headerChallengeResult(response);
  }

  static OAuthDiscoveryResult? _parseOAuthBodyChallenge(String body) {
    if (!_containsOAuthChallenge(body)) return null;

    return _decodeOAuthBody(body);
  }

  /// Try OAuth metadata endpoint.
  static Future<OAuthDiscoveryResult?> _tryOAuthMetadataEndpoint(
    String baseUrl,
  ) async {
    try {
      final metadataUrl = '$baseUrl/oauth/metadata';
      _oauthDiscoveryLogger.info('Trying OAuth metadata endpoint');

      final response = await _requestOAuthMetadata(metadataUrl);

      return _metadataResponse(response);
    } on Exception catch (error, stackTrace) {
      _oauthDiscoveryLogger.fine(
        'OAuth metadata endpoint not available',
        error,
        stackTrace,
      );
    }

    return null;
  }
}

String _wellKnownUrl(String baseUrl) =>
    '$baseUrl/.well-known/oauth-authorization-server';

Future<OAuthDiscoveryResult?> _wellKnownResponse(
  http.Response response, {
  required String redirectUrl,
  required String clientName,
}) {
  if (response.statusCode != HttpStatus.ok) return Future.value();

  return _parseWellKnownMetadata(
    json.decode(response.body) as Map<String, dynamic>,
    redirectUrl: redirectUrl,
    clientName: clientName,
  );
}

Future<OAuthDiscoveryResult?> _parseWellKnownMetadata(
  Map<String, dynamic> metadata, {
  required String redirectUrl,
  required String clientName,
}) async {
  final endpoints = _wellKnownEndpoints(metadata);
  if (endpoints == null) return null;

  return await _completeWellKnownMetadata((
    endpoints: endpoints,
    metadata: metadata,
    redirectUrl: redirectUrl,
    clientName: clientName,
  ));
}

Future<OAuthDiscoveryResult?> _discoverFromEndpoints(
  OAuthConnector registrer,
) async {
  final discovered = await OAuthDiscoveryService._tryWellKnownEndpoint(
    registrer,
  );
  if (discovered != null) return discovered;
  final direct = await OAuthDiscoveryService._tryDirectServerProbe(
    registrer.serverUrl,
  );
  if (direct != null) return direct;

  return await OAuthDiscoveryService._tryOAuthMetadataEndpoint(
    _baseUrl(registrer.serverUrl),
  );
}

OAuthDiscoveryResult? _parseMetadataResponse(String body) {
  return _parseMetadataMap(json.decode(body) as Map<String, dynamic>);
}

OAuthDiscoveryResult? _parseMetadataMap(Map<String, dynamic> metadata) {
  final authUrl = metadata['authorization_url'] as String?;
  final tokenUrl = metadata['token_url'] as String?;
  if (authUrl == null || tokenUrl == null) return null;

  return OAuthDiscoveryResult(
    authorizationUrl: authUrl,
    tokenUrl: tokenUrl,
    clientId: metadata['client_id'] as String?,
    scope: metadata['scope'] as String?,
  );
}

String _baseUrl(String serverUrl) {
  final uri = Uri.parse(serverUrl);

  return '${uri.scheme}://${uri.host}:${uri.port}';
}

typedef _WellKnownEndpoints = ({String authorizationUrl, String tokenUrl});

typedef _WellKnownClientRequest = ({
  Map<String, dynamic> metadata,
  String? registrationEndpoint,
  String redirectUrl,
  String clientName,
});

typedef _WellKnownMetadataInput = ({
  _WellKnownEndpoints endpoints,
  Map<String, dynamic> metadata,
  String redirectUrl,
  String clientName,
});

typedef _DynamicClientRegistrationRequest = ({
  String registrationEndpoint,
  String redirectUrl,
  String clientName,
});

_WellKnownEndpoints? _wellKnownEndpoints(Map<String, dynamic> metadata) {
  final authorizationUrl = metadata['authorization_endpoint'] as String?;
  final tokenUrl = metadata['token_endpoint'] as String?;
  if (authorizationUrl == null || tokenUrl == null) return null;

  return (authorizationUrl: authorizationUrl, tokenUrl: tokenUrl);
}

Future<OAuthDiscoveryResult> _completeWellKnownMetadata(
  _WellKnownMetadataInput input,
) async {
  final clientId = await _wellKnownClientId(_wellKnownClientRequest(input));

  return OAuthDiscoveryResult(
    authorizationUrl: input.endpoints.authorizationUrl,
    tokenUrl: input.endpoints.tokenUrl,
    clientId: clientId,
    scope: input.metadata['scope'] as String?,
  );
}

_WellKnownClientRequest _wellKnownClientRequest(
  _WellKnownMetadataInput input,
) => (
  metadata: input.metadata,
  registrationEndpoint: input.metadata['registration_endpoint'] as String?,
  redirectUrl: input.redirectUrl,
  clientName: input.clientName,
);

Future<http.Response> _requestWellKnown(String url) => http
    .get(.parse(url), headers: _jsonAcceptHeader)
    .timeout(const Duration(seconds: 5));

Future<String?> _wellKnownClientId(_WellKnownClientRequest request) async {
  final clientId = request.metadata['client_id'] as String?;
  final registrationEndpoint = request.registrationEndpoint;
  if (clientId != null || registrationEndpoint == null) {
    return clientId;
  }

  return await _tryDynamicClientRegistration(
    registrationEndpoint: registrationEndpoint,
    redirectUrl: request.redirectUrl,
    clientName: request.clientName,
  );
}

Future<String?> _tryDynamicClientRegistration({
  required String registrationEndpoint,
  required String redirectUrl,
  required String clientName,
}) => _performDynamicClientRegistrationSafely((
  registrationEndpoint: registrationEndpoint,
  redirectUrl: redirectUrl,
  clientName: clientName,
));

Future<String?> _performDynamicClientRegistrationSafely(
  _DynamicClientRegistrationRequest request,
) async {
  try {
    _oauthDiscoveryLogger.info('Attempting dynamic OAuth client registration');

    return await _performDynamicClientRegistration(
      registrationEndpoint: request.registrationEndpoint,
      redirectUrl: request.redirectUrl,
      clientName: request.clientName,
    );
  } on Exception catch (error, stackTrace) {
    return _dynamicClientRegistrationError(error, stackTrace);
  }
}

String? _dynamicClientRegistrationError(
  Exception error,
  StackTrace stackTrace,
) {
  _oauthDiscoveryLogger.warning(
    'Dynamic client registration error',
    error,
    stackTrace,
  );

  return null;
}

Future<String?> _performDynamicClientRegistration({
  required String registrationEndpoint,
  required String redirectUrl,
  required String clientName,
}) async => _registeredClientId(
  await _postDynamicClientRegistration(
    registrationEndpoint: registrationEndpoint,
    redirectUrl: redirectUrl,
    clientName: clientName,
  ),
);

Future<http.Response> _requestDirectProbe(Uri uri) => http
    .get(uri, headers: {'Accept': 'text/event-stream'})
    .timeout(const Duration(seconds: 5));

Uri? _probeUri(String serverUrl) {
  final uri = Uri.tryParse(serverUrl);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;

  return uri;
}

OAuthDiscoveryResult? _headerChallengeResult(http.Response response) {
  final authEndpoint = response.headers['x-oauth-authorization-url'];
  final tokenEndpoint = response.headers['x-oauth-token-url'];
  if (authEndpoint == null || tokenEndpoint == null) return null;

  return OAuthDiscoveryResult(
    authorizationUrl: authEndpoint,
    tokenUrl: tokenEndpoint,
    clientId: response.headers['x-oauth-client-id'],
    scope: response.headers['x-oauth-scope'],
  );
}

bool _hasBearerChallenge(http.Response response) {
  final authHeader = response.headers['www-authenticate'];

  return authHeader != null && authHeader.toLowerCase().contains('bearer');
}

bool _containsOAuthChallenge(String body) {
  final normalizedBody = body.toLowerCase();

  return normalizedBody.contains('oauth') ||
      normalizedBody.contains('authorization');
}

OAuthDiscoveryResult? _decodeOAuthBody(String body) {
  try {
    final bodyJson = json.decode(body) as Map<String, dynamic>?;

    return _oauthBodyResult(bodyJson);
  } on Exception catch (error, stackTrace) {
    _oauthDiscoveryLogger.fine(
      'Could not parse OAuth info from response body',
      error,
      stackTrace,
    );
  }

  return null;
}

OAuthDiscoveryResult? _oauthBodyResult(Map<String, dynamic>? bodyJson) {
  if (bodyJson == null) return null;
  final authUrl = bodyJson['authorization_url'] as String?;
  final tokenUrl = bodyJson['token_url'] as String?;
  if (authUrl == null || tokenUrl == null) return null;

  return _oauthDiscoveryResult(bodyJson, authUrl, tokenUrl);
}

OAuthDiscoveryResult _oauthDiscoveryResult(
  Map<String, dynamic> json,
  String authorizationUrl,
  String tokenUrl,
) => OAuthDiscoveryResult(
  authorizationUrl: authorizationUrl,
  tokenUrl: tokenUrl,
  clientId: json['client_id'] as String?,
  scope: json['scope'] as String?,
);

Future<http.Response> _requestOAuthMetadata(String url) => http
    .get(.parse(url), headers: _jsonAcceptHeader)
    .timeout(const Duration(seconds: 5));

OAuthDiscoveryResult? _metadataResponse(http.Response response) {
  if (response.statusCode != HttpStatus.ok) return null;

  return _parseMetadataResponse(response.body);
}

Future<http.Response> _postDynamicClientRegistration({
  required String registrationEndpoint,
  required String redirectUrl,
  required String clientName,
}) {
  final clientMetadata = _dynamicClientMetadata(clientName, redirectUrl);

  return http
      .post(
        .parse(registrationEndpoint),
        headers: {'Content-Type': 'application/json', ..._jsonAcceptHeader},
        body: json.encode(clientMetadata),
      )
      .timeout(const Duration(seconds: 10));
}

Map<String, Object> _dynamicClientMetadata(
  String clientName,
  String redirectUrl,
) => {
  'client_name': clientName,
  'redirect_uris': [redirectUrl],
  'grant_types': ['authorization_code', 'refresh_token'],
  'response_types': ['code'],
  'token_endpoint_auth_method': 'none',
  'application_type': 'web',
};

String? _registeredClientId(http.Response response) {
  if (!_isRegistrationSuccess(response.statusCode)) {
    return _logRegistrationFailure(response.statusCode);
  }

  final clientId = _registrationClientId(response.body);
  if (clientId == null) return null;

  _oauthDiscoveryLogger.info(
    'Dynamic client registration successful, client_id: $clientId',
  );

  return clientId;
}

bool _isRegistrationSuccess(int statusCode) =>
    statusCode == HttpStatus.ok || statusCode == HttpStatus.created;

String? _logRegistrationFailure(int statusCode) {
  _oauthDiscoveryLogger.warning(
    'Dynamic client registration failed with status $statusCode',
  );

  return null;
}

String? _registrationClientId(String body) {
  final registrationResponse = json.decode(body) as Map<String, dynamic>;

  return registrationResponse['client_id'] as String?;
}
