// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'package:logging/logging.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

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

  /// Canonical protected MCP resource from RFC 9728 metadata.
  final String? resource,

  /// Authorization-server issuer.
  final String? issuer,

  /// OAuth device authorization endpoint, when supported.
  final String? deviceAuthorizationUrl,

  /// Whether the authorization server advertised dynamic client registration.
  final bool supportsDynamicClientRegistration = false,

  /// Discovered scopes, preserving their precedence across metadata sources.
  final List<String> scopes = const [],

  /// Whether the authorization server supports the response `iss` parameter.
  final bool authorizationResponseIssuerSupported = false,
});

extension OAuthDiscoveryResultClientId on OAuthDiscoveryResult {
  /// Returns this discovery result with a configured public client ID.
  OAuthDiscoveryResult withClientId(String value) => OAuthDiscoveryResult(
    authorizationUrl: authorizationUrl,
    tokenUrl: tokenUrl,
    clientId: value,
    scope: scope,
    resource: resource,
    issuer: issuer,
    deviceAuthorizationUrl: deviceAuthorizationUrl,
    supportsDynamicClientRegistration: supportsDynamicClientRegistration,
    scopes: scopes,
    authorizationResponseIssuerSupported: authorizationResponseIssuerSupported,
  );
}

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
    OAuthConnector registrer, {
    http.Client? registrationClient,
    PublicUrlLookup? registrationLookup,
  }) async {
    try {
      _oauthDiscoveryLogger.info(
        'Discovering OAuth configuration for MCP server',
      );

      return await _discoverFromEndpoints(
        registrer,
        registrationOptions: (
          client: registrationClient,
          lookup: registrationLookup,
        ),
      );
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
    OAuthConnector connector, {
    required _RegistrationOptions registrationOptions,
  }) async {
    try {
      _oauthDiscoveryLogger.info('Trying well-known OAuth endpoint');

      return await _wellKnownDiscovery(
        connector,
        registrationOptions: registrationOptions,
      );
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
    OAuthConnector connector, {
    required _RegistrationOptions registrationOptions,
  }) async {
    final baseUrl = _baseUrl(connector.serverUrl);
    if (baseUrl.isEmpty) return null;
    final response = await _requestWellKnown(_wellKnownUrl(baseUrl));

    return await _wellKnownResponse(
      response,
      redirectUrl: connector.redirectUrl,
      clientName: connector.clientName,
      resourceUri: _probeUri(connector.serverUrl),
      registrationOptions: registrationOptions,
    );
  }

  /// Try probing the MCP server directly for OAuth requirements.
  static Future<OAuthDiscoveryResult?> _tryDirectServerProbe(
    OAuthConnector connector, {
    required _RegistrationOptions registrationOptions,
  }) async {
    try {
      _oauthDiscoveryLogger.info('Probing MCP server directly');
      final uri = _probeUri(connector.serverUrl);
      if (uri == null) return null;

      return await _parseDirectProbeResponse(
        await _requestDirectProbe(uri),
        connector: connector,
        resourceUri: uri,
        registrationOptions: registrationOptions,
      );
    } on Exception catch (error, stackTrace) {
      _oauthDiscoveryLogger.fine(
        'Direct server probe failed',
        error,
        stackTrace,
      );
    }

    return null;
  }

  static Future<OAuthDiscoveryResult?> _parseDirectProbeResponse(
    http.Response response, {
    required OAuthConnector connector,
    required Uri resourceUri,
    required _RegistrationOptions registrationOptions,
  }) async {
    if (response.statusCode != 401) return null;

    final challenge = mcp.WwwAuthenticateChallenge.parse(
      response.headers['www-authenticate'],
    );
    final bearerChallenge = challenge;
    if (bearerChallenge != null && bearerChallenge.isBearer) {
      final discovered = await _discoverFromProtectedResource(
        connector,
        resourceUri: resourceUri,
        challenge: bearerChallenge,
        registrationOptions: registrationOptions,
      );
      if (discovered != null) return discovered;
    }

    return _parseOAuthHeaderChallenge(response, resourceUri: resourceUri);
  }

  static OAuthDiscoveryResult? _parseOAuthHeaderChallenge(
    http.Response response, {
    Uri? resourceUri,
  }) {
    final challenge = mcp.WwwAuthenticateChallenge.parse(
      response.headers['www-authenticate'],
    );
    if (challenge?.isBearer != true) return null;

    _oauthDiscoveryLogger.info('Server requires OAuth authentication');

    return _headerChallengeResult(response, resourceUri: resourceUri);
  }

  /// Try OAuth metadata endpoint.
  static Future<OAuthDiscoveryResult?> _tryOAuthMetadataEndpoint(
    OAuthConnector connector, {
    required _RegistrationOptions registrationOptions,
  }) async {
    final baseUrl = _baseUrl(connector.serverUrl);
    if (baseUrl.isEmpty) return null;
    try {
      final metadataUrl = '$baseUrl/oauth/metadata';
      _oauthDiscoveryLogger.info('Trying OAuth metadata endpoint');

      final response = await _requestOAuthMetadata(metadataUrl);

      return await _metadataResponse(
        response,
        redirectUrl: connector.redirectUrl,
        clientName: connector.clientName,
        registrationOptions: registrationOptions,
        resourceUri: _probeUri(connector.serverUrl),
      );
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
  required Uri? resourceUri,
  required _RegistrationOptions registrationOptions,
}) {
  if (response.statusCode != HttpStatus.ok) return Future.value();

  final metadata = _decodeJsonObject(response);
  if (metadata == null) return Future.value();

  return _parseWellKnownMetadata(
    metadata,
    redirectUrl: redirectUrl,
    clientName: clientName,
    resourceUri: resourceUri,
    registrationOptions: registrationOptions,
  );
}

Future<OAuthDiscoveryResult?> _parseWellKnownMetadata(
  Map<String, dynamic> metadata, {
  required String redirectUrl,
  required String clientName,
  required Uri? resourceUri,
  required _RegistrationOptions registrationOptions,
}) async {
  final endpoints = _wellKnownEndpoints(metadata);
  if (endpoints == null) return null;

  return await _completeWellKnownMetadata((
    endpoints: endpoints,
    metadata: metadata,
    redirectUrl: redirectUrl,
    clientName: clientName,
    resourceUri: resourceUri,
    registrationOptions: registrationOptions,
  ));
}

Future<OAuthDiscoveryResult?> _discoverFromEndpoints(
  OAuthConnector registrer, {
  required _RegistrationOptions registrationOptions,
}) async {
  final direct = await OAuthDiscoveryService._tryDirectServerProbe(
    registrer,
    registrationOptions: registrationOptions,
  );
  if (direct != null) return direct;

  final discovered = await OAuthDiscoveryService._tryWellKnownEndpoint(
    registrer,
    registrationOptions: registrationOptions,
  );
  if (discovered != null) return discovered;

  return await OAuthDiscoveryService._tryOAuthMetadataEndpoint(
    registrer,
    registrationOptions: registrationOptions,
  );
}

Future<OAuthDiscoveryResult?> _parseMetadataMap(
  Map<String, dynamic> metadata, {
  required String redirectUrl,
  required String clientName,
  required _RegistrationOptions registrationOptions,
  Uri? resourceUri,
}) async {
  final authUrl = _stringValue(metadata['authorization_url']);
  final tokenUrl = _stringValue(metadata['token_url']);
  final validAuthUrl = _validHttpsUri(authUrl);
  final validTokenUrl = _validHttpsUri(tokenUrl);
  if (validAuthUrl == null || validTokenUrl == null) return null;
  final resourceValue = metadata['resource'];
  final resource = resourceValue == null ? null : _validHttpsUri(resourceValue);
  if (resourceValue != null &&
      (resource == null ||
          resourceUri != null && !_sameResource(resource, resourceUri))) {
    return null;
  }
  final issuerValue = metadata['issuer'];
  final issuer = issuerValue == null ? null : _validHttpsUri(issuerValue);
  if (issuerValue != null && issuer == null) return null;
  final scopes = _scopes(metadata['scopes_supported'], metadata['scope']);
  final clientId = await _wellKnownClientId((
    metadata: metadata,
    registrationEndpoint: _stringValue(metadata['registration_endpoint']),
    redirectUrl: redirectUrl,
    clientName: clientName,
    registrationOptions: registrationOptions,
  ));

  return OAuthDiscoveryResult(
    authorizationUrl: validAuthUrl.toString(),
    tokenUrl: validTokenUrl.toString(),
    clientId: clientId,
    scope: _stringValue(metadata['scope']) ?? scopes.join(' '),
    resource: resource?.toString() ?? resourceUri?.toString(),
    issuer: issuer?.toString(),
    deviceAuthorizationUrl: _validHttpsUri(
      metadata['device_authorization_endpoint'],
    )?.toString(),
    supportsDynamicClientRegistration:
        _stringValue(metadata['registration_endpoint']) != null,
    scopes: scopes,
    authorizationResponseIssuerSupported:
        metadata['authorization_response_iss_parameter_supported'] == true,
  );
}

Future<OAuthDiscoveryResult?> _discoverFromProtectedResource(
  OAuthConnector connector, {
  required Uri resourceUri,
  required mcp.WwwAuthenticateChallenge challenge,
  required _RegistrationOptions registrationOptions,
}) async {
  final advertised = _validHttpsUri(challenge.resourceMetadata);
  final origin = Uri.parse(_baseUrl(connector.serverUrl));
  final resourcePath = resourceUri.path.isEmpty ? '/' : resourceUri.path;
  final metadataUrls = <Uri>[
    ?advertised,
    _wellKnownPath(origin, 'oauth-protected-resource', resourcePath),
    _wellKnownPath(origin, 'oauth-protected-resource', '/'),
    if (resourcePath == '/')
      origin.replace(path: '/.well-known/oauth-protected-resource'),
  ];

  for (final metadataUrl in _uniqueUris(metadataUrls)) {
    final metadata = await _requestJsonObject(metadataUrl);
    if (metadata == null) continue;

    final protectedResource = _protectedResourceMetadata(metadata);
    if (protectedResource == null) continue;
    final resource = _validHttpsUri(protectedResource.resource);
    if (resource == null || !_sameResource(resource, resourceUri)) continue;

    final advertisedScopes = challenge.scopes;
    final resourceScopes = protectedResource.scopesSupported ?? const [];
    _oauthDiscoveryLogger.info(
      'OAuth protected-resource metadata accepted '
      'resource=${_safeOAuthLogUrl(resource)} '
      'authorizationServerCount='
      '${protectedResource.authorizationServers.length} '
      'advertisedScopeCount=${advertisedScopes.length} '
      'supportedScopeCount=${resourceScopes.length}',
    );
    for (final authorizationServer in protectedResource.authorizationServers) {
      final server = _validHttpsUri(authorizationServer);
      if (server == null) continue;
      final discovered = await _discoverAuthorizationServer(
        connector,
        authorizationServer: server,
        resource: resource.toString(),
        preferredScopes: advertisedScopes.isNotEmpty
            ? advertisedScopes
            : resourceScopes,
        registrationOptions: registrationOptions,
      );
      if (discovered != null) return discovered;
    }
  }

  return null;
}

mcp.ProtectedResourceMetadata? _protectedResourceMetadata(
  Map<String, dynamic> json,
) {
  try {
    final metadata = mcp.ProtectedResourceMetadata.fromJson(json);
    if (metadata.resource.isEmpty || metadata.authorizationServers.isEmpty) {
      return null;
    }

    return metadata;
  } on Object {
    return null;
  }
}

Future<OAuthDiscoveryResult?> _discoverAuthorizationServer(
  OAuthConnector connector, {
  required Uri authorizationServer,
  required String resource,
  required List<String> preferredScopes,
  required _RegistrationOptions registrationOptions,
}) async {
  for (final metadataUrl in _authorizationServerMetadataUrls(
    authorizationServer,
  )) {
    final metadata = await _requestJsonObject(metadataUrl);
    if (metadata == null) continue;

    final issuer = _validHttpsUri(metadata['issuer']);
    if (issuer == null || !_sameIssuer(issuer, authorizationServer)) {
      continue;
    }
    final metadataResourceValue = metadata['resource'];
    final metadataResource = metadataResourceValue == null
        ? null
        : _validHttpsUri(metadataResourceValue);
    if (metadataResourceValue != null &&
        (metadataResource == null ||
            !_sameResource(metadataResource, .parse(resource)))) {
      continue;
    }
    final authUrl = _validHttpsUri(metadata['authorization_endpoint']);
    final tokenUrl = _validHttpsUri(metadata['token_endpoint']);
    if (authUrl == null || tokenUrl == null) continue;

    final scopes = preferredScopes.isNotEmpty
        ? preferredScopes
        : _scopes(metadata['scopes_supported'], metadata['scope']);
    final deviceEndpoint = _validHttpsUri(
      metadata['device_authorization_endpoint'],
    );
    _oauthDiscoveryLogger.info(
      'OAuth authorization metadata accepted '
      'issuer=${_safeOAuthLogUrl(issuer)} '
      'clientIdAdvertised=${_stringValue(metadata['client_id']) != null} '
      'dynamicRegistrationAdvertised='
      '${_stringValue(metadata['registration_endpoint']) != null} '
      'deviceFlow=${deviceEndpoint != null} '
      'scopeCount=${scopes.length}',
    );
    final standard = await _completeWellKnownMetadataForMap(
      connector,
      metadata: metadata,
      authorizationUrl: authUrl.toString(),
      tokenUrl: tokenUrl.toString(),
      registrationOptions: registrationOptions,
    );
    final scope = scopes.isEmpty ? standard.scope : scopes.join(' ');

    return OAuthDiscoveryResult(
      authorizationUrl: authUrl.toString(),
      tokenUrl: tokenUrl.toString(),
      clientId: standard.clientId,
      scope: scope,
      resource: resource,
      issuer: issuer.toString(),
      deviceAuthorizationUrl: deviceEndpoint?.toString(),
      supportsDynamicClientRegistration:
          standard.supportsDynamicClientRegistration,
      scopes: scopes,
      authorizationResponseIssuerSupported:
          metadata['authorization_response_iss_parameter_supported'] == true,
    );
  }

  return null;
}

Future<OAuthDiscoveryResult> _completeWellKnownMetadataForMap(
  OAuthConnector connector, {
  required Map<String, dynamic> metadata,
  required String authorizationUrl,
  required String tokenUrl,
  required _RegistrationOptions registrationOptions,
}) async {
  final clientId = await _wellKnownClientId((
    metadata: metadata,
    registrationEndpoint: _stringValue(metadata['registration_endpoint']),
    redirectUrl: connector.redirectUrl,
    clientName: connector.clientName,
    registrationOptions: registrationOptions,
  ));

  return OAuthDiscoveryResult(
    authorizationUrl: authorizationUrl,
    tokenUrl: tokenUrl,
    clientId: clientId,
    scope: _stringValue(metadata['scope']),
    supportsDynamicClientRegistration:
        _stringValue(metadata['registration_endpoint']) != null,
  );
}

List<Uri> _authorizationServerMetadataUrls(Uri authorizationServer) {
  final path = authorizationServer.path.isEmpty
      ? '/'
      : authorizationServer.path;
  final origin = Uri.parse(authorizationServer.origin);

  return _uniqueUris([
    _wellKnownPath(origin, 'oauth-authorization-server', path),
    _wellKnownPath(origin, 'openid-configuration', path),
    if (path == '/')
      origin.replace(path: '/.well-known/oauth-authorization-server'),
    if (path == '/') origin.replace(path: '/.well-known/openid-configuration'),
  ]);
}

Uri _wellKnownPath(Uri origin, String name, String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';

  return origin.replace(path: '/.well-known/$name$normalizedPath');
}

List<Uri> _uniqueUris(List<Uri> values) => [
  for (var index = 0; index < values.length; index++)
    if (values.indexOf(values[index]) == index) values[index],
];

Future<Map<String, dynamic>?> _requestJsonObject(Uri uri) async {
  try {
    final response = await http
        .get(uri, headers: _jsonAcceptHeader)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != HttpStatus.ok) return null;
    final contentType = response.headers['content-type'];
    if (contentType != null && !contentType.toLowerCase().contains('json')) {
      return null;
    }

    return _decodeJsonObjectBody(response.body);
  } on Exception {
    return null;
  }
}

Map<String, dynamic>? _decodeJsonObject(http.Response response) {
  final contentType = response.headers['content-type'];
  if (contentType != null && !contentType.toLowerCase().contains('json')) {
    return null;
  }

  return _decodeJsonObjectBody(response.body);
}

Map<String, dynamic>? _decodeJsonObjectBody(String body) {
  try {
    final decoded = json.decode(body);

    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

Uri? _validHttpsUri(Object? value) {
  if (value is! String || value.isEmpty) return null;
  try {
    return requirePublicUriSyntax(value, requireHttps: true);
  } on FormatException {
    return null;
  }
}

String? _stringValue(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

List<String> _stringList(Object? value) => value is List
    ? value.whereType<String>().where((value) => value.isNotEmpty).toList()
    : const [];

List<String> _scopes(Object? supported, Object? fallback) {
  final supportedScopes = _stringList(supported);
  if (supportedScopes.isNotEmpty) return supportedScopes;
  if (fallback is! String || fallback.isEmpty) return const [];

  return fallback
      .split(RegExp(r'\s+'))
      .where((value) => value.isNotEmpty)
      .toList();
}

bool _sameResource(Uri left, Uri right) {
  String path(Uri uri) {
    final value = uri.path.isEmpty ? '/' : uri.path;

    return value.endsWith('/') ? value : '$value/';
  }

  return left.scheme == right.scheme &&
      left.host.toLowerCase() == right.host.toLowerCase() &&
      left.port == right.port &&
      path(left) == path(right);
}

bool _sameIssuer(Uri left, Uri right) =>
    left.scheme == right.scheme &&
    left.host.toLowerCase() == right.host.toLowerCase() &&
    left.port == right.port &&
    left.path.replaceAll(RegExp(r'/$'), '') ==
        right.path.replaceAll(RegExp(r'/$'), '') &&
    left.query == right.query &&
    left.fragment == right.fragment;

String _baseUrl(String serverUrl) {
  final uri = Uri.tryParse(serverUrl);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return '';

  return uri.origin;
}

String _safeOAuthLogUrl(Object? value) {
  final uri = Uri.tryParse(value?.toString() ?? '');
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    return '<none>';
  }

  return '${uri.origin}${uri.path.isEmpty ? '/' : uri.path}';
}

typedef _RegistrationOptions = ({http.Client? client, PublicUrlLookup? lookup});

typedef _WellKnownEndpoints = ({String authorizationUrl, String tokenUrl});

typedef _WellKnownClientRequest = ({
  Map<String, dynamic> metadata,
  String? registrationEndpoint,
  String redirectUrl,
  String clientName,
  _RegistrationOptions registrationOptions,
});

typedef _WellKnownMetadataInput = ({
  _WellKnownEndpoints endpoints,
  Map<String, dynamic> metadata,
  String redirectUrl,
  String clientName,
  Uri? resourceUri,
  _RegistrationOptions registrationOptions,
});

typedef _DynamicClientRegistrationRequest = ({
  String registrationEndpoint,
  String redirectUrl,
  String clientName,
  _RegistrationOptions registrationOptions,
});

typedef _DynamicClientRegistrationHttpRequest = ({
  String registrationEndpoint,
  List<String>? resolvedAddresses,
  String redirectUrl,
  String clientName,
  _RegistrationOptions registrationOptions,
});

_WellKnownEndpoints? _wellKnownEndpoints(Map<String, dynamic> metadata) {
  final authorizationUrl = _stringValue(metadata['authorization_endpoint']);
  final tokenUrl = _stringValue(metadata['token_endpoint']);
  final validAuthorizationUrl = _validHttpsUri(authorizationUrl);
  final validTokenUrl = _validHttpsUri(tokenUrl);
  if (validAuthorizationUrl == null || validTokenUrl == null) return null;

  return (
    authorizationUrl: validAuthorizationUrl.toString(),
    tokenUrl: validTokenUrl.toString(),
  );
}

Future<OAuthDiscoveryResult?> _completeWellKnownMetadata(
  _WellKnownMetadataInput input,
) async {
  final resourceValue = input.metadata['resource'];
  final resource = resourceValue == null ? null : _validHttpsUri(resourceValue);
  if (resourceValue != null) {
    if (resource == null) return null;
    final resourceUri = input.resourceUri;
    if (resourceUri != null && !_sameResource(resource, resourceUri)) {
      return null;
    }
  }
  final issuerValue = input.metadata['issuer'];
  final issuer = issuerValue == null ? null : _validHttpsUri(issuerValue);
  if (issuerValue != null && issuer == null) return null;
  final scopes = _scopes(
    input.metadata['scopes_supported'],
    input.metadata['scope'],
  );
  final clientId = await _wellKnownClientId(_wellKnownClientRequest(input));

  return OAuthDiscoveryResult(
    authorizationUrl: input.endpoints.authorizationUrl,
    tokenUrl: input.endpoints.tokenUrl,
    clientId: clientId,
    scope: _stringValue(input.metadata['scope']) ?? scopes.join(' '),
    resource: resource?.toString() ?? input.resourceUri?.toString(),
    issuer: issuer?.toString(),
    deviceAuthorizationUrl: _validHttpsUri(
      input.metadata['device_authorization_endpoint'],
    )?.toString(),
    supportsDynamicClientRegistration:
        _stringValue(input.metadata['registration_endpoint']) != null,
    scopes: scopes,
    authorizationResponseIssuerSupported:
        input.metadata['authorization_response_iss_parameter_supported'] ==
        true,
  );
}

_WellKnownClientRequest _wellKnownClientRequest(
  _WellKnownMetadataInput input,
) => (
  metadata: input.metadata,
  registrationEndpoint: _stringValue(input.metadata['registration_endpoint']),
  redirectUrl: input.redirectUrl,
  clientName: input.clientName,
  registrationOptions: input.registrationOptions,
);

Future<http.Response> _requestWellKnown(String url) => http
    .get(.parse(url), headers: _jsonAcceptHeader)
    .timeout(const Duration(seconds: 5));

Future<String?> _wellKnownClientId(_WellKnownClientRequest request) async {
  final clientId = _stringValue(request.metadata['client_id']);
  final registrationEndpoint = request.registrationEndpoint;
  if (clientId != null) return clientId;
  if (registrationEndpoint == null) {
    _oauthDiscoveryLogger.info(
      'OAuth metadata has no client ID or dynamic registration endpoint',
    );

    return null;
  }

  return await _tryDynamicClientRegistration(
    registrationEndpoint: registrationEndpoint,
    redirectUrl: request.redirectUrl,
    clientName: request.clientName,
    registrationOptions: request.registrationOptions,
  );
}

Future<String?> _tryDynamicClientRegistration({
  required String registrationEndpoint,
  required String redirectUrl,
  required String clientName,
  required _RegistrationOptions registrationOptions,
}) => _performDynamicClientRegistrationSafely((
  registrationEndpoint: registrationEndpoint,
  redirectUrl: redirectUrl,
  clientName: clientName,
  registrationOptions: registrationOptions,
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
      registrationOptions: request.registrationOptions,
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
  required _RegistrationOptions registrationOptions,
}) async {
  final resolvedRegistration = await PublicUrlGuard.resolveHttpsUri(
    registrationEndpoint,
    lookup: registrationOptions.lookup ?? InternetAddress.lookup,
  );

  return _registeredClientId(
    await _postDynamicClientRegistration((
      registrationEndpoint: resolvedRegistration.uri.toString(),
      resolvedAddresses: resolvedRegistration.addresses,
      redirectUrl: redirectUrl,
      clientName: clientName,
      registrationOptions: registrationOptions,
    )),
  );
}

http.Client _registrationHttpClient(List<String> resolvedAddresses) {
  if (resolvedAddresses.isEmpty) {
    throw StateError('Missing resolved registration address');
  }

  final client = HttpClient()
    ..findProxy = ((_) => 'DIRECT')
    ..connectionFactory = (target, _, _) =>
        _startPinnedConnection(target, resolvedAddresses);

  return http_io.IOClient(client);
}

Future<ConnectionTask<Socket>> _startPinnedConnection(
  Uri target,
  List<String> resolvedAddresses,
) async {
  final deadline = Stopwatch()..start();

  for (final address in resolvedAddresses) {
    final connection = await _tryPinnedConnection(target, address, deadline);
    if (connection != null) return connection;
  }

  throw const SocketException('Unable to connect to registration endpoint');
}

Future<ConnectionTask<Socket>?> _tryPinnedConnection(
  Uri target,
  String address,
  Stopwatch deadline,
) async {
  try {
    return await _openPinnedSocket(target, address, deadline);
  } on Exception {
    return null;
  }
}

Future<ConnectionTask<Socket>> _openPinnedSocket(
  Uri target,
  String address,
  Stopwatch deadline,
) async {
  final connectTimeout = _remainingPinnedTimeout(deadline);
  if (connectTimeout == null) {
    throw const SocketException('Pinned connection deadline expired');
  }

  final socket = await Socket.connect(
    InternetAddress(address),
    target.port,
    timeout: connectTimeout,
  );

  return await _securePinnedSocketTask(socket, target, deadline);
}

Future<ConnectionTask<Socket>> _securePinnedSocketTask(
  Socket socket,
  Uri target,
  Stopwatch deadline,
) async {
  final tlsTimeout = _remainingPinnedTimeout(deadline);
  if (tlsTimeout == null) {
    socket.destroy();

    throw const SocketException('Pinned connection deadline expired');
  }

  try {
    final secureSocket = await _securePinnedSocket(socket, target, tlsTimeout);

    return .fromSocket(.value(secureSocket), secureSocket.destroy);
  } on Exception {
    socket.destroy();

    rethrow;
  }
}

Duration? _remainingPinnedTimeout(Stopwatch deadline) {
  final remaining = const Duration(seconds: 10) - deadline.elapsed;

  return remaining <= .zero ? null : remaining;
}

Future<SecureSocket> _securePinnedSocket(
  Socket socket,
  Uri target,
  Duration timeout,
) => SecureSocket.secure(socket, host: target.host).timeout(timeout);

Future<http.Response> _requestDirectProbe(Uri uri) => http
    .get(uri, headers: {'Accept': 'text/event-stream'})
    .timeout(const Duration(seconds: 5));

Uri? _probeUri(String serverUrl) {
  final uri = Uri.tryParse(serverUrl);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;

  return uri;
}

OAuthDiscoveryResult? _headerChallengeResult(
  http.Response response, {
  Uri? resourceUri,
}) {
  final authEndpoint = _validHttpsUri(
    response.headers['x-oauth-authorization-url'],
  );
  final tokenEndpoint = _validHttpsUri(response.headers['x-oauth-token-url']);
  if (authEndpoint == null || tokenEndpoint == null) return null;

  final resourceValue = response.headers['x-oauth-resource'];
  final resource = resourceValue == null ? null : _validHttpsUri(resourceValue);
  if (resourceValue != null &&
      (resource == null ||
          resourceUri != null && !_sameResource(resource, resourceUri))) {
    return null;
  }
  final issuerValue = response.headers['x-oauth-issuer'];
  final issuer = issuerValue == null ? null : _validHttpsUri(issuerValue);
  if (issuerValue != null && issuer == null) return null;
  final scopes = _scopes(const [], response.headers['x-oauth-scope']);

  return OAuthDiscoveryResult(
    authorizationUrl: authEndpoint.toString(),
    tokenUrl: tokenEndpoint.toString(),
    clientId: response.headers['x-oauth-client-id'],
    scope: response.headers['x-oauth-scope'],
    resource: resource?.toString() ?? resourceUri?.toString(),
    issuer: issuer?.toString(),
    deviceAuthorizationUrl: _validHttpsUri(
      response.headers['x-oauth-device-url'],
    )?.toString(),
    scopes: scopes,
  );
}

Future<http.Response> _requestOAuthMetadata(String url) => http
    .get(.parse(url), headers: _jsonAcceptHeader)
    .timeout(const Duration(seconds: 5));

Future<OAuthDiscoveryResult?> _metadataResponse(
  http.Response response, {
  required String redirectUrl,
  required String clientName,
  required _RegistrationOptions registrationOptions,
  Uri? resourceUri,
}) async {
  if (response.statusCode != HttpStatus.ok) return null;

  final metadata = _decodeJsonObject(response);
  if (metadata == null) return null;

  return await _parseMetadataMap(
    metadata,
    redirectUrl: redirectUrl,
    clientName: clientName,
    registrationOptions: registrationOptions,
    resourceUri: resourceUri,
  );
}

Future<http.Response> _postDynamicClientRegistration(
  _DynamicClientRegistrationHttpRequest input,
) async {
  final request = _registrationRequest(input);
  final registrationClient = _registrationClient(input);

  try {
    return await _sendRegistrationRequest(
      registrationClient.client,
      request,
    ).timeout(const Duration(seconds: 10));
  } finally {
    if (registrationClient.close) registrationClient.client.close();
  }
}

http.Request _registrationRequest(_DynamicClientRegistrationHttpRequest input) {
  final clientMetadata = _dynamicClientMetadata(
    input.clientName,
    input.redirectUrl,
  );

  return http.Request('POST', .parse(input.registrationEndpoint))
    ..followRedirects = false
    ..headers.addAll({'Content-Type': 'application/json', ..._jsonAcceptHeader})
    ..body = json.encode(clientMetadata);
}

({http.Client client, bool close}) _registrationClient(
  _DynamicClientRegistrationHttpRequest input,
) {
  final resolvedAddresses = input.resolvedAddresses;
  if (resolvedAddresses != null) {
    return (client: _registrationHttpClient(resolvedAddresses), close: true);
  }

  final client = input.registrationOptions.client ?? http.Client();

  return (client: client, close: input.registrationOptions.client == null);
}

Future<http.Response> _sendRegistrationRequest(
  http.Client client,
  http.Request request,
) async {
  return await http.Response.fromStream(await client.send(request));
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
  'application_type': 'native',
};

String? _registeredClientId(http.Response response) {
  if (!_isRegistrationSuccess(response.statusCode)) {
    return _logRegistrationFailure(response.statusCode);
  }

  final contentType = response.headers['content-type'];
  if (contentType != null && !contentType.toLowerCase().contains('json')) {
    return null;
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
  final registrationResponse = _decodeJsonObjectBody(body);
  if (registrationResponse == null) return null;

  final clientId = _stringValue(registrationResponse['client_id'])?.trim();

  return clientId == null || clientId.isEmpty ? null : clientId;
}
