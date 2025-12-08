import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

class McpManagerClient {
  McpManagerClient._(this._client);
  final mcp.Client _client;
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
    McpServerEntity serverInfo,
  ) async {
    // Create client configuration
    final config = mcp.McpClient.simpleConfig(
      name: 'AuraVibes MCP Client',
      version: '1.0.0',
    );

    // Create transport configuration based on server settings
    final transportConfig = _createTransportConfig(serverInfo);

    // Create and connect client
    final clientResult = await mcp.McpClient.createAndConnect(
      config: config,
      transportConfig: transportConfig,
    );

    final client = clientResult.fold(
      (c) => c,
      (error) => throw Exception('Failed to connect: $error'),
    );

    return McpManagerClient._(client);
  }

  Future<List<McpToolInfo>> getTools(
    McpManagerClient client,
    McpServerEntity serverInfo,
  ) async {
    // List available tools from the MCP server
    final tools = await client._client.listTools();
    return _convertTools(tools, serverInfo);
  }

  /// Create transport configuration based on server settings.
  mcp.TransportConfig _createTransportConfig(McpServerEntity server) {
    switch (server.transport) {
      case McpTransportType.sse:
        return _createSseTransportConfig(server);
      case McpTransportType.streamableHttp:
        return _createHttpTransportConfig(server);
    }
  }

  mcp.TransportConfig _createSseTransportConfig(McpServerEntity server) {
    switch (server.authenticationType) {
      case McpAuthenticationType.none:
        return mcp.TransportConfig.sse(serverUrl: server.url);

      case McpAuthenticationType.bearerToken:
        return mcp.TransportConfig.sse(
          serverUrl: server.url,
          bearerToken: server.bearerToken,
        );

      case McpAuthenticationType.oauth:
        return mcp.TransportConfig.sse(
          serverUrl: server.url,
          oauthConfig: mcp.OAuthConfig(
            authorizationEndpoint: server.authorizationEndpoint!,
            tokenEndpoint: server.tokenEndpoint!,
            clientId: server.clientId!,
          ),
        );
    }
  }

  mcp.TransportConfig _createHttpTransportConfig(McpServerEntity server) {
    switch (server.authenticationType) {
      case McpAuthenticationType.none:
        return mcp.TransportConfig.streamableHttp(
          baseUrl: server.url,
          useHttp2: server.useHttp2,
        );

      case McpAuthenticationType.bearerToken:
        // Streamable HTTP doesn't support bearer token, fall back to no auth
        return mcp.TransportConfig.streamableHttp(
          baseUrl: server.url,
          useHttp2: server.useHttp2,
        );

      case McpAuthenticationType.oauth:
        return mcp.TransportConfig.streamableHttp(
          baseUrl: server.url,
          useHttp2: server.useHttp2,
          oauthConfig: mcp.OAuthConfig(
            authorizationEndpoint: server.authorizationEndpoint!,
            tokenEndpoint: server.tokenEndpoint!,
            clientId: server.clientId!,
          ),
        );
    }
  }

  /// Convert MCP tools to our McpToolInfo format with prefixed names.
  List<McpToolInfo> _convertTools(
    List<mcp.Tool> tools,
    McpServerEntity server,
  ) {
    return tools.map((mcp.Tool tool) {
      return McpToolInfo(
        toolName: tool.name,
        serverName: server.name,
        description: tool.description,
        inputSchema: tool.inputSchema,
        mcpServerId: server.id,
        metadata: tool.metadata,
        supportsCancellation: tool.supportsCancellation,
        supportsProgress: tool.supportsProgress,
      );
    }).toList();
  }
}
