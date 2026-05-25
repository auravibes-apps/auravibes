import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

class McpManagerClient {
  McpManagerClient._(
    this._client, {
    this._tokenManager,
  });
  final mcp.Client _client;
  final mcp.OAuthTokenManager? _tokenManager;

  Stream<OAuthTokenEntity>? get onTokenUpdate =>
      _tokenManager?.onTokenUpdate.map(
        (mcpToken) => OAuthTokenEntity(
          accessToken: mcpToken.accessToken,
          issuedAt: mcpToken.issuedAt,
          refreshToken: mcpToken.refreshToken,
          expiresIn: mcpToken.expiresIn,
          tokenType: mcpToken.tokenType,
          scopes: mcpToken.scopes,
        ),
      );
}

class McpManagerService {
  Future<void> disconnect(McpManagerClient? client) async {
    if (client == null) return;
    client._client.disconnect();
  }

  Future<String> callToolString(
    McpManagerClient client, {
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) async {
    final result = await client._client.callTool(toolIdentifier, arguments);

    // Convert the result content to a string
    // The result.content is a list of content items (TextContent, etc.)
    final contentStrings = result.content.map((content) {
      if (content is mcp.TextContent) {
        return content.text;
      }
      return content.toString();
    }).toList();

    return contentStrings.join('\n');
  }

  Future<McpManagerClient> connectMcp(
    McpServerToCreate serverInfo,
  ) async {
    // Create client configuration
    final config = mcp.McpClient.simpleConfig(
      name: 'AuraVibes MCP Client',
      version: '1.0.0',
    );

    // Create and connect client
    final clientResult = mcp.McpClient.createClient(
      config,
    );

    // clientResult.connect(transport)

    // Create transport configuration based on server settings
    final clientTransport = await _createTransportConfig(serverInfo);
    await clientResult.connect(clientTransport);

    final tokenManager = _tokenManager(serverInfo);

    return McpManagerClient._(clientResult, tokenManager: tokenManager);
  }

  Future<List<McpToolInfo>> getTools(
    McpManagerClient client,
  ) async {
    // List available tools from the MCP server
    final tools = await client._client.listTools();
    return _convertTools(tools);
  }

  /// Create transport configuration based on server settings.
  Future<mcp.ClientTransport> _createTransportConfig(McpServerToCreate server) {
    switch (server.transport) {
      case McpTransportTypeSSE():
        return _createSseTransportConfig(server);
      case McpTransportTypeStreamableHttp():
        return _createHttpTransportConfig(server);
    }
  }

  Future<mcp.ClientTransport> _createSseTransportConfig(
    McpServerToCreate server,
  ) async {
    final authType = server.authenticationType;

    if (authType is McpAuthenticationTypeNone) {
      return mcp.SseClientTransport.create(
        serverUrl: server.url,
      );
    }
    String? bearerToken;
    if (authType is McpAuthenticationTypeBearerToken) {
      bearerToken = authType.bearerToken;
    }

    final oAuthConfig = _getOauthConfig(authType);
    return mcp.SseAuthClientTransport.create(
      serverUrl: server.url,
      oauthToken: _getOauthToken(authType),
      oauthClient: oAuthConfig != null
          ? mcp.HttpOAuthClient(
              config: oAuthConfig,
            )
          : null,
      bearerToken: bearerToken,
    );
  }

  Future<mcp.ClientTransport> _createHttpTransportConfig(
    McpServerToCreate server,
  ) async {
    final headers = <String, String>{};
    final authType = server.authenticationType;
    final transportType = server.transport;

    if (transportType is! McpTransportTypeStreamableHttp) {
      throw Exception('Invalid transport type for HTTP transport');
    }

    if (authType is McpAuthenticationTypeBearerToken) {
      if (authType.bearerToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${authType.bearerToken}';
      } else {
        throw Exception(
          'Bearer token is required'
          ' for bearer token authentication.',
        );
      }
    }

    final oauthConfig = _getOauthConfig(authType);

    final transport = await mcp.StreamableHttpClientTransport.create(
      baseUrl: server.url,
      oauthConfig: oauthConfig,
      headers: headers,
      useHttp2: transportType.useHttp2,
    );
    final authToken = _getOauthToken(authType);

    if (authToken != null) {
      transport.setOAuthToken(authToken);
    }
    return transport;
  }

  mcp.OAuthConfig? _getOauthConfig(McpAuthenticationType authType) {
    if (authType is McpAuthenticationTypeOAuth) {
      return mcp.OAuthConfig(
        authorizationEndpoint: authType.authorizationEndpoint,
        tokenEndpoint: authType.tokenEndpoint,
        clientId: authType.clientId,
      );
    }
    return null;
  }

  mcp.OAuthToken? _getOauthToken(McpAuthenticationType authType) {
    if (authType is McpAuthenticationTypeOAuth) {
      return mcp.OAuthToken(
        accessToken: authType.token.accessToken,
        expiresIn: authType.token.expiresIn,
        refreshToken: authType.token.refreshToken,
        scopes: authType.token.scopes,
        issuedAt: authType.token.issuedAt,
      );
    }
    return null;
  }

  /// Convert MCP tools to our McpToolInfo format with prefixed names.
  List<McpToolInfo> _convertTools(
    List<mcp.Tool> tools,
  ) {
    return tools.map((tool) {
      return McpToolInfo(
        toolName: tool.name,
        description: tool.description,
        inputSchema: tool.inputSchema,
        supportsProgress: tool.supportsProgress,
        supportsCancellation: tool.supportsCancellation,
        metadata: tool.metadata,
      );
    }).toList();
  }

  mcp.OAuthTokenManager? _tokenManager(McpServerToCreate server) {
    final authType = server.authenticationType;
    final config = _getOauthConfig(authType);
    final token = _getOauthToken(authType);
    if (config == null || token == null) return null;

    final oauthClient = mcp.HttpOAuthClient(config: config);
    return mcp.OAuthTokenManager(oauthClient)..setToken(token);
  }
}
