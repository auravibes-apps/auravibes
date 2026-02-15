import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_mcp_server_to_create_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/call_mcp_tool_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/wait_for_mcp_connections_usecase.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/selected_workspace.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/mcp_service/mcp_service.dart';
import 'package:auravibes_app/services/mcp_service/oauth_authenticate.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:langchain/langchain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_connection_controller.freezed.dart';
part 'mcp_connection_controller.g.dart';

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
    McpManagerClient? client,

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

extension _McpToolInfoSpec on McpToolInfo {
  ToolSpec _spec(McpServerEntity server) {
    return .new(
      name: finalToolName(server),
      description: description,
      inputJsonSchema: inputSchema,
    );
  }
}
// ============================================================
// MCP Tool ID Components
// ============================================================

/// Parsed components of a composite MCP tool ID.
///
/// The composite ID format is: `mcp_<mcp_id>_<slug_name>_<tool_identifier>`
///
/// Note: Tool names must match pattern ^[a-zA-Z0-9_-]{1,128}$
/// so we use underscores as separators instead of colons.
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

  static McpToolIdComponents? fromComposite(String compositeId) {
    if (!compositeId.startsWith('mcp_')) {
      return null;
    }

    // Remove 'mcp_' prefix
    final withoutPrefix = compositeId.substring(4);

    // Parse format: <id>_<slug>_<tool>
    // Since slug and tool can contain underscores, we parse carefully
    final firstUnderscoreIdx = withoutPrefix.indexOf('_');
    if (firstUnderscoreIdx <= 0) {
      return null;
    }

    final mcpServerId = withoutPrefix.substring(0, firstUnderscoreIdx);
    final rest = withoutPrefix.substring(firstUnderscoreIdx + 1);

    final secondUnderscoreIdx = rest.indexOf('_');
    if (secondUnderscoreIdx <= 0) {
      return null;
    }

    final slugName = rest.substring(0, secondUnderscoreIdx);
    final toolIdentifier = rest.substring(secondUnderscoreIdx + 1);

    if (mcpServerId.isEmpty || slugName.isEmpty || toolIdentifier.isEmpty) {
      return null;
    }

    return McpToolIdComponents(
      mcpServerId: mcpServerId,
      slugName: slugName,
      toolIdentifier: toolIdentifier,
    );
  }
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
class McpConnectionController extends _$McpConnectionController {
  late final McpManagerService _mcpManagerService;
  @override
  List<McpConnectionState> build() {
    _mcpManagerService = ref.watch(mcpManagerServiceProvider);
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
  Future<void> addMcpServer(McpServerFormToCreate serverToCreate) async {
    final workspace = await ref.read(selectedWorkspaceProvider.future);
    final workspaceId = workspace.id;

    final serverInfo =
        await BuildMcpServerToCreateUseCase(
          authenticator: OauthAuthenticate(
            callbackUrlScheme: 'me-auravibes',
            clientName: 'Aura Vibes MCP Client',
          ),
        ).call(
          serverToCreate,
        );

    final client = await _mcpManagerService.connectMcp(serverInfo);

    final mcpTools = await _mcpManagerService.getTools(client);

    final repository = ref.read(mcpServersRepositoryProvider);
    final savedServer = await repository.addMcpServerWithTools(
      workspaceId: workspaceId,
      serverToCreate: serverInfo.copyWith(
        authenticationType: await serverInfo.authenticationType.copyCryptor(
          ref.read(encryptionServiceProvider).encrypt,
        ),
      ),
      tools: mcpTools,
    );

    state = [
      ...state,
      McpConnectionState(
        server: savedServer,
        status: McpConnectionStatus.connected,
        tools: mcpTools,
        client: client,
      ),
    ];

    // Invalidate workspace tools provider so the UI refreshes with the new
    // tools
    ref.invalidate(workspaceToolsProvider);
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
      _mcpManagerService.disconnect(connection.client);
    }

    // Remove from state
    state = state.where((c) => c.server.id != serverId).toList();

    // Delete from database (cascades to tools group and tools)
    final repository = ref.read(mcpServersRepositoryProvider);
    await repository.deleteMcpServer(serverId);
  }

  /// Reconnect to a specific MCP server.
  Future<void> reconnectMcpServer(String serverId) async {
    final connection = state.where((c) => c.server.id == serverId).firstOrNull;
    if (connection == null) return;

    // Disconnect if currently connected
    _mcpManagerService.disconnect(connection.client);

    // Reconnect
    await _connectToMcp(connection.server);
  }

  /// Disconnect from a specific MCP server without deleting.
  void disconnectMcpServer(String serverId) {
    final index = state.indexWhere(
      (c) => c.server.id == serverId,
    );
    if (index == -1) return;

    final connection = state[index];
    _mcpManagerService.disconnect(connection.client);

    state = [
      ...state.sublist(0, index),
      connection.copyWith(
        status: McpConnectionStatus.disconnected,
        client: null,
      ),
      ...state.sublist(index + 1),
    ];
  }

  /// Get a connection state by server ID.
  McpConnectionState? getConnection(String serverId) {
    return state.where((c) => c.server.id == serverId).firstOrNull;
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
      (t) => t.toolName == toolName,
    );
    if (toolInfo == null) {
      return null;
    }

    return toolInfo._spec(connection.server);
  }

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
    final effectiveTimeout = timeout ?? getMcpConnectionTimeout();
    await const WaitForMcpConnectionsUseCase().call(
      mcpServerIds: mcpServerIds,
      timeout: effectiveTimeout,
      isStillConnecting: () {
        return state
            .where((connection) => mcpServerIds.contains(connection.server.id))
            .any(
              (connection) =>
                  connection.status == McpConnectionStatus.connecting,
            );
      },
    );
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

    return CallMcpToolUseCase(
      callTool: ({required toolIdentifier, required arguments}) {
        return _mcpManagerService.callToolString(
          connection.client!,
          toolIdentifier: toolIdentifier,
          arguments: arguments,
        );
      },
    ).call(
      isConnected: connection.isReady,
      availableTools: connection.tools,
      mcpServerId: mcpServerId,
      toolIdentifier: toolIdentifier,
      arguments: arguments,
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
        await _connectToMcp(
          server.copyWith(
            authenticationType: await server.authenticationType.copyCryptor(
              ref.read(encryptionServiceProvider).decrypt,
            ),
          ),
        );
      }
    } on Exception catch (e) {
      // Log error but don't crash - MCP loading is not critical
      // ignore: avoid_print
      print('Failed to load MCP servers from database: $e');
    }
  }
  // ============================================================
  // Private: Connection Management
  // ============================================================

  /// Connect to an MCP server.
  Future<void> _connectToMcp(McpServerEntity server) async {
    // Check if already in state
    final existingIndex = state.indexWhere(
      (c) => c.server.id == server.id,
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
      final client = await _mcpManagerService.connectMcp(server);

      final mcpTools = await _mcpManagerService.getTools(client);

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

  /// Update a connection state by server ID.
  void _updateConnectionState(
    String serverId,
    McpConnectionState Function(McpConnectionState) updater,
  ) {
    final index = state.indexWhere(
      (c) => c.server.id == serverId,
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
      _mcpManagerService.disconnect(connection.client);
    }
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

@Riverpod(keepAlive: true)
McpManagerService mcpManagerService(Ref ref) {
  return McpManagerService();
}
