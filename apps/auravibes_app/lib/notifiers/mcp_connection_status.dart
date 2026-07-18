// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_mcp_server_to_create_use_case.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/tools/data/cloud_tools_repository.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/services/mcp_service/mcp_manager_client.dart';
import 'package:auravibes_app/services/mcp_service/o_auth_authenticate.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_connection_status.freezed.dart';
part 'mcp_connection_status.g.dart';

final _logger = Logger('McpConnectionNotifier');

const Duration _mcpConnectionTimeout = Duration(seconds: 10);

// ============================================================.
// MCP Connection Status.
// ============================================================.

/// Status of an MCP server connection.
enum McpConnectionStatus {
  /// Not connected to the server.
  disconnected,

  /// Currently attempting to connect.
  connecting,

  /// Successfully connected and ready.
  connected,

  /// Connection failed with an error.
  error,
}

// ============================================================.
// MCP Connection State.
// ============================================================.

/// State for a single MCP server connection.
@freezed
abstract class McpConnectionState with _$McpConnectionState {
  const factory McpConnectionState({
    /// The MCP server configuration.
    required McpServerEntity server,

    /// Current connection status.
    required McpConnectionStatus status,

    /// The connected MCP client instance (null if not connected).
    McpManagerClient? client,

    /// Tools available from this MCP server.
    @Default([]) List<McpToolInfo> tools,

    /// Error message if connection failed.
    String? errorMessage,
  }) = _McpConnectionState;

  const McpConnectionState._();

  /// Whether this connection is ready to use.
  bool get isReady => status == McpConnectionStatus.connected && client != null;

  /// Whether this connection has tools available.
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
// ============================================================.
// MCP Tool ID Components.
// ============================================================.

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

  /// The database ID of the MCP server.
  final String mcpServerId;

  /// The slugified server name (for readability).
  final String slugName;

  /// The original tool name from the MCP server.
  final String toolIdentifier;

  static McpToolIdComponents? fromComposite(String compositeId) {
    final parsed = ToolNameFormatter.parse(compositeId);
    if (parsed case AgentResolvedToolName(
      kind: AgentResolvedToolKind.mcp,
      mcpServerId: final mcpServerId?,
      mcpSlug: final mcpSlug?,
      :final toolIdentifier,
    )) {
      return McpToolIdComponents(
        mcpServerId: mcpServerId,
        slugName: mcpSlug,
        toolIdentifier: toolIdentifier,
      );
    }

    return null;
  }
}

// ============================================================.
// MCP Manager Notifier.
// ============================================================.

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
/// `mcp_<mcpId>_<slugName>_<toolIdentifier>`
/// - mcpId: Database ID for uniqueness
/// - slugName: URL-safe server name for LLM readability
/// - toolIdentifier: Original tool identifier from the MCP server
///
/// See [McpToolIdComponents] for parsing composite IDs.
@riverpod
class McpConnectionNotifier extends _$McpConnectionNotifier {
  McpManagerService? _mcpManagerService;
  String? _activeWorkspaceId;
  var _isCloud = false;
  var _isDisposed = false;
  var _lastKnownState = const <McpConnectionState>[];
  final _tokenSubscriptions = <String, StreamSubscription<OAuthTokenEntity>>{};
  StreamController<List<McpConnectionState>> _stateController =
      StreamController<List<McpConnectionState>>.broadcast(sync: true);

  @override
  List<McpConnectionState> build() {
    _isDisposed = false;
    _lastKnownState = const [];
    if (_stateController.isClosed) {
      _stateController = StreamController<List<McpConnectionState>>.broadcast(
        sync: true,
      );
    }
    ref
      ..onDispose(_onDispose)
      ..listen<String?>(currentRouteWorkspaceIdProvider, (previous, next) {
        if (next == null || next == previous) {
          return;
        }

        unawaited(_loadMcpsForWorkspace(next));
      });

    final initialWorkspaceId = ref.read(currentRouteWorkspaceIdProvider);
    if (initialWorkspaceId != null) {
      unawaited(_loadMcpsForWorkspace(initialWorkspaceId));
    }

    return [];
  }

  // ============================================================.
  // Public API.
  // ============================================================.

  /// Add a new MCP server from the form data.
  ///
  /// This will:
  /// 1. Save the server to the database
  /// 2. Connect to the MCP server
  /// 3. Persist tools to database if connection successful
  Future<void> addMcpServer(
    McpServerFormToCreate serverToCreate, {
    required String workspaceId,
  }) async {
    if (_isCloud) {
      await _addCloudMcpServer(serverToCreate, workspaceId);

      return;
    }
    final manager = _requiredMcpManager;
    final serverInfo =
        await BuildMcpServerToCreateUseCase(
          authenticator: OAuthAuthenticate(
            callbackUrlScheme: 'me-auravibes',
            clientName: 'Aura Vibes MCP Client',
          ),
        ).call(
          serverToCreate,
        );

    final serviceConnectionRepository = ref.read(
      serviceConnectionRepositoryProvider,
    );
    final serviceConnectionId = await serviceConnectionRepository
        .createMcpServiceConnection(
          workspaceId: workspaceId,
          profile: McpServiceConnectionProfile(
            name: serverInfo.name,
            authenticationType: serverInfo.authenticationType,
          ),
        );
    final serverForPersistence = serverInfo.copyWith(
      serviceConnectionId: serviceConnectionId,
    );

    McpManagerClient? client;
    var mcpTools = const <McpToolInfo>[];
    McpServerEntity savedServer;
    try {
      client = await manager.connectMcp(serverInfo);

      mcpTools = await manager.getTools(client);

      final repository = _repositoryFor(workspaceId);
      savedServer = await repository.addMcpServerWithTools(
        workspaceId: workspaceId,
        serverToCreate: serverForPersistence,
        tools: mcpTools,
      );
    } on Object {
      if (client != null) {
        manager.disconnect(client);
      }
      if (serviceConnectionId != null) {
        await serviceConnectionRepository.deleteOwnedMcpCredential(
          serviceConnectionId,
        );
      }
      rethrow;
    }

    if (_isDisposed) {
      manager.disconnect(client);

      return;
    }
    _listenTokenUpdates(
      serverId: savedServer.id,
      serviceConnectionId: serviceConnectionId,
      client: client,
    );

    _setState([
      ...state,
      McpConnectionState(
        server: savedServer,
        status: McpConnectionStatus.connected,
        client: client,
        tools: mcpTools,
      ),
    ]);

    if (!_isDisposed) {
      ref.invalidate(workspaceToolsProvider(workspaceId));
    }
  }

  /// Delete an MCP server by identifier.
  ///
  /// This will:
  /// 1. Disconnect the client if connected
  /// 2. Remove from state
  /// 3. Delete from database (cascades to tools group and tools)
  Future<void> deleteMcpServer(String serverId) async {
    // Find and disconnect the client.
    final connection = state.firstWhereOrNull((c) => c.server.id == serverId);

    if (connection != null) {
      unawaited(_tokenSubscriptions.remove(serverId)?.cancel());
      _mcpManagerService?.disconnect(connection.client);
    }

    // Remove from state.
    _setState(state.where((c) => c.server.id != serverId).toList());

    // Delete from database (cascades to tools group and tools).
    final repository = _activeRepository;
    final _ = await repository.deleteMcpServer(serverId);
  }

  /// Reconnect to a specific MCP server.
  ///
  /// If the server is present in state, disconnects and reconnects.
  /// If absent (e.g. after cold start), loads the server from the
  /// repository and creates a fresh connection.
  Future<void> reconnectMcpServer(String serverId) async {
    if (_isCloud) {
      await _discoverCloudMcp(serverId);

      return;
    }
    final connection = state.where((c) => c.server.id == serverId).firstOrNull;
    if (connection != null) {
      unawaited(_tokenSubscriptions.remove(serverId)?.cancel());
      _requiredMcpManager.disconnect(connection.client);
      await _connectToMcp(connection.server);

      return;
    }

    final repository = _activeRepository;
    final server = await repository.getMcpServerById(serverId);
    if (server != null) {
      await _connectToMcp(server);
    }
  }

  /// Disconnect from a specific MCP server without deleting.
  void disconnectMcpServer(String serverId) {
    if (_isCloud) return;
    final index = state.indexWhere(
      (c) => c.server.id == serverId,
    );
    if (index == -1) return;

    final connection = state[index];
    unawaited(_tokenSubscriptions.remove(serverId)?.cancel());
    _requiredMcpManager.disconnect(connection.client);

    _setState([
      ...state.sublist(0, index),
      connection.copyWith(
        status: McpConnectionStatus.disconnected,
        client: null,
      ),
      ...state.sublist(index + 1),
    ]);
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
    if (connection == null ||
        connection.status != McpConnectionStatus.connected ||
        (!_isCloud && connection.client == null)) {
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

  /// Returns a Future that completes when the specified MCP servers have
  /// finished their connection attempts (status is connected, error,
  /// or disconnected - not connecting).
  ///
  /// [mcpServerIds] - List of MCP server IDs to wait for.
  ///   If empty, returns immediately.
  /// [timeout] - Maximum time to wait. If null, uses [_mcpConnectionTimeout].
  ///
  /// Returns normally after all connections resolve OR timeout is reached.
  ///
  /// Also completes if this notifier is disposed (the state stream closes),
  /// so callers do not hang waiting on a torn-down notifier.
  Future<void> waitForConnectionsReady({
    required List<String> mcpServerIds,
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? _mcpConnectionTimeout;
    if (mcpServerIds.isEmpty || effectiveTimeout <= Duration.zero) {
      return;
    }

    final ids = mcpServerIds.toSet();
    bool ready(List<McpConnectionState> connections) => !connections
        .where((c) => ids.contains(c.server.id))
        .any((c) => c.status == McpConnectionStatus.connecting);

    if (ready(state)) return;

    final _ = await _stateController.stream
        .firstWhere(ready, orElse: () => const [])
        .timeout(effectiveTimeout, onTimeout: () => const []);
  }

  /// Get the list of MCP connection states that are currently connecting
  /// from the specified server IDs.
  List<McpConnectionState> getConnectingServers(List<String> mcpServerIds) {
    return state
        .where((c) => mcpServerIds.contains(c.server.id))
        .where((c) => c.status == McpConnectionStatus.connecting)
        .toList();
  }

  /// Call an MCP tool on a connected MCP server.
  ///
  /// The caller provides the resolved MCP server ID and tool identifier.
  /// This method validates the current connection, ensures the tool exists,
  /// and then executes it with the given arguments.
  ///
  /// Returns the tool result as a string.
  /// Throws an exception if the MCP server is not connected or tool not found.
  Future<String> callTool({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) async {
    if (_isCloud) {
      throw const UnsupportedWorkspaceCapabilityException();
    }
    final connection = getConnection(mcpServerId);
    if (connection == null) {
      throw Exception('MCP server not found: $mcpServerId');
    }

    if (!connection.isReady) {
      throw Exception('MCP server not connected: $mcpServerId');
    }

    final toolExists = connection.tools.any(
      (t) => t.toolName == toolIdentifier,
    );
    if (!toolExists) {
      throw Exception(
        'Tool "$toolIdentifier" not found on MCP server: $mcpServerId',
      );
    }

    final client = connection.client;
    if (client == null) {
      throw Exception('MCP server not connected: $mcpServerId');
    }

    return _requiredMcpManager.callToolString(
      client,
      toolIdentifier: toolIdentifier,
      arguments: arguments,
    );
  }

  // ============================================================.
  // Private: Database Operations.
  // ============================================================.

  /// Load enabled MCPs only for the active workspace.
  Future<void> _loadMcpsForWorkspace(String workspaceId) async {
    try {
      _activeWorkspaceId = workspaceId;
      final repository = _repositoryFor(workspaceId);
      _isCloud = repository is CloudToolsRepository;
      _mcpManagerService = _isCloud
          ? null
          : ref.read(mcpManagerServiceProvider);
      if (_isDisposed) {
        return;
      }

      final servers = await repository.getEnabledMcpServersForWorkspace(
        workspaceId,
      );
      if (_isDisposed) {
        return;
      }

      for (final server in servers) {
        if (_isDisposed) {
          return;
        }

        if (getConnection(server.id) case final existingConnection?
            when existingConnection.isReady ||
                existingConnection.status == McpConnectionStatus.connecting) {
          continue;
        }

        if (_isCloud) {
          await _discoverCloudMcp(server.id, server: server);
        } else {
          await _connectToMcp(server);
        }
      }
    } on Exception catch (e, stackTrace) {
      _logger.warning(
        'Failed to load MCP servers from database',
        e,
        stackTrace,
      );
    }
  }
  // ============================================================.
  // Private: Connection Management.
  // ============================================================.

  /// Connect to an MCP server.
  Future<void> _connectToMcp(McpServerEntity server) async {
    if (_isDisposed) {
      return;
    }

    // Check if already in state.
    final existingIndex = state.indexWhere(
      (c) => c.server.id == server.id,
    );

    // Add or update state to "connecting.".
    if (existingIndex >= 0) {
      _setState([
        ...state.sublist(0, existingIndex),
        state[existingIndex].copyWith(
          status: McpConnectionStatus.connecting,
          errorMessage: null,
        ),
        ...state.sublist(existingIndex + 1),
      ]);
    } else {
      _setState([
        ...state,
        McpConnectionState(
          server: server,
          status: McpConnectionStatus.connecting,
        ),
      ]);
    }

    McpManagerClient? connectedClient;
    try {
      final authenticationType = await ref
          .read(oauthCredentialServiceProvider)
          .resolveMcpAuthentication(server.serviceConnectionId);
      final serverToConnect = server.copyWith(
        authenticationType: authenticationType,
      );
      connectedClient = await _requiredMcpManager.connectMcp(
        serverToConnect,
      );

      final mcpTools = await _requiredMcpManager.getTools(
        connectedClient,
      );
      if (_isDisposed) {
        return;
      }
      _listenTokenUpdates(
        serverId: server.id,
        serviceConnectionId: server.serviceConnectionId,
        client: connectedClient,
      );

      // Update state with connected client and tools.
      _updateConnectionState(
        server.id,
        (connection) => connection.copyWith(
          status: McpConnectionStatus.connected,
          client: connectedClient,
          tools: mcpTools,
          errorMessage: null,
        ),
      );
      connectedClient = null;

      // Sync tools to database.
      await _syncMcpToolsToDatabase(server, mcpTools);
    } on Exception catch (e) {
      // Update state with error.
      _updateConnectionState(
        server.id,
        (connection) => connection.copyWith(
          status: McpConnectionStatus.error,
          client: null,
          tools: [],
          errorMessage: e.toString(),
        ),
      );
    } finally {
      if (connectedClient != null) {
        _requiredMcpManager.disconnect(connectedClient);
      }
    }
  }

  /// Update a connection state by server ID.
  void _updateConnectionState(
    String serverId,
    McpConnectionState Function(McpConnectionState) updater,
  ) {
    if (_isDisposed) {
      return;
    }

    final index = state.indexWhere(
      (c) => c.server.id == serverId,
    );
    if (index == -1) return;

    _setState([
      ...state.sublist(0, index),
      updater(state[index]),
      ...state.sublist(index + 1),
    ]);
  }

  void _onDispose() {
    _isDisposed = true;
    _disposeAllConnections();
    unawaited(_stateController.close());
  }

  /// Dispose all active connections.
  void _disposeAllConnections() {
    final manager = _mcpManagerService;
    if (manager == null) return;
    for (final connection in _lastKnownState) {
      manager.disconnect(connection.client);
    }
    for (final subscription in _tokenSubscriptions.values) {
      unawaited(subscription.cancel());
    }
    _tokenSubscriptions.clear();
  }

  void _setState(List<McpConnectionState> nextState) {
    _lastKnownState = nextState;
    state = nextState;
  }

  @override
  set state(List<McpConnectionState> value) {
    super.state = value;
    if (!_stateController.isClosed) _stateController.add(value);
  }

  // ============================================================.
  // Private: Tool Synchronization.
  // ============================================================.

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
      final repository = _repositoryFor(server.workspaceId);

      await repository.syncMcpTools(
        mcpServerId: server.id,
        currentTools: tools,
      );
    } on Exception catch (e, stackTrace) {
      _logger.warning(
        'Failed to sync MCP tools to database',
        e,
        stackTrace,
      );
    }
  }

  McpManagerService get _requiredMcpManager =>
      _mcpManagerService ??
      (throw const UnsupportedWorkspaceCapabilityException());

  CloudToolsRepository get _cloudRepository {
    final repository = _activeRepository;
    if (repository case final CloudToolsRepository cloudRepository) {
      return cloudRepository;
    }

    throw const UnsupportedWorkspaceCapabilityException();
  }

  McpServersRepositoryContract get _activeRepository {
    final workspaceId = _activeWorkspaceId;
    if (workspaceId == null) {
      throw StateError('No active workspace for MCP operation');
    }

    return _repositoryFor(workspaceId);
  }

  McpServersRepositoryContract _repositoryFor(String workspaceId) {
    final session = ref
        .read(
          workspaceSessionForRouteProvider(workspaceId),
        )
        .requireValue;

    return ref.read(mcpServersRepositoryProvider(session));
  }

  Future<void> _addCloudMcpServer(
    McpServerFormToCreate server,
    String workspaceId,
  ) async {
    final result = await _cloudRepository.createMcpServer(
      workspaceId: workspaceId,
      server: server,
    );
    if (_isDisposed) return;
    _setCloudDiscovery(result.server, result.discovery);
    ref.invalidate(workspaceToolsProvider(workspaceId));
  }

  Future<void> _discoverCloudMcp(
    String serverId, {
    McpServerEntity? server,
  }) async {
    final repository = _cloudRepository;
    final resolvedServer =
        server ?? await repository.getMcpServerById(serverId);
    if (resolvedServer == null || _isDisposed) return;
    _upsertConnection(
      McpConnectionState(
        server: resolvedServer,
        status: McpConnectionStatus.connecting,
      ),
    );
    try {
      final discovery = await repository.discoverMcpServer(serverId);
      if (_isDisposed) return;
      _setCloudDiscovery(resolvedServer, discovery);
    } on Exception catch (error) {
      if (_isDisposed) return;
      _upsertConnection(
        McpConnectionState(
          server: resolvedServer,
          status: McpConnectionStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _setCloudDiscovery(
    McpServerEntity server,
    DiscoverMcpServerResult discovery,
  ) {
    final connected = discovery.health == McpServerHealth.healthy;
    _upsertConnection(
      McpConnectionState(
        server: server,
        status: connected
            ? McpConnectionStatus.connected
            : McpConnectionStatus.error,
        tools: [
          for (final tool in discovery.tools)
            McpToolInfo(
              toolName: tool.name,
              description: tool.description ?? '',
              inputSchema:
                  jsonDecode(tool.inputSchemaJson) as Map<String, dynamic>,
            ),
        ],
        errorMessage: connected ? null : discovery.errorCode,
      ),
    );
  }

  void _upsertConnection(McpConnectionState connection) {
    final index = state.indexWhere(
      (item) => item.server.id == connection.server.id,
    );
    if (index < 0) {
      _setState([...state, connection]);

      return;
    }
    _setState([
      ...state.sublist(0, index),
      connection,
      ...state.sublist(index + 1),
    ]);
  }

  void _listenTokenUpdates({
    required String serverId,
    required String? serviceConnectionId,
    required McpManagerClient client,
  }) {
    final tokenUpdates = client.onTokenUpdate;
    if (serviceConnectionId == null || tokenUpdates == null) return;
    unawaited(_tokenSubscriptions.remove(serverId)?.cancel());
    _tokenSubscriptions[serverId] = tokenUpdates.listen((token) {
      unawaited(
        ref
            .read(oauthCredentialServiceProvider)
            .persistOAuthTokenUpdate(
              serviceConnectionId: serviceConnectionId,
              token: token,
            ),
      );
    });
  }
}

@Riverpod(keepAlive: true)
McpManagerService mcpManagerService(Ref _) {
  return McpManagerService();
}
