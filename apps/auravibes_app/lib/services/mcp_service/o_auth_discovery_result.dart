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
const _contentTypeHeaderName = 'content-type';
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
}) {
  // ignore: unnecessary_type_name_in_constructor - Required by Dart primary constructor syntax.
  OAuthDiscoveryResult._fromMetadataMap(
    _MetadataMapResultInput input,
    String? clientId,
  ) : this(
        authorizationUrl: input.endpoints.authorizationUrl,
        tokenUrl: input.endpoints.tokenUrl,
        clientId: clientId,
        scope: _stringValue(input.metadata['scope']) ?? input.scopes.join(' '),
        resource:
            input.resource?.toString() ?? input.context.resourceUri?.toString(),
        issuer: input.issuer?.toString(),
        deviceAuthorizationUrl: _validHttpsUri(
          input.metadata['device_authorization_endpoint'],
        )?.toString(),
        supportsDynamicClientRegistration:
            _stringValue(input.metadata['registration_endpoint']) != null,
        scopes: input.scopes,
        authorizationResponseIssuerSupported:
            input.metadata['authorization_response_iss_parameter_supported'] ==
            true,
      );

  // ignore: unnecessary_type_name_in_constructor - Required by Dart primary constructor syntax.
  OAuthDiscoveryResult._fromAuthorizationMetadata(
    _AuthorizationMetadataResultInput input,
  ) : this(
        authorizationUrl: input.authorization.authorizationUrl,
        tokenUrl: input.authorization.tokenUrl,
        clientId: input.clientId,
        scope: input.authorization.scopes.join(' '),
        resource: input.server.resource,
        issuer: input.authorization.issuer.toString(),
        deviceAuthorizationUrl: input.authorization.deviceAuthorizationUrl
            ?.toString(),
        supportsDynamicClientRegistration:
            _stringValue(input.metadata['registration_endpoint']) != null,
        scopes: input.authorization.scopes,
        authorizationResponseIssuerSupported:
            input.authorization.authorizationResponseIssuerSupported,
      );

  // ignore: unnecessary_type_name_in_constructor - Required by Dart primary constructor syntax.
  OAuthDiscoveryResult._fromWellKnown(
    _WellKnownMetadataInput input,
    _WellKnownMetadataValidation validated,
    String? clientId,
  ) : this(
        authorizationUrl: input.endpoints.authorizationUrl,
        tokenUrl: input.endpoints.tokenUrl,
        clientId: clientId,
        scope:
            _stringValue(input.metadata['scope']) ?? validated.scopes.join(' '),
        resource: validated.resource?.toString(),
        issuer: validated.issuer?.toString(),
        deviceAuthorizationUrl: _validHttpsUri(
          input.metadata['device_authorization_endpoint'],
        )?.toString(),
        supportsDynamicClientRegistration:
            _stringValue(input.metadata['registration_endpoint']) != null,
        scopes: validated.scopes,
        authorizationResponseIssuerSupported:
            input.metadata['authorization_response_iss_parameter_supported'] ==
            true,
      );

  // ignore: unnecessary_type_name_in_constructor - Required by Dart primary constructor syntax.
  OAuthDiscoveryResult._fromHeaderChallenge(
    _HeaderChallengeEndpoints endpoints,
    _HeaderChallengeMetadata metadata,
    Uri resourceUri,
  ) : this(
        authorizationUrl: endpoints.authorization.toString(),
        tokenUrl: endpoints.token.toString(),
        clientId: metadata.clientId,
        scope: metadata.scope,
        resource: metadata.resource?.toString() ?? resourceUri.toString(),
        issuer: metadata.issuer?.toString(),
        deviceAuthorizationUrl: metadata.deviceAuthorizationUrl?.toString(),
        scopes: metadata.scopes,
      );
}

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

    return await _wellKnownResponse(response, (
      redirectUrl: connector.redirectUrl,
      clientName: connector.clientName,
      resourceUri: _probeUri(connector.serverUrl),
      registrationOptions: registrationOptions,
    ));
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

      return await _parseDirectProbeResponse(await _requestDirectProbe(uri), (
        connector: connector,
        resourceUri: uri,
        registrationOptions: registrationOptions,
      ));
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
    http.Response response,
    _DirectProbeInput input,
  ) async {
    if (response.statusCode != 401) return null;

    final discovered = await _discoverFromDirectChallenge(response, input);
    if (discovered != null) return discovered;

    return _parseOAuthHeaderChallenge(response, resourceUri: input.resourceUri);
  }

  static Future<OAuthDiscoveryResult?> _discoverFromDirectChallenge(
    http.Response response,
    _DirectProbeInput input,
  ) {
    final challenge = mcp.WwwAuthenticateChallenge.parse(
      response.headers['www-authenticate'],
    );
    if (challenge == null || !challenge.isBearer) return Future.value();

    return _discoverFromProtectedResource((
      connector: input.connector,
      resourceUri: input.resourceUri,
      challenge: challenge,
      registrationOptions: input.registrationOptions,
    ));
  }

  static OAuthDiscoveryResult? _parseOAuthHeaderChallenge(
    http.Response response, {
    required Uri resourceUri,
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

      return await _requestAndParseOAuthMetadata(
        metadataUrl,
        connector,
        registrationOptions,
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

Future<OAuthDiscoveryResult?> _requestAndParseOAuthMetadata(
  String metadataUrl,
  OAuthConnector connector,
  _RegistrationOptions registrationOptions,
) async {
  final response = await _requestOAuthMetadata(metadataUrl);

  return await _metadataResponse(
    response,
    context: (
      redirectUrl: connector.redirectUrl,
      clientName: connector.clientName,
      resourceUri: _probeUri(connector.serverUrl),
      registrationOptions: registrationOptions,
    ),
  );
}

String _wellKnownUrl(String baseUrl) =>
    '$baseUrl/.well-known/oauth-authorization-server';

Future<OAuthDiscoveryResult?> _wellKnownResponse(
  http.Response response,
  _DiscoveryContext context,
) {
  if (response.statusCode != HttpStatus.ok) return Future.value();

  final metadata = _decodeJsonObject(response);
  if (metadata == null) return Future.value();

  return _parseWellKnownMetadata(metadata, context);
}

Future<OAuthDiscoveryResult?> _parseWellKnownMetadata(
  Map<String, dynamic> metadata,
  _DiscoveryContext context,
) async {
  final endpoints = _wellKnownEndpoints(metadata);
  if (endpoints == null) return null;

  return await _completeWellKnownMetadata((
    endpoints: endpoints,
    metadata: metadata,
    redirectUrl: context.redirectUrl,
    clientName: context.clientName,
    resourceUri: context.resourceUri,
    registrationOptions: context.registrationOptions,
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

Future<OAuthDiscoveryResult?> _parseMetadataMap(_MetadataMapInput input) async {
  final validated = _validateMetadataMap(input);
  if (validated == null) return null;

  return await _buildMetadataMapResult((
    metadata: input.metadata,
    endpoints: validated.endpoints,
    context: input.context,
    resource: validated.resource,
    issuer: validated.issuer,
    scopes: validated.scopes,
  ));
}

_MetadataMapValidation? _validateMetadataMap(_MetadataMapInput input) {
  final endpoints = _metadataMapEndpoints(input.metadata);
  if (endpoints == null) return null;

  final resourceAndIssuer = _metadataMapResourceAndIssuer(input);
  if (resourceAndIssuer == null) return null;

  return _metadataMapValidationResult((
    metadata: input.metadata,
    endpoints: endpoints,
    resource: resourceAndIssuer.resource,
    issuer: resourceAndIssuer.issuer,
  ));
}

_MetadataMapResourceAndIssuer? _metadataMapResourceAndIssuer(
  _MetadataMapInput input,
) {
  final metadata = input.metadata;
  final resource = _metadataResource(
    metadata['resource'],
    input.context.resourceUri,
  );
  if (metadata['resource'] != null && resource == null) return null;

  final issuer = _validHttpsUri(metadata['issuer']);
  if (metadata['issuer'] != null && issuer == null) return null;

  return (resource: resource, issuer: issuer);
}

_MetadataMapValidation _metadataMapValidationResult(
  _MetadataMapValidationInput input,
) => (
  endpoints: input.endpoints,
  resource: input.resource,
  issuer: input.issuer,
  scopes: _scopes(input.metadata['scopes_supported'], input.metadata['scope']),
);

_WellKnownEndpoints? _metadataMapEndpoints(Map<String, dynamic> metadata) {
  final authorizationUrl = _validHttpsUri(metadata['authorization_url']);
  final tokenUrl = _validHttpsUri(metadata['token_url']);
  if (authorizationUrl == null || tokenUrl == null) return null;

  return (
    authorizationUrl: authorizationUrl.toString(),
    tokenUrl: tokenUrl.toString(),
  );
}

Uri? _metadataResource(Object? value, Uri? expected) {
  if (value == null) return expected;
  final resource = _validHttpsUri(value);
  if (resource == null ||
      expected != null && !_sameResource(resource, expected)) {
    return null;
  }

  return resource;
}

Future<OAuthDiscoveryResult> _buildMetadataMapResult(
  _MetadataMapResultInput input,
) async {
  final clientId = await _metadataMapClientId(input);

  return _createMetadataMapResult(input, clientId);
}

Future<String?> _metadataMapClientId(_MetadataMapResultInput input) {
  final metadata = input.metadata;
  final context = input.context;

  return _wellKnownClientId((
    metadata: metadata,
    registrationEndpoint: _stringValue(metadata['registration_endpoint']),
    redirectUrl: context.redirectUrl,
    clientName: context.clientName,
    registrationOptions: context.registrationOptions,
  ));
}

OAuthDiscoveryResult _createMetadataMapResult(
  _MetadataMapResultInput input,
  String? clientId,
) => OAuthDiscoveryResult._fromMetadataMap(input, clientId);

Future<OAuthDiscoveryResult?> _discoverFromProtectedResource(
  _ProtectedResourceInput input,
) async {
  for (final metadataUrl in _protectedResourceMetadataUrls(input)) {
    final discovered = await _discoverProtectedResourceAt(metadataUrl, input);
    if (discovered != null) return discovered;
  }

  return null;
}

List<Uri> _protectedResourceMetadataUrls(_ProtectedResourceInput input) {
  final advertised = _validHttpsUri(input.challenge.resourceMetadata);
  final origin = Uri.parse(_baseUrl(input.connector.serverUrl));
  final resourcePath = input.resourceUri.path.isEmpty
      ? '/'
      : input.resourceUri.path;

  return _protectedResourceMetadataCandidates(origin, resourcePath, advertised);
}

List<Uri> _protectedResourceMetadataCandidates(
  Uri origin,
  String resourcePath,
  Uri? advertised,
) {
  return _uniqueUris([
    ?advertised,
    _wellKnownPath(origin, 'oauth-protected-resource', resourcePath),
    _wellKnownPath(origin, 'oauth-protected-resource', '/'),
    if (resourcePath == '/')
      origin.replace(path: '/.well-known/oauth-protected-resource'),
  ]);
}

Future<OAuthDiscoveryResult?> _discoverProtectedResourceAt(
  Uri metadataUrl,
  _ProtectedResourceInput input,
) async {
  final metadata = await _requestJsonObject(metadataUrl);
  if (metadata == null) return null;

  final protectedResource = _protectedResourceMetadata(metadata);
  if (protectedResource == null) return null;
  final resourceUri = input.resourceUri;
  final resource = _protectedResourceUri(protectedResource, resourceUri);
  if (resource == null) return null;

  return await _discoverProtectedResourceAuthorization(
    input,
    protectedResource,
    resource,
  );
}

Future<OAuthDiscoveryResult?> _discoverProtectedResourceAuthorization(
  _ProtectedResourceInput input,
  mcp.ProtectedResourceMetadata protectedResource,
  Uri resource,
) => _discoverAuthorizationServers(
  _protectedResourceDiscoveryInput(input, protectedResource, resource),
);

_ProtectedResourceDiscoveryInput _protectedResourceDiscoveryInput(
  _ProtectedResourceInput input,
  mcp.ProtectedResourceMetadata protectedResource,
  Uri resource,
) {
  final advertisedScopes = input.challenge.scopes;
  _logProtectedResource(resource, protectedResource, advertisedScopes);

  return (
    connector: input.connector,
    resource: resource,
    authorizationServers: protectedResource.authorizationServers,
    preferredScopes: _preferredProtectedResourceScopes(
      advertisedScopes,
      protectedResource.scopesSupported,
    ),
    registrationOptions: input.registrationOptions,
  );
}

List<String> _preferredProtectedResourceScopes(
  List<String> advertised,
  List<String>? supported,
) => advertised.isNotEmpty ? advertised : supported ?? const <String>[];

Uri? _protectedResourceUri(
  mcp.ProtectedResourceMetadata metadata,
  Uri expected,
) {
  final resource = _validHttpsUri(metadata.resource);
  if (resource == null || !_sameResource(resource, expected)) return null;

  return resource;
}

void _logProtectedResource(
  Uri resource,
  mcp.ProtectedResourceMetadata metadata,
  List<String> advertisedScopes,
) {
  final resourceScopes = metadata.scopesSupported ?? const [];
  _oauthDiscoveryLogger.info(
    'OAuth protected-resource metadata accepted '
    'resource=${_safeOAuthLogUrl(resource)} '
    'authorizationServerCount=${metadata.authorizationServers.length} '
    'advertisedScopeCount=${advertisedScopes.length} '
    'supportedScopeCount=${resourceScopes.length}',
  );
}

Future<OAuthDiscoveryResult?> _discoverAuthorizationServers(
  _ProtectedResourceDiscoveryInput input,
) async {
  for (final authorizationServer in input.authorizationServers) {
    final server = _validHttpsUri(authorizationServer);
    if (server == null) continue;
    final discovered = await _discoverAuthorizationServer((
      connector: input.connector,
      authorizationServer: server,
      resource: input.resource.toString(),
      preferredScopes: input.preferredScopes,
      registrationOptions: input.registrationOptions,
    ));
    if (discovered != null) return discovered;
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
  _AuthorizationServerInput input,
) async {
  for (final metadataUrl in _authorizationServerMetadataUrls(
    input.authorizationServer,
  )) {
    final result = await _authorizationMetadataResult(metadataUrl, input);
    if (result != null) return result;
  }

  return null;
}

Future<OAuthDiscoveryResult?> _authorizationMetadataResult(
  Uri metadataUrl,
  _AuthorizationServerInput input,
) async {
  final metadata = await _requestJsonObject(metadataUrl);
  if (metadata == null) return null;

  final authorization = _parseAuthorizationMetadata((
    metadata: metadata,
    authorizationServer: input.authorizationServer,
    resource: Uri.parse(input.resource),
    preferredScopes: input.preferredScopes,
  ));
  if (authorization == null) return null;

  return await _buildAuthorizationMetadataResult(
    metadata,
    input,
    authorization,
  );
}

Future<OAuthDiscoveryResult> _buildAuthorizationMetadataResult(
  Map<String, dynamic> metadata,
  _AuthorizationServerInput input,
  _AuthorizationMetadata authorization,
) async {
  final clientId = await _authorizationMetadataClientId(metadata, input);

  return _createAuthorizationMetadataResult((
    metadata: metadata,
    server: input,
    authorization: authorization,
    clientId: clientId,
  ));
}

Future<String?> _authorizationMetadataClientId(
  Map<String, dynamic> metadata,
  _AuthorizationServerInput input,
) => _wellKnownClientId((
  metadata: metadata,
  registrationEndpoint: _stringValue(metadata['registration_endpoint']),
  redirectUrl: input.connector.redirectUrl,
  clientName: input.connector.clientName,
  registrationOptions: input.registrationOptions,
));

OAuthDiscoveryResult _createAuthorizationMetadataResult(
  _AuthorizationMetadataResultInput input,
) {
  _logAuthorizationMetadata(input.metadata, input.authorization);

  return OAuthDiscoveryResult._fromAuthorizationMetadata(input);
}

_AuthorizationMetadata? _parseAuthorizationMetadata(
  _AuthorizationMetadataValidationInput input,
) {
  final issuer = _authorizationIssuer(
    input.metadata,
    input.authorizationServer,
  );
  if (issuer == null || !_authorizationResourceMatches(input)) return null;

  final endpoints = _wellKnownEndpoints(input.metadata);
  if (endpoints == null) return null;

  return _createAuthorizationMetadata(input, issuer, endpoints);
}

_AuthorizationMetadata _createAuthorizationMetadata(
  _AuthorizationMetadataValidationInput input,
  Uri issuer,
  _WellKnownEndpoints endpoints,
) {
  final metadata = input.metadata;
  final deviceAuthorizationUrl = _validHttpsUri(
    metadata['device_authorization_endpoint'],
  );
  final scopes = input.preferredScopes.isNotEmpty
      ? input.preferredScopes
      : _scopes(metadata['scopes_supported'], metadata['scope']);

  return (
    issuer: issuer,
    authorizationUrl: endpoints.authorizationUrl,
    tokenUrl: endpoints.tokenUrl,
    deviceAuthorizationUrl: deviceAuthorizationUrl,
    scopes: scopes,
    authorizationResponseIssuerSupported:
        metadata['authorization_response_iss_parameter_supported'] == true,
  );
}

Uri? _authorizationIssuer(
  Map<String, dynamic> metadata,
  Uri authorizationServer,
) {
  final issuer = _validHttpsUri(metadata['issuer']);
  if (issuer == null || !_sameIssuer(issuer, authorizationServer)) return null;

  return issuer;
}

bool _authorizationResourceMatches(
  _AuthorizationMetadataValidationInput input,
) {
  final value = input.metadata['resource'];
  if (value == null) return true;

  final resource = _validHttpsUri(value);

  return resource != null && _sameResource(resource, input.resource);
}

void _logAuthorizationMetadata(
  Map<String, dynamic> metadata,
  _AuthorizationMetadata authorization,
) {
  final clientIdAdvertised = _stringValue(metadata['client_id']) != null;
  final dynamicRegistrationAdvertised =
      _stringValue(metadata['registration_endpoint']) != null;
  _oauthDiscoveryLogger.info(
    'OAuth authorization metadata accepted '
    'issuer=${_safeOAuthLogUrl(authorization.issuer)} '
    'clientIdAdvertised=$clientIdAdvertised '
    'dynamicRegistrationAdvertised=$dynamicRegistrationAdvertised '
    'deviceFlow=${authorization.deviceAuthorizationUrl != null} '
    'scopeCount=${authorization.scopes.length}',
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
    if (response.statusCode != HttpStatus.ok ||
        !_hasJsonContentType(response)) {
      return null;
    }

    return _decodeJsonObjectBody(response.body);
  } on Exception {
    return null;
  }
}

Map<String, dynamic>? _decodeJsonObject(http.Response response) {
  if (!_hasJsonContentType(response)) return null;

  return _decodeJsonObjectBody(response.body);
}

bool _hasJsonContentType(http.Response response) {
  final contentType = response.headers[_contentTypeHeaderName];

  return contentType == null || contentType.toLowerCase().contains('json');
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

bool _sameResource(Uri left, Uri right) =>
    _sameOrigin(left, right) && _resourcePath(left) == _resourcePath(right);

String _resourcePath(Uri uri) {
  final path = uri.path.isEmpty ? '/' : uri.path;

  return path.endsWith('/') ? path : '$path/';
}

bool _sameIssuer(Uri left, Uri right) =>
    _sameOrigin(left, right) &&
    _issuerPath(left) == _issuerPath(right) &&
    left.query == right.query &&
    left.fragment == right.fragment;

bool _sameOrigin(Uri left, Uri right) =>
    left.scheme == right.scheme &&
    left.host.toLowerCase() == right.host.toLowerCase() &&
    left.port == right.port;

String _issuerPath(Uri uri) => uri.path.replaceAll(RegExp(r'/$'), '');

String _baseUrl(String serverUrl) {
  final uri = Uri.tryParse(serverUrl);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return '';

  return uri.origin;
}

String _safeOAuthLogUrl(Object value) {
  final uri = Uri.tryParse(value.toString());
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

typedef _DiscoveryContext = ({
  String redirectUrl,
  String clientName,
  Uri? resourceUri,
  _RegistrationOptions registrationOptions,
});

typedef _ProtectedResourceInput = ({
  OAuthConnector connector,
  Uri resourceUri,
  mcp.WwwAuthenticateChallenge challenge,
  _RegistrationOptions registrationOptions,
});

typedef _DirectProbeInput = ({
  OAuthConnector connector,
  Uri resourceUri,
  _RegistrationOptions registrationOptions,
});

typedef _ProtectedResourceDiscoveryInput = ({
  OAuthConnector connector,
  Uri resource,
  List<String> authorizationServers,
  List<String> preferredScopes,
  _RegistrationOptions registrationOptions,
});

typedef _AuthorizationServerInput = ({
  OAuthConnector connector,
  Uri authorizationServer,
  String resource,
  List<String> preferredScopes,
  _RegistrationOptions registrationOptions,
});

typedef _AuthorizationMetadata = ({
  Uri issuer,
  Uri? deviceAuthorizationUrl,
  String authorizationUrl,
  String tokenUrl,
  List<String> scopes,
  bool authorizationResponseIssuerSupported,
});

typedef _AuthorizationMetadataResultInput = ({
  Map<String, dynamic> metadata,
  _AuthorizationServerInput server,
  _AuthorizationMetadata authorization,
  String? clientId,
});

typedef _AuthorizationMetadataValidationInput = ({
  Map<String, dynamic> metadata,
  Uri authorizationServer,
  Uri resource,
  List<String> preferredScopes,
});

typedef _MetadataMapInput = ({
  Map<String, dynamic> metadata,
  _DiscoveryContext context,
});

typedef _MetadataMapResourceAndIssuer = ({Uri? resource, Uri? issuer});

typedef _MetadataMapValidation = ({
  _WellKnownEndpoints endpoints,
  Uri? resource,
  Uri? issuer,
  List<String> scopes,
});

typedef _MetadataMapValidationInput = ({
  Map<String, dynamic> metadata,
  _WellKnownEndpoints endpoints,
  Uri? resource,
  Uri? issuer,
});

typedef _WellKnownMetadataValidation = ({
  Uri? resource,
  Uri? issuer,
  List<String> scopes,
});

typedef _MetadataMapResultInput = ({
  Map<String, dynamic> metadata,
  _WellKnownEndpoints endpoints,
  _DiscoveryContext context,
  Uri? resource,
  Uri? issuer,
  List<String> scopes,
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
  final validated = _validateWellKnownMetadata(input);
  if (validated == null) return null;
  final clientId = await _wellKnownClientId(_wellKnownClientRequest(input));

  return _createWellKnownResult(input, validated, clientId);
}

_WellKnownMetadataValidation? _validateWellKnownMetadata(
  _WellKnownMetadataInput input,
) {
  final metadata = input.metadata;
  final resource = _wellKnownResource(input);
  if (metadata['resource'] != null && resource == null) return null;
  final issuer = _validHttpsUri(metadata['issuer']);
  if (metadata['issuer'] != null && issuer == null) return null;

  return (
    resource: resource,
    issuer: issuer,
    scopes: _scopes(metadata['scopes_supported'], metadata['scope']),
  );
}

OAuthDiscoveryResult _createWellKnownResult(
  _WellKnownMetadataInput input,
  _WellKnownMetadataValidation validated,
  String? clientId,
) => OAuthDiscoveryResult._fromWellKnown(input, validated, clientId);

Uri? _wellKnownResource(_WellKnownMetadataInput input) {
  final value = input.metadata['resource'];
  if (value == null) return input.resourceUri;

  final resource = _validHttpsUri(value);
  final expected = input.resourceUri;
  if (resource == null ||
      expected != null && !_sameResource(resource, expected)) {
    return null;
  }

  return resource;
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
  required Uri resourceUri,
}) {
  final endpoints = _headerChallengeEndpoints(response);
  if (endpoints == null) return null;
  final metadata = _headerChallengeMetadata(response, resourceUri);
  if (metadata == null) return null;

  return _createHeaderChallengeResult(endpoints, metadata, resourceUri);
}

OAuthDiscoveryResult _createHeaderChallengeResult(
  _HeaderChallengeEndpoints endpoints,
  _HeaderChallengeMetadata metadata,
  Uri resourceUri,
) =>
    OAuthDiscoveryResult._fromHeaderChallenge(endpoints, metadata, resourceUri);

typedef _HeaderChallengeEndpoints = ({Uri authorization, Uri token});

typedef _HeaderChallengeMetadata = ({
  String? clientId,
  String? scope,
  Uri? resource,
  Uri? issuer,
  Uri? deviceAuthorizationUrl,
  List<String> scopes,
});

_HeaderChallengeEndpoints? _headerChallengeEndpoints(http.Response response) {
  final authorization = _validHttpsUri(
    response.headers['x-oauth-authorization-url'],
  );
  final token = _validHttpsUri(response.headers['x-oauth-token-url']);
  if (authorization == null || token == null) return null;

  return (authorization: authorization, token: token);
}

_HeaderChallengeMetadata? _headerChallengeMetadata(
  http.Response response,
  Uri resourceUri,
) {
  final headers = response.headers;
  final resource = _headerResource(headers, resourceUri);
  if (resource == _invalidUri) return null;
  final issuer = _headerIssuer(headers);
  if (headers['x-oauth-issuer'] != null && issuer == null) {
    return null;
  }

  return _createHeaderChallengeMetadata(headers, resource, issuer);
}

_HeaderChallengeMetadata _createHeaderChallengeMetadata(
  Map<String, String> headers,
  Uri? resource,
  Uri? issuer,
) {
  final scope = headers['x-oauth-scope'];

  return (
    clientId: headers['x-oauth-client-id'],
    scope: scope,
    resource: resource,
    issuer: issuer,
    deviceAuthorizationUrl: _validHttpsUri(headers['x-oauth-device-url']),
    scopes: _scopes(const [], scope),
  );
}

final Uri _invalidUri = .parse('about:blank');

Uri? _headerResource(Map<String, String> headers, Uri expected) {
  final value = headers['x-oauth-resource'];
  if (value == null) return null;
  final resource = _validHttpsUri(value);
  if (resource == null || !_sameResource(resource, expected)) {
    return _invalidUri;
  }

  return resource;
}

Uri? _headerIssuer(Map<String, String> headers) =>
    _validHttpsUri(headers['x-oauth-issuer']);

Future<http.Response> _requestOAuthMetadata(String url) => http
    .get(.parse(url), headers: _jsonAcceptHeader)
    .timeout(const Duration(seconds: 5));

Future<OAuthDiscoveryResult?> _metadataResponse(
  http.Response response, {
  required _DiscoveryContext context,
}) async {
  if (response.statusCode != HttpStatus.ok) return null;

  final metadata = _decodeJsonObject(response);
  if (metadata == null) return null;

  return await _parseMetadataMap((metadata: metadata, context: context));
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

  final contentType = response.headers[_contentTypeHeaderName];
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
