// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/services/mcp_service/mcp_sdk_adapter.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

class McpManagerClient._(
  final mcp.Client _client, {
  final mcp.OAuthTokenManager? _tokenManager,
}) {
  Stream<OAuthTokenEntity>? get onTokenUpdate =>
      _tokenManager?.onTokenUpdate.map(_oauthTokenEntity);

  void disconnect() => _client.disconnect();
}

class McpManagerService {
  new({this.oauthCredentialService});
  final OAuthCredentialService? oauthCredentialService;

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

  Future<McpManagerClient> connectMcp(McpServerToCreate serverInfo) async {
    // Create client configuration.
    final config = mcp.McpClient.simpleConfig(
      name: 'AuraVibes MCP Client',
      version: '1.0.0',
    );

    final clientResult = mcp.McpClient.createClient(config);
    await clientResult.connect(
      await _createTransportConfig(
        serverInfo,
        oauthCredentialService: oauthCredentialService,
      ),
    );

    return McpManagerClient._(
      clientResult,
      tokenManager: serverInfo.transport is McpTransportTypeSSE
          ? _tokenManager(serverInfo)
          : null,
    );
  }

  Future<List<McpToolInfo>> getTools(McpManagerClient client) async {
    // List available tools from the MCP server.
    final tools = await client._client.listTools();

    return _convertTools(tools);
  }
}

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
}) => switch (server.transport) {
  McpTransportTypeSSE() => _createSseTransportConfig(server),
  McpTransportTypeStreamableHttp() => _createHttpTransportConfig(
    server,
    oauthCredentialService: oauthCredentialService,
  ),
};

Future<mcp.ClientTransport> _createSseTransportConfig(
  McpServerToCreate server,
) {
  final authType = server.authenticationType;
  if (authType is McpAuthenticationTypeNone) {
    return mcp.SseClientTransport.create(serverUrl: server.url);
  }

  return mcp.SseAuthClientTransport.create(
    serverUrl: server.url,
    oauthToken: _getOauthToken(authType),
    oauthClient: _oauthClient(authType),
    bearerToken: _bearerToken(authType),
  );
}

Future<mcp.ClientTransport> _createHttpTransportConfig(
  McpServerToCreate server, {
  required OAuthCredentialService? oauthCredentialService,
}) async {
  final transportType = server.transport;
  if (transportType is! McpTransportTypeStreamableHttp) {
    throw Exception('Invalid transport type for HTTP transport');
  }

  final authType = server.authenticationType;
  final transport = await _createStreamableTransport(
    server,
    authType,
    transportType,
    oauthCredentialService: oauthCredentialService,
  );
  if (authType is! McpAuthenticationTypeOAuth) {
    _setOAuthToken(transport, authType);
  }

  return transport;
}

Future<mcp.StreamableHttpClientTransport> _createStreamableTransport(
  McpServerToCreate server,
  McpAuthenticationType authType,
  McpTransportTypeStreamableHttp transportType, {
  required OAuthCredentialService? oauthCredentialService,
}) => mcp.StreamableHttpClientTransport.create(
  baseUrl: server.url,
  oauthConfig: authType is McpAuthenticationTypeOAuth
      ? null
      : _getOauthConfig(authType),
  headers: authType is McpAuthenticationTypeOAuth
      ? const {}
      : _httpHeaders(authType),
  headersProvider: authType is McpAuthenticationTypeOAuth
      ? (_) => _oauthHeaders(server, authType, oauthCredentialService)
      : null,
  useHttp2: transportType.useHttp2,
);

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
      McpAuthenticationTypeNone() ||
      McpAuthenticationTypeOAuth() => <String, String>{},
    };

void _setOAuthToken(
  mcp.StreamableHttpClientTransport transport,
  McpAuthenticationType authType,
) {
  final authToken = _getOauthToken(authType);
  if (authToken == null) return;
  transport.setOAuthToken(authToken);
}

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
      McpAuthenticationTypeNone() || McpAuthenticationTypeBearerToken() => null,
    };

mcp.OAuthToken? _getOauthToken(McpAuthenticationType authType) =>
    switch (authType) {
      McpAuthenticationTypeOAuth(:final token) => _mcpOAuthToken(token),
      McpAuthenticationTypeNone() || McpAuthenticationTypeBearerToken() => null,
    };

mcp.OAuthToken _mcpOAuthToken(OAuthTokenEntity token) => .new(
  accessToken: token.accessToken,
  expiresIn: token.expiresIn,
  refreshToken: token.refreshToken,
  scopes: token.scopes,
  issuedAt: token.issuedAt,
);

List<McpToolInfo> _convertTools(List<mcp.Tool> tools) =>
    tools.map(_convertTool).toList();

McpToolInfo _convertTool(mcp.Tool tool) => .new(
  toolName: tool.name,
  description: tool.description,
  inputSchema: tool.inputSchema,
  supportsProgress: tool.supportsProgress,
  supportsCancellation: tool.supportsCancellation,
  metadata: tool.metadata,
);

mcp.OAuthTokenManager? _tokenManager(McpServerToCreate server) {
  final authType = server.authenticationType;
  final config = _getOauthConfig(authType);
  final token = _getOauthToken(authType);
  if (config == null || token == null) return null;

  return mcp.OAuthTokenManager(.new(config: config))..setToken(token);
}
