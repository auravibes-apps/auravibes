// Required: Existing test and UI helpers keep compact return flow.
import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/services/mcp_service/mcp_legacy_sse_unavailable_exception.dart';
import 'package:auravibes_app/services/mcp_service/mcp_sdk_adapter.dart';
import 'package:auravibes_app/services/mcp_service/mcp_streamable_http_response_capture.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mcp_client/mcp_client.dart' as mcp;

typedef McpConnectionRequest = ({
  String name,
  String url,
  bool useHttp2,
  McpAuthenticationType authenticationType,
  String? serviceConnectionId,
  String? description,
});

typedef _StreamableHttpAuthConfig = ({
  Map<String, String> headers,
  mcp.RequestHeadersProvider? headersProvider,
});

const int _maxMcpAppResultBytes = maxPersistedToolOutputBytes - 1024;

Map<String, Object?> _boundedMcpAppResult(
  Map<String, Object?> result,
  String modelText,
) {
  if (_isWithinMcpAppResultLimit(result)) return result;
  final fallback = _mcpAppTextResult(modelText);
  final metadata = result['_meta'];
  if (metadata == null) return fallback;

  final withMetadata = <String, Object?>{'_meta': metadata, ...fallback};

  return _isWithinMcpAppResultLimit(withMetadata) ? withMetadata : fallback;
}

bool _isWithinMcpAppResultLimit(Map<String, Object?> result) =>
    utf8.encode(jsonEncode(result)).length <= _maxMcpAppResultBytes;

Map<String, Object?> _mcpAppTextResult(String modelText) => {
  'content': [
    {'type': 'text', 'text': projectToolOutput(modelText).text},
  ],
};

class McpManagerClient._(
  final mcp.Client _client,
  final mcp.ClientTransport _transport,
  final McpTransportType _resolvedTransport,
  final mcp.OAuthTokenManager? _tokenManager,
) {
  var _requestId = 0;

  Stream<OAuthTokenEntity>? get onTokenUpdate =>
      _tokenManager?.onTokenUpdate.map(_oauthTokenEntity);

  bool get isConnected => _client.isConnected;

  McpTransportType get resolvedTransport => _resolvedTransport;

  void onToolsListChanged(void Function() handler) {
    if (_client.serverCapabilities?.toolsListChanged == true) {
      _client.onToolsListChanged(handler);
    }
  }

  void disconnect() => _client.disconnect();

  static Future<Map<String, Object?>> requestToolsPage({
    required mcp.ClientTransport transport,
    required int requestId,
    String? cursor,
  }) =>
      _requestToolsPageFromTransport(transport, (1 << 52) + requestId, cursor);

  Future<Map<String, Object?>> _requestToolsPage(String? cursor) =>
      requestToolsPage(
        transport: _transport,
        requestId: ++_requestId,
        cursor: cursor,
      );
}

StreamSubscription<Object?> _listenForToolsResponse(
  mcp.ClientTransport transport,
  int id,
  Completer<Map<String, Object?>> response,
) => transport.onMessage.listen(
  (message) => _completeToolsResponse(message, id, response),
  onError: (Object error, StackTrace stackTrace) =>
      _completeToolResponseError(response, error, stackTrace),
);

void _sendToolsListRequest(
  mcp.ClientTransport transport,
  int id,
  String? cursor,
) => transport.send({
  'jsonrpc': '2.0',
  'id': id,
  'method': 'tools/list',
  'params': {'cursor': ?cursor},
});

void _completeToolsResponse(
  Object? message,
  int id,
  Completer<Map<String, Object?>> response,
) {
  if (response.isCompleted) return;
  try {
    final result = _readToolsResponse(message, id);
    if (result != null) response.complete(result);
  } on Object catch (error, stackTrace) {
    _completeToolResponseError(response, error, stackTrace);
  }
}

Map<String, Object?>? _readToolsResponse(Object? message, int id) {
  final Object? decoded = message is String ? jsonDecode(message) : message;
  if (decoded is! Map || decoded['id'] != id) return null;
  if (decoded['error'] != null || decoded['result'] is! Map) {
    throw const FormatException('Invalid MCP tools response.');
  }

  return Map<String, Object?>.from(decoded['result'] as Map);
}

void _completeToolResponseError(
  Completer<Map<String, Object?>> response,
  Object error,
  StackTrace stackTrace,
) {
  if (!response.isCompleted) response.completeError(error, stackTrace);
}

Future<Map<String, Object?>> _connectionClosedResponse(
  mcp.ClientTransport transport,
) async {
  await transport.onClose;
  throw const FormatException('MCP connection closed.');
}

Future<Map<String, Object?>> _awaitToolsResponse(
  mcp.ClientTransport transport,
  Future<Map<String, Object?>> response,
) async =>
    await Future.any([response, _connectionClosedResponse(transport)])
        .timeout(const Duration(seconds: 10));

Future<Map<String, Object?>> _requestToolsPageFromTransport(
  mcp.ClientTransport transport,
  int id,
  String? cursor,
) async {
  final response = Completer<Map<String, Object?>>();
  final subscription = _listenForToolsResponse(transport, id, response);
  try {
    _sendToolsListRequest(transport, id, cursor);

    return await _awaitToolsResponse(transport, response.future);
  } finally {
    await subscription.cancel();
  }
}

class McpManagerService {
  new({
    this.oauthCredentialService,
    @visibleForTesting bool? legacySseSupported,
    @visibleForTesting this.legacySseTransportFactory,
  }) : _legacySseSupported = legacySseSupported ?? !kIsWeb;

  final OAuthCredentialService? oauthCredentialService;
  @visibleForTesting
  final Future<mcp.ClientTransport> Function(McpServerToCreate)?
  legacySseTransportFactory;
  final bool _legacySseSupported;

  Future<void> disconnect(McpManagerClient? client) async {
    if (client == null) return;
    client.disconnect();
  }

  Future<String> callToolString(
    McpManagerClient client, {
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) async {
    final result = await client._client.callTool(toolIdentifier, arguments);

    return McpSdkAdapter.toolResult(result).toModelText();
  }

  Future<({String modelText, Map<String, Object?> appData})> callToolOutput(
    McpManagerClient client, {
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) async {
    final result = await client._client.callTool(toolIdentifier, arguments);
    final modelText = McpSdkAdapter.toolResult(result).toModelText();

    return (
      modelText: modelText,
      appData: _boundedMcpAppResult(result.toJson(), modelText),
    );
  }

  Future<Map<String, Object?>> callToolResult(
    McpManagerClient client, {
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) async {
    final result = await client._client.callTool(toolIdentifier, arguments);
    final modelText = McpSdkAdapter.toolResult(result).toModelText();

    return _boundedMcpAppResult(result.toJson(), modelText);
  }

  Future<Map<String, Object?>> readResource(
    McpManagerClient client,
    String uri,
  ) async => (await client._client.readResource(uri)).toJson();

  Future<McpManagerClient> connectMcp(McpServerToCreate serverInfo) async {
    return await _connectMcp((
      serverInfo: serverInfo,
      oauthCredentialService: oauthCredentialService,
      httpClient: null,
      clientTransport: null,
    ));
  }

  Future<McpManagerClient> connectMcpWithAutoTransport(
    McpConnectionRequest request,
  ) async {
    final httpServerInfo = _streamableHttpServerInfo(request);
    final responseCapture = McpStreamableHttpResponseCapture();

    try {
      return await _connectMcp((
        serverInfo: httpServerInfo,
        oauthCredentialService: oauthCredentialService,
        httpClient: responseCapture,
        clientTransport: null,
      ));
    } on Object {
      final shouldFallback = responseCapture.shouldFallbackToLegacySse;
      responseCapture.close();
      if (!shouldFallback) rethrow;

      return await _connectLegacySse(_legacySseConnectRequest(this, request));
    }
  }

  Future<List<McpToolInfo>> getTools(McpManagerClient client) async {
    final tools = await collectMcpToolsCatalog(client._requestToolsPage)
        .timeout(const Duration(seconds: 30));

    return tools.map(_convertTool).toList(growable: false);
  }
}

typedef _McpConnectRequest = ({
  McpServerToCreate serverInfo,
  OAuthCredentialService? oauthCredentialService,
  http.Client? httpClient,
  mcp.ClientTransport? clientTransport,
});

typedef _LegacySseConnectRequest = ({
  McpConnectionRequest request,
  bool supported,
  Future<mcp.ClientTransport> Function(McpServerToCreate)? transportFactory,
  OAuthCredentialService? oauthCredentialService,
});

_LegacySseConnectRequest _legacySseConnectRequest(
  McpManagerService service,
  McpConnectionRequest request,
) => (
  request: request,
  supported: service._legacySseSupported,
  transportFactory: service.legacySseTransportFactory,
  oauthCredentialService: service.oauthCredentialService,
);

McpServerToCreate _streamableHttpServerInfo(McpConnectionRequest request) =>
    _serverForTransport(
      request,
      McpTransportTypeStreamableHttp(useHttp2: request.useHttp2),
    );

Future<McpManagerClient> _connectMcp(_McpConnectRequest request) async {
  final client = _createMcpClient();
  final transport = await _connectClient(client, request);
  final serverInfo = request.serverInfo;

  return McpManagerClient._(
    client,
    transport,
    serverInfo.transport,
    serverInfo.transport is McpTransportTypeSSE
        ? _tokenManager(serverInfo)
        : null,
  );
}

// Create client configuration.
mcp.Client _createMcpClient() => mcp.McpClient.createClient(
  mcp.McpClient.simpleConfig(
    name: 'AuraVibes MCP Client',
    version: '1.0.0',
  ).copyWith(
    capabilities: const .new(
      extensions: {
        'io.modelcontextprotocol/ui': {
          'mimeTypes': ['text/html;profile=mcp-app'],
        },
      },
    ),
  ),
);

Future<mcp.ClientTransport> _connectClient(
  mcp.Client client,
  _McpConnectRequest request,
) async {
  try {
    final transport =
        request.clientTransport ??
        await _createTransportConfig(
          request.serverInfo,
          oauthCredentialService: request.oauthCredentialService,
          httpClient: request.httpClient,
        );
    await client.connect(transport);

    return transport;
  } on Object {
    client.disconnect();
    rethrow;
  }
}

Future<McpManagerClient> _connectLegacySse(
  _LegacySseConnectRequest request,
) async {
  if (!request.supported) throw const McpLegacySseUnavailableException();
  final serverInfo = _serverForTransport(
    request.request,
    const McpTransportTypeSSE(),
  );
  final factory = request.transportFactory;
  final clientTransport = factory == null ? null : await factory(serverInfo);

  return await _connectMcp((
    serverInfo: serverInfo,
    oauthCredentialService: request.oauthCredentialService,
    httpClient: null,
    clientTransport: clientTransport,
  ));
}

McpServerToCreate _serverForTransport(
  McpConnectionRequest request,
  McpTransportType transport,
) => McpServerToCreate(
  name: request.name,
  url: request.url,
  transport: transport,
  authenticationType: request.authenticationType,
  serviceConnectionId: request.serviceConnectionId,
  description: request.description,
);

OAuthTokenEntity _oauthTokenEntity(mcp.OAuthToken mcpToken) => .new(
  accessToken: mcpToken.accessToken,
  issuedAt: mcpToken.issuedAt,
  refreshToken: mcpToken.refreshToken,
  expiresIn: mcpToken.expiresIn,
  tokenType: mcpToken.tokenType,
  scopes: mcpToken.scopes,
);

Future<mcp.ClientTransport> _createTransportConfig(
  McpServerToCreate server, {
  required OAuthCredentialService? oauthCredentialService,
  http.Client? httpClient,
}) => switch (server.transport) {
  McpTransportTypeSSE() => _createSseTransportConfig(server),
  McpTransportTypeStreamableHttp() => _createHttpTransportConfig(
    server,
    oauthCredentialService: oauthCredentialService,
    httpClient: httpClient,
  ),
};

Future<mcp.ClientTransport> _createSseTransportConfig(
  McpServerToCreate server,
) {
  final authType = server.authenticationType;
  if (authType is! McpAuthenticationTypeOAuth) {
    return mcp.SseClientTransport.create(
      serverUrl: server.url,
      headers: _httpHeaders(authType),
    );
  }

  // ignore: deprecated_member_use - Retain legacy SSE OAuth refresh hooks; v3 SseClientTransport only supports static headers.
  return mcp.SseAuthClientTransport.create(
    serverUrl: server.url,
    headers: _httpHeaders(authType),
    oauthToken: _getOauthToken(authType),
    oauthClient: _oauthClient(authType),
    bearerToken: _bearerToken(authType),
  );
}

Future<mcp.ClientTransport> _createHttpTransportConfig(
  McpServerToCreate server, {
  required OAuthCredentialService? oauthCredentialService,
  http.Client? httpClient,
}) async {
  final transportType = server.transport;
  if (transportType is! McpTransportTypeStreamableHttp) {
    throw Exception('Invalid transport type for HTTP transport');
  }

  return await _createStreamableTransport(
    server,
    transportType,
    oauthCredentialService: oauthCredentialService,
    httpClient: httpClient,
  );
}

Future<mcp.StreamableHttpClientTransport> _createStreamableTransport(
  McpServerToCreate server,
  McpTransportTypeStreamableHttp transportType, {
  required OAuthCredentialService? oauthCredentialService,
  http.Client? httpClient,
}) {
  final authConfig = _streamableHttpAuthConfig(server, oauthCredentialService);

  return mcp.StreamableHttpClientTransport.create(
    baseUrl: server.url,
    headers: authConfig.headers,
    headersProvider: authConfig.headersProvider,
    useHttp2: transportType.useHttp2,
    httpClient: httpClient,
  );
}

_StreamableHttpAuthConfig _streamableHttpAuthConfig(
  McpServerToCreate server,
  OAuthCredentialService? oauthCredentialService,
) {
  final authType = server.authenticationType;
  if (authType is McpAuthenticationTypeOAuth) {
    return (
      headers: const {},
      headersProvider: (_) =>
          _oauthHeaders(server, authType, oauthCredentialService),
    );
  }

  return (headers: _httpHeaders(authType), headersProvider: null);
}

Future<Map<String, String>> _oauthHeaders(
  McpServerToCreate server,
  McpAuthenticationTypeOAuth authType,
  OAuthCredentialService? oauthCredentialService,
) async {
  final serviceConnectionId = server.serviceConnectionId;
  final token =
      oauthCredentialService == null ||
          serviceConnectionId == null ||
          serviceConnectionId.isEmpty
      ? authType.token.accessToken
      : await oauthCredentialService.getValidAccessToken(serviceConnectionId);
  if (token.isEmpty) {
    throw const FormatException('OAuth access token is empty.');
  }

  return {'Authorization': 'Bearer $token'};
}

Map<String, String> _httpHeaders(McpAuthenticationType authType) =>
    switch (authType) {
      McpAuthenticationTypeBearerToken(:final bearerToken)
          when bearerToken.isNotEmpty =>
        {'Authorization': 'Bearer $bearerToken'},
      McpAuthenticationTypeBearerToken() => throw Exception(
        'Bearer token is required'
        ' for bearer token authentication.',
      ),
      McpAuthenticationTypeHttpHeaders(:final headers) => headers,
      McpAuthenticationTypeNone() ||
      McpAuthenticationTypeOAuth() => <String, String>{},
    };

mcp.HttpOAuthClient? _oauthClient(McpAuthenticationType authType) {
  final config = _getOauthConfig(authType);

  return config == null ? null : mcp.HttpOAuthClient(config: config);
}

String? _bearerToken(McpAuthenticationType authType) =>
    authType is McpAuthenticationTypeBearerToken ? authType.bearerToken : null;

mcp.OAuthConfig? _getOauthConfig(McpAuthenticationType authType) =>
    switch (authType) {
      McpAuthenticationTypeOAuth(
        :final authorizationEndpoint,
        :final tokenEndpoint,
        :final clientId,
      ) =>
        .new(
          authorizationEndpoint: authorizationEndpoint,
          tokenEndpoint: tokenEndpoint,
          clientId: clientId,
        ),
      McpAuthenticationTypeNone() ||
      McpAuthenticationTypeBearerToken() ||
      McpAuthenticationTypeHttpHeaders() => null,
    };

mcp.OAuthToken? _getOauthToken(McpAuthenticationType authType) =>
    switch (authType) {
      McpAuthenticationTypeOAuth(:final token) => _mcpOAuthToken(token),
      McpAuthenticationTypeNone() ||
      McpAuthenticationTypeBearerToken() ||
      McpAuthenticationTypeHttpHeaders() => null,
    };

mcp.OAuthToken _mcpOAuthToken(OAuthTokenEntity token) => .new(
  accessToken: token.accessToken,
  expiresIn: token.expiresIn,
  refreshToken: token.refreshToken,
  scopes: token.scopes,
  issuedAt: token.issuedAt,
);

McpToolInfo _convertTool(Map<String, Object?> tool) => .new(
  toolName: _requiredToolName(tool['name']),
  description: _optionalString(tool['description']) ?? '',
  inputSchema: _jsonMapOrEmpty(tool['inputSchema']),
  outputSchema: _jsonMap(tool['outputSchema']),
  supportsProgress: tool['supportsProgress'] as bool?,
  supportsCancellation: tool['supportsCancellation'] as bool?,
  metadata: _jsonMap(tool['_meta'] ?? tool['metadata']),
);

String _requiredToolName(Object? value) => switch (value) {
  final String name => name,
  _ => throw const FormatException('Invalid MCP tool name.'),
};

String? _optionalString(Object? value) => switch (value) {
  final String string => string,
  _ => null,
};

Map<String, dynamic> _jsonMapOrEmpty(Object? value) =>
    _jsonMap(value) ?? const <String, dynamic>{};

Map<String, dynamic>? _jsonMap(Object? value) => switch (value) {
  final Map<Object?, Object?> map => Map<String, dynamic>.from(map),
  _ => null,
};

mcp.OAuthTokenManager? _tokenManager(McpServerToCreate server) {
  final authType = server.authenticationType;
  final config = _getOauthConfig(authType);
  final token = _getOauthToken(authType);
  if (config == null || token == null) return null;

  return mcp.OAuthTokenManager(.new(config: config))..setToken(token);
}
