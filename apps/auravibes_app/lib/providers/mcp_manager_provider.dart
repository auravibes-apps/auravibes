import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/selected_workspace.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:langchain/langchain.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_manager_provider.freezed.dart';
part 'mcp_manager_provider.g.dart';

// ============================================================
// MCP Connection Status
// ============================================================

/// Status of an MCP server connection
enum McpConnectionStatus {
  /// Not connected to the server
  disconnected,

  /// Currently attempting to connect
  connecting,

  /// Successfully connected and ready
  connected,

  /// Connection failed with an error
  error,
}

// ============================================================
// MCP Tool Info
// ============================================================

/// Information about a tool provided by an MCP server
@freezed
abstract class McpToolInfo with _$McpToolInfo {
  const factory McpToolInfo({
    /// Original tool name from the MCP server
    required String originalName,

    /// Prefixed name for avoiding conflicts: "mcp_${slug}_${originalName}"
    required String prefixedName,

    /// Tool description from the MCP server
    required String description,

    /// JSON Schema for the tool's input parameters
    required Map<String, dynamic> inputSchema,

    /// ID of the MCP server that provides this tool
    required String mcpServerId,
  }) = _McpToolInfo;

  const McpToolInfo._();
}

// ============================================================
// MCP Connection State
// ============================================================

/// State for a single MCP server connection
@freezed
abstract class McpConnectionState with _$McpConnectionState {
  const factory McpConnectionState({
    /// The MCP server configuration
    required McpServerEntity server,

    /// Current connection status
    required McpConnectionStatus status,

    /// The connected MCP client instance (null if not connected)
    mcp.Client? client,

    /// Tools available from this MCP server
    @Default([]) List<McpToolInfo> tools,

    /// Error message if connection failed
    String? errorMessage,
  }) = _McpConnectionState;

  const McpConnectionState._();

  /// Whether this connection is ready to use
  bool get isReady => status == McpConnectionStatus.connected && client != null;

  /// Whether this connection has tools available
  bool get hasTools => tools.isNotEmpty;
}

// ============================================================
// MCP Tool ID Components
// ============================================================

/// Parsed components of a composite MCP tool ID.
///
/// The composite ID format is: `mcp::<mcp_id>::<slug_name>::<tool_identifier>`
class McpToolIdComponents {
  const McpToolIdComponents({
    required this.mcpServerId,
    required this.slugName,
    required this.toolIdentifier,
  });

  /// The database ID of the MCP server
  final String mcpServerId;

  /// The slugified server name (for readability)
  final String slugName;

  /// The original tool name from the MCP server
  final String toolIdentifier;
}

// ============================================================
// MCP Manager Notifier
// ============================================================

/// Manages MCP server connections and their tools.
///
/// This notifier handles:
/// - Adding new MCP servers (saves to database and connects)
/// - Loading MCPs from database on startup
/// - Maintaining active connections to MCP servers
/// - Tracking tools from each MCP server with prefixed names
/// - Deleting MCP servers
/// - Executing MCP tools
///
/// Tools are stored with a composite ID format:
/// `mcp::<mcpId>::<slugName>::<toolName>`
/// - mcpId: Database ID for uniqueness
/// - slugName: URL-safe server name for LLM readability
/// - toolName: Original tool identifier from the MCP server
@Riverpod(keepAlive: true)
class McpManagerNotifier extends _$McpManagerNotifier {
  @override
  List<McpConnectionState> build() {
    ref.onDispose(_disposeAllConnections);

    // Load MCPs from database on initialization
    _loadMcpsFromDatabase();

    return [];
  }

  // ============================================================
  // Public API
  // ============================================================

  /// Add a new MCP server from the form data.
  ///
  /// This will:
  /// 1. Save the server to the database
  /// 2. Connect to the MCP server
  /// 3. Persist tools to database if connection successful
  Future<void> addMcpServer(McpServerToCreate serverToCreate) async {
    // Get the current workspace ID
    final workspace = await ref.read(selectedWorkspaceProvider.future);
    final workspaceId = workspace.id;

    // Save to database using the repository
    final repository = ref.read(mcpServersRepositoryProvider);
    final savedServer = await repository.addMcpServerWithTools(
      workspaceId: workspaceId,
      serverToCreate: serverToCreate,
      tools: [], // Initially empty, will be updated after connection
    );

    // Add to state and connect
    await _connectToMcp(savedServer);
  }

  /// Delete an MCP server by ID.
  ///
  /// This will:
  /// 1. Disconnect the client if connected
  /// 2. Remove from state
  /// 3. Delete from database (cascades to tools group and tools)
  Future<void> deleteMcpServer(String serverId) async {
    // Find and disconnect the client
    final connection = state.firstWhereOrNull((c) => c.server.id == serverId);
    if (connection != null) {
      connection.client?.disconnect();
    }

    // Remove from state
    state = state
        .where((McpConnectionState c) => c.server.id != serverId)
        .toList();

    // Delete from database (cascades to tools group and tools)
    final repository = ref.read(mcpServersRepositoryProvider);
    await repository.deleteMcpServer(serverId);
  }

  /// Reconnect to a specific MCP server.
  Future<void> reconnectMcpServer(String serverId) async {
    final connection = state
        .where((McpConnectionState c) => c.server.id == serverId)
        .firstOrNull;
    if (connection == null) return;

    // Disconnect if currently connected
    connection.client?.disconnect();

    // Reconnect
    await _connectToMcp(connection.server);
  }

  /// Disconnect from a specific MCP server without deleting.
  void disconnectMcpServer(String serverId) {
    final index = state.indexWhere(
      (McpConnectionState c) => c.server.id == serverId,
    );
    if (index == -1) return;

    final connection = state[index];
    connection.client?.disconnect();

    state = [
      ...state.sublist(0, index),
      connection.copyWith(
        status: McpConnectionStatus.disconnected,
        client: null,
      ),
      ...state.sublist(index + 1),
    ];
  }

  /// Get all available MCP tools (flattened from all connected servers).
  List<McpToolInfo> getAllMcpTools() {
    return state
        .where(
          (McpConnectionState c) => c.status == McpConnectionStatus.connected,
        )
        .expand((McpConnectionState c) => c.tools)
        .toList();
  }

  /// Get ToolSpec list for use with the chatbot service.
  ///
  /// Converts MCP tools to LangChain ToolSpec format.
  List<ToolSpec> getMcpToolSpecs() {
    return getAllMcpTools().map(_toToolSpec).toList();
  }

  /// Refresh MCP servers from database.
  ///
  /// Loads any new MCP servers that aren't already connected.
  Future<void> refreshMcpServers() async {
    await _loadMissingMcps();
  }

  /// Get a connection state by server ID.
  McpConnectionState? getConnection(String serverId) {
    return state
        .where((McpConnectionState c) => c.server.id == serverId)
        .firstOrNull;
  }

  /// Get a ToolSpec for a specific MCP tool by server ID and tool name.
  ///
  /// Returns null if the server is not connected or the tool is not found.
  ToolSpec? getToolSpec({
    required String mcpServerId,
    required String toolName,
  }) {
    final connection = getConnection(mcpServerId);
    if (connection == null || !connection.isReady) {
      return null;
    }

    final toolInfo = connection.tools.firstWhereOrNull(
      (t) => t.originalName == toolName,
    );
    if (toolInfo == null) {
      return null;
    }

    return _toToolSpec(toolInfo);
  }

  /// Check if any MCP servers are currently connecting.
  bool get isConnecting => state.any(
    (McpConnectionState c) => c.status == McpConnectionStatus.connecting,
  );

  /// Get count of connected MCP servers.
  int get connectedCount => state
      .where(
        (McpConnectionState c) => c.status == McpConnectionStatus.connected,
      )
      .length;

  /// Get the timeout duration for waiting for MCP connections.
  ///
  /// This is exposed as a method to allow future configuration via settings.
  /// Currently returns a default of 10 seconds.
  Duration getMcpConnectionTimeout() {
    // TODO: In the future, this can be fetched from user settings/config
    return const Duration(seconds: 10);
  }

  /// Returns a Future that completes when the specified MCP servers have
  /// finished their connection attempts (status is connected, error,
  /// or disconnected - not connecting).
  ///
  /// [mcpServerIds] - List of MCP server IDs to wait for.
  ///   If empty, returns immediately.
  /// [timeout] - Maximum time to wait. If null, uses [getMcpConnectionTimeout].
  ///
  /// Returns normally after all connections resolve OR timeout is reached.
  Future<void> waitForConnectionsReady({
    required List<String> mcpServerIds,
    Duration? timeout,
  }) async {
    if (mcpServerIds.isEmpty) return;

    final effectiveTimeout = timeout ?? getMcpConnectionTimeout();
    if (effectiveTimeout.inSeconds <= 0) return; // Disabled

    bool isStillConnecting() {
      return state
          .where((c) => mcpServerIds.contains(c.server.id))
          .any((c) => c.status == McpConnectionStatus.connecting);
    }

    // If nothing is connecting, return immediately
    if (!isStillConnecting()) return;

    // Poll for state changes with a small interval until resolved or timeout
    final stopwatch = Stopwatch()..start();
    const pollInterval = Duration(milliseconds: 100);

    while (isStillConnecting() && stopwatch.elapsed < effectiveTimeout) {
      await Future<void>.delayed(pollInterval);
    }

    stopwatch.stop();
  }

  /// Get the list of MCP server IDs that are currently connecting.
  List<String> getConnectingServerIds() {
    return state
        .where((c) => c.status == McpConnectionStatus.connecting)
        .map((c) => c.server.id)
        .toList();
  }

  /// Get the list of MCP connection states that are currently connecting
  /// from the specified server IDs.
  List<McpConnectionState> getConnectingServers(List<String> mcpServerIds) {
    return state
        .where((c) => mcpServerIds.contains(c.server.id))
        .where((c) => c.status == McpConnectionStatus.connecting)
        .toList();
  }

  /// Call an MCP tool by its composite ID.
  ///
  /// The composite ID format is:
  /// `mcp::<mcp_id>::<slug_name>::<tool_identifier>`
  /// This method parses the composite ID, finds the MCP server connection,
  /// and executes the tool with the given arguments.
  ///
  /// Returns the tool result as a string.
  /// Throws an exception if the MCP server is not connected or tool not found.
  Future<String> callTool({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) async {
    final connection = getConnection(mcpServerId);
    if (connection == null) {
      throw Exception('MCP server not found: $mcpServerId');
    }

    if (!connection.isReady) {
      throw Exception('MCP server not connected: $mcpServerId');
    }

    // Verify the tool exists on this server
    final toolExists = connection.tools.any(
      (McpToolInfo t) => t.originalName == toolIdentifier,
    );
    if (!toolExists) {
      throw Exception(
        'Tool "$toolIdentifier" not found on MCP server: $mcpServerId',
      );
    }

    // Call the tool via the MCP client
    final result = await connection.client!.callTool(
      toolIdentifier,
      arguments,
    );

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

  /// Parse a composite MCP tool ID and extract its components.
  ///
  /// Format: `mcp::<mcp_id>::<slug_name>::<tool_identifier>`
  /// Returns null if the format is invalid or not an MCP tool.
  static McpToolIdComponents? parseCompositeToolId(String compositeId) {
    if (!compositeId.startsWith('mcp::')) {
      return null;
    }

    // Remove 'mcp::' prefix
    final withoutPrefix = compositeId.substring(5);

    // Split by '::' delimiter - we need exactly 3 parts: id, slug, tool
    final parts = withoutPrefix.split('::');
    if (parts.length != 3) {
      return null;
    }

    final mcpServerId = parts[0];
    final slugName = parts[1];
    final toolIdentifier = parts[2];

    return McpToolIdComponents(
      mcpServerId: mcpServerId,
      slugName: slugName,
      toolIdentifier: toolIdentifier,
    );
  }

  // ============================================================
  // Private: Database Operations
  // ============================================================

  /// Load MCPs from database on initialization.
  Future<void> _loadMcpsFromDatabase() async {
    try {
      final repository = ref.read(mcpServersRepositoryProvider);
      final workspace = await ref.read(selectedWorkspaceProvider.future);
      final servers = await repository.getEnabledMcpServersForWorkspace(
        workspace.id,
      );

      for (final server in servers) {
        await _connectToMcp(server);
      }
    } on Exception catch (e) {
      // Log error but don't crash - MCP loading is not critical
      // ignore: avoid_print
      print('Failed to load MCP servers from database: $e');
    }
  }

  /// Load MCPs from database that aren't already in state.
  Future<void> _loadMissingMcps() async {
    try {
      final repository = ref.read(mcpServersRepositoryProvider);
      final workspace = await ref.read(selectedWorkspaceProvider.future);
      final servers = await repository.getEnabledMcpServersForWorkspace(
        workspace.id,
      );

      final existingIds = state
          .map((McpConnectionState c) => c.server.id)
          .toSet();
      final newServers = servers
          .where((McpServerEntity s) => !existingIds.contains(s.id))
          .toList();

      for (final server in newServers) {
        await _connectToMcp(server);
      }
    } on Exception catch (e) {
      // Log error but don't crash
      // ignore: avoid_print
      print('Failed to load missing MCP servers: $e');
    }
  }

  // ============================================================
  // Private: Connection Management
  // ============================================================

  /// Connect to an MCP server.
  Future<void> _connectToMcp(McpServerEntity server) async {
    // Check if already in state
    final existingIndex = state.indexWhere(
      (McpConnectionState c) => c.server.id == server.id,
    );

    // Add or update state to "connecting"
    if (existingIndex >= 0) {
      state = [
        ...state.sublist(0, existingIndex),
        state[existingIndex].copyWith(
          status: McpConnectionStatus.connecting,
          errorMessage: null,
        ),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [
        ...state,
        McpConnectionState(
          server: server,
          status: McpConnectionStatus.connecting,
        ),
      ];
    }

    try {
      // Create client configuration
      final config = mcp.McpClient.simpleConfig(
        name: 'AuraVibes MCP Client',
        version: '1.0.0',
      );

      // Create transport configuration based on server settings
      final transportConfig = _createTransportConfig(server);

      // Create and connect client
      final clientResult = await mcp.McpClient.createAndConnect(
        config: config,
        transportConfig: transportConfig,
      );

      final client = clientResult.fold(
        (c) => c,
        (error) => throw Exception('Failed to connect: $error'),
      );

      // List available tools from the MCP server
      final tools = await client.listTools();
      final mcpTools = _convertTools(tools, server);

      // Update state with connected client and tools
      _updateConnectionState(
        server.id,
        (connection) => connection.copyWith(
          status: McpConnectionStatus.connected,
          client: client,
          tools: mcpTools,
          errorMessage: null,
        ),
      );

      // Sync tools to database
      await _syncMcpToolsToDatabase(server, mcpTools);
    } on Exception catch (e) {
      // Update state with error
      _updateConnectionState(
        server.id,
        (connection) => connection.copyWith(
          status: McpConnectionStatus.error,
          client: null,
          tools: [],
          errorMessage: e.toString(),
        ),
      );
    }
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
    final slug = _slugifyName(server.name);
    return tools.map((mcp.Tool tool) {
      return McpToolInfo(
        originalName: tool.name,
        prefixedName: _generatePrefixedToolName(server.id, slug, tool.name),
        description: tool.description,
        inputSchema: tool.inputSchema,
        mcpServerId: server.id,
      );
    }).toList();
  }

  /// Generate a prefixed tool name to avoid conflicts.
  ///
  /// Format: `mcp::<mcp_id>::<slug_name>::<tool_identifier>`
  /// - mcp_id: Database ID of the MCP server (ensures uniqueness)
  /// - slug_name: URL-safe slug of server name (for LLM readability)
  /// - tool_identifier: Original tool name from the MCP server
  String _generatePrefixedToolName(
    String mcpId,
    String mcpSlug,
    String toolName,
  ) {
    return 'mcp::$mcpId::$mcpSlug::$toolName';
  }

  /// Convert a name to a URL-safe slug.
  String _slugifyName(String name) {
    return name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');
  }

  /// Update a connection state by server ID.
  void _updateConnectionState(
    String serverId,
    McpConnectionState Function(McpConnectionState) updater,
  ) {
    final index = state.indexWhere(
      (McpConnectionState c) => c.server.id == serverId,
    );
    if (index == -1) return;

    state = [
      ...state.sublist(0, index),
      updater(state[index]),
      ...state.sublist(index + 1),
    ];
  }

  /// Dispose all active connections.
  void _disposeAllConnections() {
    for (final connection in state) {
      connection.client?.disconnect();
    }
  }

  // ============================================================
  // Private: Tool Conversion
  // ============================================================

  /// Convert McpToolInfo to LangChain ToolSpec.
  ToolSpec _toToolSpec(McpToolInfo tool) {
    return ToolSpec(
      name: tool.prefixedName,
      description: tool.description,
      inputJsonSchema: tool.inputSchema,
    );
  }

  // ============================================================
  // Private: Tool Synchronization
  // ============================================================

  /// Sync MCP tools to the database.
  ///
  /// Uses the repository's syncMcpTools method which:
  /// - Adds new tools that don't exist yet
  /// - Removes tools that no longer exist on the MCP server
  /// - Preserves user customizations (isEnabled, permissions, etc.)
  Future<void> _syncMcpToolsToDatabase(
    McpServerEntity server,
    List<McpToolInfo> tools,
  ) async {
    try {
      final repository = ref.read(mcpServersRepositoryProvider);

      await repository.syncMcpTools(
        mcpServerId: server.id,
        currentTools: tools,
      );
    } on Exception catch (e) {
      // Log error but don't fail the connection
      // ignore: avoid_print
      print('Failed to sync MCP tools to database: $e');
    }
  }
}

// ============================================================
// Helper Provider: All MCP Tools
// ============================================================

/// Provides a flat list of all available MCP tools.
@riverpod
List<McpToolInfo> allMcpTools(Ref ref) {
  final connections = ref.watch(mcpManagerProvider);
  return connections
      .where(
        (McpConnectionState c) => c.status == McpConnectionStatus.connected,
      )
      .expand((McpConnectionState c) => c.tools)
      .toList();
}

/// Provides MCP tools as ToolSpec for the chatbot service.
@riverpod
List<ToolSpec> mcpToolSpecs(Ref ref) {
  final tools = ref.watch(allMcpToolsProvider);
  return tools
      .map(
        (McpToolInfo tool) => ToolSpec(
          name: tool.prefixedName,
          description: tool.description,
          inputJsonSchema: tool.inputSchema,
        ),
      )
      .toList();
}

// ============================================================
// Helper Provider: Connecting MCP Servers
// ============================================================

/// Provides the list of MCP connection states that are currently connecting
/// from the specified server IDs.
///
/// This is useful for UI to show which specific MCPs are being waited on.
@riverpod
List<McpConnectionState> connectingMcpServers(
  Ref ref, {
  required List<String> mcpServerIds,
}) {
  final allConnections = ref.watch(mcpManagerProvider);
  return allConnections
      .where((c) => mcpServerIds.contains(c.server.id))
      .where((c) => c.status == McpConnectionStatus.connecting)
      .toList();
}

/// Provider that returns true if any of the specified MCP servers are
/// connecting.
@riverpod
bool isMcpConnectionsPending(
  Ref ref, {
  required List<String> mcpServerIds,
}) {
  final connecting = ref.watch(
    connectingMcpServersProvider(mcpServerIds: mcpServerIds),
  );
  return connecting.isNotEmpty;
}
