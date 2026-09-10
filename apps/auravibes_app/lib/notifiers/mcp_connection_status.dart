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
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/services/mcp_service/mcp_manager_client.dart';
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

const Duration _mcpConnectionTimeout = .new(seconds: 10);

typedef _AddedMcpServer = ({
  McpServerEntity server,
  List<McpToolInfo> tools,
  McpManagerClient client,
  String? serviceConnectionId,
});

typedef _LocalMcpAddRequest = ({
  McpManagerService manager,
  McpServerToCreate serverInfo,
  McpServerToCreate serverForPersistence,
  String workspaceId,
  String? serviceConnectionId,
  ServiceConnectionRepository serviceConnectionRepository,
});

typedef _LocalMcpAddInput = ({
  McpManagerService manager,
  McpServerToCreate serverInfo,
  ServiceConnectionRepository serviceConnectionRepository,
  String workspaceId,
  String? serviceConnectionId,
});

typedef _McpServiceConnectionAdd = ({
  ServiceConnectionRepository repository,
  String? id,
});

typedef _McpAddCleanup = ({
  McpManagerService manager,
  ServiceConnectionRepository serviceConnectionRepository,
  McpManagerClient? client,
  String? serviceConnectionId,
});

typedef _CloudDiscoveryError = ({
  String serverId,
  McpServerEntity server,
  Exception error,
  StackTrace stackTrace,
});

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
@Freezed(toStringOverride: false)
abstract class const McpConnectionState._() with _$McpConnectionState {
  const factory({
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

  bool get hasTools => tools.isNotEmpty;

  /// Whether this connection is ready to use.
  bool get isReady => status == McpConnectionStatus.connected && client != null;

  /// Whether this connection belongs to [serverId].
  bool hasServerId(String serverId) => server.id == serverId;

  /// Whether this connection exposes [toolName].
  bool hasTool(String toolName) =>
      tools.any((tool) => tool.toolName == toolName);
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
class const McpToolIdComponents({
  /// The database ID of the MCP server.
  required final String mcpServerId,

  /// The slugified server name (for readability).
  required final String slugName,

  /// The original tool name from the MCP server.
  required final String toolIdentifier,
}) {
  static McpToolIdComponents? fromComposite(String compositeId) =>
      _fromParsed(ToolNameFormatter.parse(compositeId));

  static McpToolIdComponents? _fromParsed(AgentResolvedToolName? parsed) =>
      switch (parsed) {
        AgentResolvedToolName(
          kind: AgentResolvedToolKind.mcp,
          mcpServerId: final mcpServerId?,
          mcpSlug: final mcpSlug?,
          :final toolIdentifier,
        ) =>
          _mcpToolIdComponents(mcpServerId, mcpSlug, toolIdentifier),
        _ => null,
      };
}

McpToolIdComponents _mcpToolIdComponents(
  String mcpServerId,
  String slugName,
  String toolIdentifier,
) => McpToolIdComponents(
  mcpServerId: mcpServerId,
  slugName: slugName,
  toolIdentifier: toolIdentifier,
);

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
  String? _activeWorkspaceId;
  var _isCloud = false;
  var _isDisposed = false;
  var _lastKnownState = const <McpConnectionState>[];
  var _currentState = const <McpConnectionState>[];
  final _tokenSubscriptions = <String, StreamSubscription<OAuthTokenEntity>>{};
  StreamController<List<McpConnectionState>> _stateController =
      StreamController<List<McpConnectionState>>.broadcast(sync: true);
  McpManagerService? _mcpManagerService;

  Ref get _notifierRef => ref;

  @override
  set state(List<McpConnectionState> value) {
    super.state = value;
    _currentState = value;
    if (!_stateController.isClosed) _stateController.add(value);
  }

  /// Call an MCP tool on a connected MCP server.
  Future<String> callTool({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) async {
    if (_isCloud) {
      throw const UnsupportedWorkspaceCapabilityException();
    }
    final client = _requiredToolClient(mcpServerId, toolIdentifier);

    return await _requiredMcpManager.callToolString(
      client,
      toolIdentifier: toolIdentifier,
      arguments: arguments,
    );
  }

  /// Add a new MCP server from the form data.
  Future<void> addMcpServer(
    McpServerFormToCreate serverToCreate, {
    required String workspaceId,
  }) async {
    if (_isCloud) {
      await _addCloudMcpServer(serverToCreate, workspaceId);

      return;
    }
    await _addLocalMcpServer(serverToCreate, workspaceId);
  }

  /// Reconnect to a specific MCP server.
  Future<void> reconnectMcpServer(String serverId) async {
    if (_isCloud) {
      await _discoverCloudMcp(serverId);

      return;
    }
    if (await _reconnectExistingMcp(serverId)) return;

    await _reconnectStoredMcp(serverId);
  }

  @override
  List<McpConnectionState> build() {
    _resetBuildState();
    _listenForWorkspaceChanges();
    _loadInitialWorkspace();

    return [];
  }

  void _setNotifierState(List<McpConnectionState> nextState) {
    _lastKnownState = nextState;
    state = nextState;
  }
}

extension _McpConnectionNotifierContext on McpConnectionNotifier {
  McpServersRepositoryContract get _activeRepository {
    final workspaceId = _activeWorkspaceId;
    if (workspaceId == null) {
      throw StateError('No active workspace for MCP operation');
    }

    return _repositoryFor(workspaceId);
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
}

extension McpConnectionNotifierOperations on McpConnectionNotifier {
  /// Get a connection state by server ID.
  McpConnectionState? getConnection(String serverId) => _currentState
      .where((connection) => connection.hasServerId(serverId))
      .firstOrNull;

  /// Get a ToolSpec for a specific MCP tool by server ID and tool name.
  ///
  /// Returns null if the server is not connected or the tool is not found.
  ToolSpec? getToolSpec({
    required String mcpServerId,
    required String toolName,
  }) => _toolSpec(getConnection(mcpServerId), toolName);

  /// Get the connections that are currently connecting.
  List<McpConnectionState> getConnectingServers(List<String> mcpServerIds) =>
      _currentState
          .where((c) => mcpServerIds.contains(c.server.id))
          .where((c) => c.status == McpConnectionStatus.connecting)
          .toList();

  /// Disconnect from a specific MCP server without deleting.
  void disconnectMcpServer(String serverId) {
    if (_isCloud) return;
    final index = _connectionIndex(serverId);
    if (index == -1) return;

    final connection = _currentState[index];
    _disconnectLocalConnection(serverId, connection);
    _setState(_disconnectedState(index, connection));
  }

  /// Returns when the specified MCP servers have finished connecting.
  Future<void> waitForConnectionsReady({
    required List<String> mcpServerIds,
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? _mcpConnectionTimeout;
    if (mcpServerIds.isEmpty || effectiveTimeout <= .zero) return;

    final ids = mcpServerIds.toSet();
    if (_connectionsReady(ids, _currentState)) return;

    await _waitForConnections(ids, effectiveTimeout);
  }

  /// Delete an MCP server by identifier.
  Future<void> deleteMcpServer(String serverId) async {
    final connection = _currentState.firstWhereOrNull(
      (c) => c.server.id == serverId,
    );
    if (connection != null) _disconnectDeletedConnection(serverId, connection);
    _removeConnection(serverId);
    await _deleteMcpServerRecord(serverId);
  }
}

extension _McpConnectionLookupOperations on McpConnectionNotifier {
  ToolSpec? _toolSpec(McpConnectionState? connection, String toolName) {
    if (connection case final current?
        when current.status == McpConnectionStatus.connected &&
            current.tools.isNotEmpty &&
            (_isCloud || current.client != null)) {
      return _toolInfoSpec(current, toolName);
    }

    return null;
  }

  ToolSpec? _toolInfoSpec(McpConnectionState connection, String toolName) =>
      connection.tools
          .firstWhereOrNull((tool) => tool.toolName == toolName)
          ?._spec(connection.server);

  McpManagerClient _requiredToolClient(
    String mcpServerId,
    String toolIdentifier,
  ) {
    final connection = _requiredConnection(mcpServerId);
    if (!connection.isReady) {
      throw Exception('MCP server not connected: $mcpServerId');
    }
    _ensureToolExists(connection, mcpServerId, toolIdentifier);

    return _requiredClient(connection, mcpServerId);
  }

  McpConnectionState _requiredConnection(String serverId) {
    final connection = getConnection(serverId);
    if (connection == null) throw Exception('MCP server not found: $serverId');

    return connection;
  }

  void _ensureToolExists(
    McpConnectionState connection,
    String serverId,
    String toolIdentifier,
  ) {
    if (connection.hasTool(toolIdentifier)) {
      return;
    }

    throw Exception(
      'Tool "$toolIdentifier" not found on MCP server: $serverId',
    );
  }

  McpManagerClient _requiredClient(
    McpConnectionState connection,
    String serverId,
  ) {
    final client = connection.client;
    if (client == null) {
      throw Exception('MCP server not connected: $serverId');
    }

    return client;
  }
}

extension _McpConnectionStateOperations on McpConnectionNotifier {
  int _connectionIndex(String serverId) => _currentState.indexWhere(
    (connection) => connection.server.id == serverId,
  );

  void _disconnectLocalConnection(
    String serverId,
    McpConnectionState connection,
  ) {
    unawaited(_tokenSubscriptions.remove(serverId)?.cancel());
    _requiredMcpManager.disconnect(connection.client);
  }

  List<McpConnectionState> _disconnectedState(
    int index,
    McpConnectionState connection,
  ) => [
    ..._currentState.sublist(0, index),
    connection.copyWith(status: .disconnected, client: null),
    ..._currentState.sublist(index + 1),
  ];

  bool _connectionsReady(
    Set<String> ids,
    List<McpConnectionState> connections,
  ) => !connections
      .where((connection) => ids.contains(connection.server.id))
      .any((connection) => connection.status == .connecting);

  Future<void> _waitForConnections(Set<String> ids, Duration timeout) async {
    final _ = await _stateController.stream
        .firstWhere(
          (connections) => _connectionsReady(ids, connections),
          orElse: () => const [],
        )
        .timeout(timeout, onTimeout: () => const []);
  }

  Future<void> _addLocalMcpServer(
    McpServerFormToCreate serverToCreate,
    String workspaceId,
  ) async {
    final request = await _prepareLocalMcpAdd(serverToCreate, workspaceId);
    final added = await _connectAndPersistMcp(request);

    await _finishLocalMcpAdd(added, request.manager, workspaceId);
  }

  Future<_LocalMcpAddRequest> _prepareLocalMcpAdd(
    McpServerFormToCreate serverToCreate,
    String workspaceId,
  ) async => _localMcpAddRequest(
    await _prepareLocalMcpInput(serverToCreate, workspaceId),
  );

  Future<_LocalMcpAddInput> _prepareLocalMcpInput(
    McpServerFormToCreate serverToCreate,
    String workspaceId,
  ) async {
    final serverInfo = await _buildMcpServerInfo(serverToCreate);
    final serviceConnection = await _prepareMcpServiceConnection(
      workspaceId,
      serverInfo,
    );

    return (
      manager: _requiredMcpManager,
      serverInfo: serverInfo,
      serviceConnectionRepository: serviceConnection.repository,
      workspaceId: workspaceId,
      serviceConnectionId: serviceConnection.id,
    );
  }
}

extension _McpServiceConnectionAddOperations on McpConnectionNotifier {
  Future<_McpServiceConnectionAdd> _prepareMcpServiceConnection(
    String workspaceId,
    McpServerToCreate serverInfo,
  ) async {
    final repository = _notifierRef.read(serviceConnectionRepositoryProvider);
    final id = await _createMcpServiceConnection(
      repository,
      workspaceId,
      serverInfo,
    );

    return (repository: repository, id: id);
  }
}

extension _McpConnectionAddOperations on McpConnectionNotifier {
  _LocalMcpAddRequest _localMcpAddRequest(_LocalMcpAddInput input) => (
    manager: input.manager,
    serverInfo: input.serverInfo,
    serverForPersistence: input.serverInfo.copyWith(
      serviceConnectionId: input.serviceConnectionId,
    ),
    workspaceId: input.workspaceId,
    serviceConnectionId: input.serviceConnectionId,
    serviceConnectionRepository: input.serviceConnectionRepository,
  );

  Future<McpServerToCreate> _buildMcpServerInfo(McpServerFormToCreate server) =>
      BuildMcpServerToCreateUseCase(
        authenticator: .new(
          callbackUrlScheme: 'me-auravibes',
          clientName: 'Aura Vibes MCP Client',
        ),
      ).call(server);

  Future<String?> _createMcpServiceConnection(
    ServiceConnectionRepository serviceConnectionRepository,
    String workspaceId,
    McpServerToCreate serverInfo,
  ) => serviceConnectionRepository.createMcpServiceConnection(
    workspaceId: workspaceId,
    profile: .new(
      name: serverInfo.name,
      authenticationType: serverInfo.authenticationType,
    ),
  );

  Future<_AddedMcpServer> _connectAndPersistMcp(
    _LocalMcpAddRequest request,
  ) async {
    McpManagerClient? client;
    try {
      client = await _connectMcpClientForAdd(request);

      return await _persistMcpAdd(request, client);
    } on Object {
      await _cleanupFailedMcpAdd(_mcpAddCleanup(request, client));
      rethrow;
    }
  }

  Future<McpManagerClient> _connectMcpClientForAdd(
    _LocalMcpAddRequest request,
  ) => request.manager.connectMcp(request.serverInfo);

  Future<_AddedMcpServer> _persistMcpAdd(
    _LocalMcpAddRequest request,
    McpManagerClient client,
  ) async {
    final tools = await request.manager.getTools(client);
    final server = await _persistMcpServer(request, tools);

    return (
      server: server,
      tools: tools,
      client: client,
      serviceConnectionId: request.serviceConnectionId,
    );
  }

  Future<McpServerEntity> _persistMcpServer(
    _LocalMcpAddRequest request,
    List<McpToolInfo> tools,
  ) => _repositoryFor(request.workspaceId).addMcpServerWithTools(
    workspaceId: request.workspaceId,
    serverToCreate: request.serverForPersistence,
    tools: tools,
  );

  Future<void> _finishLocalMcpAdd(
    _AddedMcpServer added,
    McpManagerService manager,
    String workspaceId,
  ) async {
    if (_isDisposed) {
      manager.disconnect(added.client);

      return;
    }
    _listenTokenUpdates(
      serverId: added.server.id,
      serviceConnectionId: added.serviceConnectionId,
      client: added.client,
    );
    _appendConnectedMcp(added);
    _notifierRef.invalidate(workspaceToolsProvider(workspaceId));
  }
}

extension _McpAddCleanupInputOperations on McpConnectionNotifier {
  _McpAddCleanup _mcpAddCleanup(
    _LocalMcpAddRequest request,
    McpManagerClient? client,
  ) => (
    manager: request.manager,
    serviceConnectionRepository: request.serviceConnectionRepository,
    client: client,
    serviceConnectionId: request.serviceConnectionId,
  );
}

extension _McpConnectionCleanupOperations on McpConnectionNotifier {
  void _appendConnectedMcp(_AddedMcpServer added) {
    _setState([
      ..._currentState,
      McpConnectionState(
        server: added.server,
        status: .connected,
        client: added.client,
        tools: added.tools,
      ),
    ]);
  }

  Future<void> _cleanupFailedMcpAdd(_McpAddCleanup cleanup) async {
    if (cleanup.client case final client?) {
      cleanup.manager.disconnect(client);
    }
    if (cleanup.serviceConnectionId case final serviceConnectionId?) {
      await cleanup.serviceConnectionRepository.deleteOwnedMcpCredential(
        serviceConnectionId,
      );
    }
  }

  void _disconnectDeletedConnection(
    String serverId,
    McpConnectionState connection,
  ) {
    unawaited(_tokenSubscriptions.remove(serverId)?.cancel());
    _mcpManagerService?.disconnect(connection.client);
  }

  void _removeConnection(String serverId) {
    _setState(
      _currentState
          .where((connection) => connection.server.id != serverId)
          .toList(),
    );
  }

  Future<void> _deleteMcpServerRecord(String serverId) async {
    final _ = await _activeRepository.deleteMcpServer(serverId);
  }

  Future<bool> _reconnectExistingMcp(String serverId) async {
    final connection = getConnection(serverId);
    if (connection == null) return false;

    unawaited(_tokenSubscriptions.remove(serverId)?.cancel());
    _requiredMcpManager.disconnect(connection.client);
    await _connectToMcp(connection.server);

    return true;
  }

  Future<void> _reconnectStoredMcp(String serverId) async {
    final server = await _activeRepository.getMcpServerById(serverId);
    if (server != null) await _connectToMcp(server);
  }

  void _resetBuildState() {
    _isDisposed = false;
    _lastKnownState = const [];
    if (_stateController.isClosed) {
      _stateController = StreamController<List<McpConnectionState>>.broadcast(
        sync: true,
      );
    }
  }
}

extension _McpConnectionLoadOperations on McpConnectionNotifier {
  void _listenForWorkspaceChanges() {
    _notifierRef
      ..onDispose(_onDispose)
      ..listen<String?>(
        currentRouteWorkspaceIdProvider,
        _handleWorkspaceChange,
      );
  }

  void _handleWorkspaceChange(String? previous, String? next) {
    if (next == null || next == previous) return;

    unawaited(_loadMcpsForWorkspace(next));
  }

  void _loadInitialWorkspace() {
    final initialWorkspaceId = _notifierRef.read(
      currentRouteWorkspaceIdProvider,
    );
    if (initialWorkspaceId != null) {
      unawaited(_loadMcpsForWorkspace(initialWorkspaceId));
    }
  }

  // ============================================================.
  // Private: Database Operations.
  // ============================================================.

  /// Load enabled MCPs only for the active workspace.
  Future<void> _loadMcpsForWorkspace(String workspaceId) async {
    try {
      await _loadWorkspaceMcpServers(workspaceId);
    } on Exception catch (e, stackTrace) {
      _logger.warning(
        'Failed to load MCP servers from database',
        e,
        stackTrace,
      );
    }
  }

  Future<void> _loadWorkspaceMcpServers(String workspaceId) async {
    _prepareWorkspace(workspaceId);
    if (_isDisposed) return;

    final servers = await _enabledServers(workspaceId);
    if (_isDisposed) return;

    await _loadMcpServers(servers);
  }

  void _prepareWorkspace(String workspaceId) {
    _activeWorkspaceId = workspaceId;
    final repository = _repositoryFor(workspaceId);
    _isCloud = repository is CloudToolsRepository;
    _mcpManagerService = _isCloud
        ? null
        : _notifierRef.read(mcpManagerServiceProvider);
  }

  Future<List<McpServerEntity>> _enabledServers(String workspaceId) =>
      _repositoryFor(workspaceId).getEnabledMcpServersForWorkspace(workspaceId);

  Future<void> _loadMcpServers(List<McpServerEntity> servers) async {
    for (final server in servers) {
      if (_isDisposed) return;

      await _loadMcpServer(server);
    }
  }
}

extension _McpConnectionServerLoadOperations on McpConnectionNotifier {
  Future<void> _loadMcpServer(McpServerEntity server) async {
    if (getConnection(server.id) case final existingConnection?
        when existingConnection.isReady ||
            existingConnection.status == McpConnectionStatus.connecting) {
      return;
    }

    if (_isCloud) {
      await _discoverCloudMcp(server.id, server: server);
    } else {
      await _connectToMcp(server);
    }
  }
}

extension _McpConnectionManagementOperations on McpConnectionNotifier {
  // ============================================================.
  // Private: Connection Management.
  // ============================================================.

  /// Connect to an MCP server.
  Future<void> _connectToMcp(McpServerEntity server) async {
    if (_isDisposed) return;
    _setConnectingState(server);

    await _connectMcpAndHandleErrors(server);
  }

  Future<void> _connectMcpAndHandleErrors(McpServerEntity server) async {
    McpManagerClient? connectedClient;
    try {
      connectedClient = await _connectMcpClient(server);
      await _completeMcpConnection(server, connectedClient);
      connectedClient = null;
    } on Exception catch (error, stackTrace) {
      _setConnectionError(server, error, stackTrace);
    } finally {
      _disconnectClient(connectedClient);
    }
  }

  Future<void> _completeMcpConnection(
    McpServerEntity server,
    McpManagerClient client,
  ) async {
    final tools = await _requiredMcpManager.getTools(client);
    if (_isDisposed) return;

    _setConnectedState(server, client, tools);
    await _syncMcpToolsToDatabase(server, tools);
  }

  void _setConnectingState(McpServerEntity server) {
    final index = _connectionIndex(server.id);
    if (index < 0) {
      _appendConnectingState(server);

      return;
    }
    _replaceConnectingState(index);
  }

  void _appendConnectingState(McpServerEntity server) {
    _setState([
      ..._currentState,
      McpConnectionState(server: server, status: .connecting),
    ]);
  }

  void _replaceConnectingState(int index) {
    _setState([
      ..._currentState.sublist(0, index),
      _currentState[index].copyWith(status: .connecting, errorMessage: null),
      ..._currentState.sublist(index + 1),
    ]);
  }

  Future<McpManagerClient> _connectMcpClient(McpServerEntity server) async {
    final authenticationType = await _notifierRef
        .read(oauthCredentialServiceProvider)
        .resolveMcpAuthentication(server.serviceConnectionId);

    return await _requiredMcpManager.connectMcp(
      server.copyWith(authenticationType: authenticationType),
    );
  }
}

extension _McpConnectionResultOperations on McpConnectionNotifier {
  void _setConnectedState(
    McpServerEntity server,
    McpManagerClient client,
    List<McpToolInfo> tools,
  ) {
    _listenTokenUpdates(
      serverId: server.id,
      serviceConnectionId: server.serviceConnectionId,
      client: client,
    );
    _updateConnectionState(
      server.id,
      (connection) => _connectedState(connection, client, tools),
    );
  }

  McpConnectionState _connectedState(
    McpConnectionState connection,
    McpManagerClient client,
    List<McpToolInfo> tools,
  ) => connection.copyWith(
    status: .connected,
    client: client,
    tools: tools,
    errorMessage: null,
  );

  void _setConnectionError(
    McpServerEntity server,
    Exception error,
    StackTrace stackTrace,
  ) {
    _logConnectionError(server, error, stackTrace);
    _updateConnectionState(server.id, _connectionErrorState);
  }

  void _logConnectionError(
    McpServerEntity server,
    Exception error,
    StackTrace stackTrace,
  ) {
    _logger.warning(
      'MCP server connection failed: server=${server.id}',
      error,
      stackTrace,
    );
  }

  McpConnectionState _connectionErrorState(McpConnectionState connection) =>
      connection.copyWith(
        status: .error,
        client: null,
        tools: [],
        errorMessage: LocaleKeys.tools_screen_mcp_error,
      );

  void _disconnectClient(McpManagerClient? client) {
    if (client != null) _requiredMcpManager.disconnect(client);
  }

  /// Update a connection state by server ID.
  void _updateConnectionState(
    String serverId,
    McpConnectionState Function(McpConnectionState) updater,
  ) {
    if (_isDisposed) {
      return;
    }

    final index = _currentState.indexWhere((c) => c.server.id == serverId);
    if (index == -1) return;

    _setState([
      ..._currentState.sublist(0, index),
      updater(_currentState[index]),
      ..._currentState.sublist(index + 1),
    ]);
  }
}

extension _McpConnectionLifecycleOperations on McpConnectionNotifier {
  void _onDispose() {
    _isDisposed = true;
    _disposeAllConnections();
    unawaited(_stateController.close());
  }

  void _listenTokenUpdates({
    required String serverId,
    required String? serviceConnectionId,
    required McpManagerClient client,
  }) {
    final tokenUpdates = client.onTokenUpdate;
    if (serviceConnectionId == null || tokenUpdates == null) return;
    unawaited(_tokenSubscriptions.remove(serverId)?.cancel());
    _tokenSubscriptions[serverId] = _subscribeTokenUpdates(
      tokenUpdates,
      serviceConnectionId,
    );
  }

  StreamSubscription<OAuthTokenEntity> _subscribeTokenUpdates(
    Stream<OAuthTokenEntity> tokenUpdates,
    String serviceConnectionId,
  ) => tokenUpdates.listen(
    (token) => _persistTokenUpdate(serviceConnectionId, token),
  );

  void _persistTokenUpdate(String serviceConnectionId, OAuthTokenEntity token) {
    unawaited(
      _notifierRef
          .read(oauthCredentialServiceProvider)
          .persistOAuthTokenUpdate(
            serviceConnectionId: serviceConnectionId,
            token: token,
          ),
    );
  }

  void _setState(List<McpConnectionState> nextState) {
    _setNotifierState(nextState);
  }

  // ============================================================.
  // Private: Tool Synchronization.
  // ============================================================.

  /// Sync MCP tools to the database.
  ///
  /// Uses the repository's syncMcpTools method to add new tools, remove tools
  /// no longer on the MCP server, and preserve user customizations such as
  /// isEnabled and permissions.
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
      _logger.warning('Failed to sync MCP tools to database', e, stackTrace);
    }
  }

  McpServersRepositoryContract _repositoryFor(String workspaceId) {
    final session = _notifierRef
        .read(workspaceSessionForRouteProvider(workspaceId))
        .requireValue;

    return _notifierRef.read(mcpServersRepositoryProvider(session));
  }
}

extension _McpConnectionCloudOperations on McpConnectionNotifier {
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
    _notifierRef.invalidate(workspaceToolsProvider(workspaceId));
  }

  Future<void> _discoverCloudMcp(
    String serverId, {
    McpServerEntity? server,
  }) async {
    final resolvedServer = await _resolveCloudMcpServer(serverId, server);
    if (resolvedServer == null || _isDisposed) return;
    _upsertConnection(
      .new(server: resolvedServer, status: McpConnectionStatus.connecting),
    );
    await _performCloudDiscovery(serverId, resolvedServer);
  }

  Future<void> _performCloudDiscovery(
    String serverId,
    McpServerEntity server,
  ) async {
    try {
      final discovery = await _cloudRepository.discoverMcpServer(serverId);
      if (_isDisposed) return;
      _setCloudDiscovery(server, discovery);
    } on Exception catch (error, stackTrace) {
      _handleCloudDiscoveryError((
        serverId: serverId,
        server: server,
        error: error,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<McpServerEntity?> _resolveCloudMcpServer(
    String serverId,
    McpServerEntity? server,
  ) async => server ?? await _cloudRepository.getMcpServerById(serverId);

  void _handleCloudDiscoveryError(_CloudDiscoveryError details) {
    if (_isDisposed) return;
    _logger.warning(
      'MCP server cloud discovery failed: server=${details.serverId}',
      details.error,
      details.stackTrace,
    );
    _upsertConnection(
      .new(
        server: details.server,
        status: .error,
        errorMessage: LocaleKeys.tools_screen_mcp_error,
      ),
    );
  }

  void _setCloudDiscovery(
    McpServerEntity server,
    DiscoverMcpServerResult discovery,
  ) {
    final connected = discovery.health == McpServerHealth.healthy;
    _upsertConnection(
      .new(
        server: server,
        status: _cloudConnectionStatus(connected),
        tools: _cloudTools(discovery),
        errorMessage: connected ? null : discovery.errorCode,
      ),
    );
  }

  McpConnectionStatus _cloudConnectionStatus(bool connected) =>
      connected ? .connected : .error;

  List<McpToolInfo> _cloudTools(DiscoverMcpServerResult discovery) => [
    for (final tool in discovery.tools)
      McpToolInfo(
        toolName: tool.name,
        description: tool.description ?? '',
        inputSchema: jsonDecode(tool.inputSchemaJson) as Map<String, dynamic>,
      ),
  ];
}

extension _McpConnectionCloudStateOperations on McpConnectionNotifier {
  void _upsertConnection(McpConnectionState connection) {
    final index = _currentState.indexWhere(
      (item) => item.server.id == connection.server.id,
    );
    if (index < 0) {
      _appendConnection(connection);

      return;
    }
    _replaceConnection(index, connection);
  }

  void _appendConnection(McpConnectionState connection) {
    _setState([..._currentState, connection]);
  }

  void _replaceConnection(int index, McpConnectionState connection) {
    _setState([
      ..._currentState.sublist(0, index),
      connection,
      ..._currentState.sublist(index + 1),
    ]);
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
}

@Riverpod(keepAlive: true)
McpManagerService mcpManagerService(Ref _) {
  return McpManagerService();
}
