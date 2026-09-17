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
import 'package:auravibes_app/services/log_redaction.dart';
import 'package:auravibes_app/services/mcp_service/mcp_manager_client.dart';
import 'package:auravibes_app/services/mcp_service/oauth_authentication_canceled_exception.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/v7.dart';

part 'mcp_connection_status.freezed.dart';
part 'mcp_connection_status.g.dart';

final _logger = Logger('McpConnectionNotifier');

const Duration _mcpConnectionTimeout = .new(seconds: 10);
const Duration _mcpVerificationLifetime = .new(minutes: 5);

typedef McpConnectionVerification = ({
  String id,
  int toolCount,
  DateTime expiresAt,
});

typedef _AddedMcpServer = ({
  McpServerEntity server,
  List<McpToolInfo> tools,
  McpManagerClient client,
});

typedef _LocalMcpAddRequest = ({
  McpManagerService manager,
  McpServerToCreate serverInfo,
  McpServerToCreate serverForPersistence,
  String workspaceId,
  String? serviceConnectionId,
  ServiceConnectionRepository serviceConnectionRepository,
});

typedef _McpPrepareRequest = ({
  String id,
  String fingerprint,
  String workspaceId,
});

typedef _McpLocalPreparedData = ({
  McpManagerService manager,
  McpServerToCreate serverInfo,
  McpManagerClient client,
  List<McpToolInfo> tools,
  OAuthTokenEntity? latestOAuthToken,
  StreamSubscription<OAuthTokenEntity>? tokenSubscription,
});

typedef _McpConnectedLocalRequest = ({
  _McpPrepareRequest request,
  McpManagerService manager,
  McpServerToCreate serverInfo,
  McpManagerClient client,
});

typedef _McpLocalPreparedRequest = ({
  _McpConnectedLocalRequest request,
  _McpPreparedTokenBuffer buffer,
  StreamSubscription<OAuthTokenEntity>? tokenSubscription,
  List<McpToolInfo> tools,
});

typedef _McpTokenPreparation = ({
  _McpPreparedTokenBuffer buffer,
  StreamSubscription<OAuthTokenEntity>? subscription,
});

typedef _PreparedMcpConnectionData = ({
  String id,
  String workspaceId,
  String fingerprint,
  DateTime verifiedAt,
  DateTime expiresAt,
  McpManagerService? manager,
  McpServerToCreate? serverInfo,
  McpManagerClient? client,
  List<McpToolInfo> tools,
  String? verificationReceipt,
});

typedef _McpCloudVerification = ({
  DiscoverMcpServerResult discovery,
  String verificationReceipt,
  DateTime expiresAt,
});

class _McpPreparedTokenBuffer {
  new(this._persist, this.latestOAuthToken);

  OAuthTokenEntity? latestOAuthToken;
  _PreparedMcpConnection? session;
  final void Function(String, OAuthTokenEntity) _persist;

  void update(OAuthTokenEntity token) {
    latestOAuthToken = token;
    session?.latestOAuthToken = token;
    final persistenceId = session?.tokenPersistenceId;
    if (persistenceId != null) _persist(persistenceId, token);
  }
}

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

class _PreparedMcpConnection {
  new(_PreparedMcpConnectionData data)
    : id = data.id,
      workspaceId = data.workspaceId,
      fingerprint = data.fingerprint,
      verifiedAt = data.verifiedAt,
      expiresAt = data.expiresAt,
      manager = data.manager,
      serverInfo = data.serverInfo,
      client = data.client,
      tools = data.tools,
      verificationReceipt = data.verificationReceipt;

  final String id;
  final String workspaceId;
  final String fingerprint;
  final DateTime verifiedAt;
  final DateTime expiresAt;
  final McpManagerService? manager;
  final McpServerToCreate? serverInfo;
  final McpManagerClient? client;
  final List<McpToolInfo> tools;
  final String? verificationReceipt;

  OAuthTokenEntity? latestOAuthToken;
  String? tokenPersistenceId;
  StreamSubscription<OAuthTokenEntity>? tokenSubscription;
  String? cloudCreateRequestId;
  String? cloudCommitFingerprint;

  Future<void> close() async {
    await tokenSubscription?.cancel();
    tokenSubscription = null;
    tokenPersistenceId = null;
    await manager?.disconnect(client);
  }
}

class const McpVerificationRequiredException() implements Exception;

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
  final _preparedMcpConnections = <String, _PreparedMcpConnection>{};
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

  /// Prepare an MCP connection without persisting its configuration or tools.
  Future<McpConnectionVerification> prepareMcpConnection(
    McpServerFormToCreate serverToCreate, {
    required String workspaceId,
    void Function(McpOAuthDeviceCode deviceCode)? onOAuthDeviceCode,
    bool Function()? isOAuthCancelled,
  }) async {
    _prepareWorkspace(workspaceId);
    await _discardPreparedMcpConnectionsForWorkspace(workspaceId);

    final request = (
      id: const UuidV7().generate(),
      fingerprint: _mcpConnectionFingerprint(serverToCreate),
      workspaceId: workspaceId,
    );
    if (_isCloud) {
      return await _prepareCloudMcpConnection(request, serverToCreate);
    }

    return await _prepareLocalMcpConnection(
      request,
      serverToCreate,
      onOAuthDeviceCode: onOAuthDeviceCode,
      isOAuthCancelled: isOAuthCancelled,
    );
  }

  /// Persist a previously prepared MCP connection.
  Future<void> commitPreparedMcpConnection(
    McpServerFormToCreate serverToCreate, {
    required String workspaceId,
    required String verificationId,
  }) async {
    _prepareWorkspace(workspaceId);
    final session = await _requiredPreparedMcpConnection(
      verificationId,
      serverToCreate,
      workspaceId,
    );
    if (_isCloud) {
      await _commitCloudPreparedMcpConnection(
        session,
        serverToCreate,
        workspaceId,
      );

      return;
    }
    await _commitLocalPreparedMcpConnection(
      session,
      serverToCreate,
      workspaceId,
    );
  }

  /// Discard an in-memory MCP verification and its live client.
  Future<void> discardPreparedMcpConnection(String verificationId) async {
    final session = _preparedMcpConnections.remove(verificationId);
    if (session == null) return;

    final _ = await session.close();
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

  /// Disconnect from a specific MCP server without deleting.
  void disconnectMcpServer(String serverId) {
    if (_isCloud) return;
    final index = _connectionIndex(serverId);
    if (index == -1) return;

    final connection = _currentState[index];
    _disconnectLocalConnection(serverId, connection);
    _setState(_disconnectedState(index, connection));
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
}

extension _McpPreparedConnectionOperations on McpConnectionNotifier {
  Future<void> _discardPreparedMcpConnectionsForWorkspace(
    String workspaceId,
  ) async {
    final ids = _preparedMcpConnections.values
        .where((session) => session.workspaceId == workspaceId)
        .map((session) => session.id)
        .toList();
    for (final id in ids) {
      await discardPreparedMcpConnection(id);
    }
  }

  Future<_PreparedMcpConnection> _requiredPreparedMcpConnection(
    String verificationId,
    McpServerFormToCreate serverToCreate,
    String workspaceId,
  ) async {
    final session = _preparedMcpConnections[verificationId];
    if (session == null ||
        !_preparedSessionMatches(session, serverToCreate, workspaceId)) {
      await discardPreparedMcpConnection(verificationId);
      throw const McpVerificationRequiredException();
    }

    return session;
  }

  bool _preparedSessionMatches(
    _PreparedMcpConnection session,
    McpServerFormToCreate server,
    String workspaceId,
  ) =>
      DateTime.now().toUtc().isBefore(session.expiresAt) &&
      session.workspaceId == workspaceId &&
      session.fingerprint == _mcpConnectionFingerprint(server);

  Future<void> _completePreparedMcpConnection(String verificationId) async {
    final session = _preparedMcpConnections.remove(verificationId);
    final _ = await session?.tokenSubscription?.cancel();
    if (session != null) session.tokenSubscription = null;
  }

  void _adoptPreparedTokenUpdates(
    _PreparedMcpConnection session, {
    required String serverId,
    required String? serviceConnectionId,
  }) {
    if (serviceConnectionId == null) return;
    final subscription = session.tokenSubscription;
    if (subscription == null) return;
    session.tokenPersistenceId = serviceConnectionId;
    _tokenSubscriptions[serverId] = subscription;
    session.tokenSubscription = null;
  }
}

extension _McpPreparationOperations on McpConnectionNotifier {
  Future<McpConnectionVerification> _prepareCloudMcpConnection(
    _McpPrepareRequest request,
    McpServerFormToCreate server,
  ) async {
    final verification = await _cloudRepository.verifyMcpServer(
      workspaceId: request.workspaceId,
      server: server,
    );
    if (_isDisposed) throw const McpVerificationRequiredException();

    final session = _storePreparedCloudMcpConnection(
      request,
      server,
      verification,
    );

    return _mcpVerificationSummary(session);
  }

  Future<McpConnectionVerification> _prepareLocalMcpConnection(
    _McpPrepareRequest request,
    McpServerFormToCreate server, {
    void Function(McpOAuthDeviceCode deviceCode)? onOAuthDeviceCode,
    bool Function()? isOAuthCancelled,
  }) async {
    final manager = _requiredMcpManager;
    final serverInfo = await _buildMcpServerInfo(
      server,
      onOAuthDeviceCode: onOAuthDeviceCode,
      isOAuthCancelled: isOAuthCancelled,
    );

    return await _connectPreparedLocalMcp(request, manager, serverInfo);
  }

  Future<McpConnectionVerification> _connectPreparedLocalMcp(
    _McpPrepareRequest request,
    McpManagerService manager,
    McpServerToCreate serverInfo,
  ) async {
    McpManagerClient? client;
    try {
      client = await manager.connectMcp(serverInfo);
      final verification = await _prepareConnectedLocalMcp((
        request: request,
        manager: manager,
        serverInfo: serverInfo,
        client: client,
      ));
      client = null;

      return verification;
    } finally {
      await manager.disconnect(client);
    }
  }

  Future<McpConnectionVerification> _prepareConnectedLocalMcp(
    _McpConnectedLocalRequest request,
  ) async {
    final tokenPreparation = _prepareLocalTokenUpdates(request);
    try {
      final tools = await _fetchPreparedLocalTools(request);

      final session = _storePreparedLocalMcpConnection((
        request: request,
        buffer: tokenPreparation.buffer,
        tokenSubscription: tokenPreparation.subscription,
        tools: tools,
      ));

      return _mcpVerificationSummary(session);
    } on Object {
      await tokenPreparation.subscription?.cancel();
      rethrow;
    }
  }

  _PreparedMcpConnection _storePreparedCloudMcpConnection(
    _McpPrepareRequest request,
    McpServerFormToCreate server,
    _McpCloudVerification verification,
  ) {
    final session = _PreparedMcpConnection(
      _cloudPreparedConnectionData(request, verification),
    )..cloudCommitFingerprint = _mcpCommitFingerprint(server);
    _preparedMcpConnections[request.id] = session;

    return session;
  }

  _PreparedMcpConnection _storePreparedLocalMcpConnection(
    _McpLocalPreparedRequest data,
  ) {
    final session = _newPreparedLocalSession(
      data.request.request,
      _mcpLocalPreparedData(data),
    );
    data.buffer.session = session;
    _preparedMcpConnections[data.request.request.id] = session;

    return session;
  }

  _PreparedMcpConnection _newPreparedLocalSession(
    _McpPrepareRequest request,
    _McpLocalPreparedData data,
  ) {
    final verifiedAt = DateTime.now().toUtc();

    return _PreparedMcpConnection(
        _localPreparedConnectionData(request, data, verifiedAt),
      )
      ..latestOAuthToken = data.latestOAuthToken
      ..tokenSubscription = data.tokenSubscription;
  }

  _PreparedMcpConnectionData _cloudPreparedConnectionData(
    _McpPrepareRequest request,
    _McpCloudVerification verification,
  ) => (
    id: request.id,
    workspaceId: request.workspaceId,
    fingerprint: request.fingerprint,
    verifiedAt: DateTime.now().toUtc(),
    expiresAt: verification.expiresAt,
    manager: null,
    serverInfo: null,
    client: null,
    tools: _cloudTools(verification.discovery),
    verificationReceipt: verification.verificationReceipt,
  );

  _PreparedMcpConnectionData _localPreparedConnectionData(
    _McpPrepareRequest request,
    _McpLocalPreparedData data,
    DateTime verifiedAt,
  ) => (
    id: request.id,
    workspaceId: request.workspaceId,
    fingerprint: request.fingerprint,
    verifiedAt: verifiedAt,
    expiresAt: verifiedAt.add(_mcpVerificationLifetime),
    manager: data.manager,
    serverInfo: data.serverInfo,
    client: data.client,
    tools: data.tools,
    verificationReceipt: null,
  );

  OAuthTokenEntity? _initialOAuthToken(McpServerToCreate server) =>
      switch (server.authenticationType) {
        McpAuthenticationTypeOAuth(:final token) => token,
        McpAuthenticationTypeNone() ||
        McpAuthenticationTypeBearerToken() => null,
      };
}

extension _McpLocalPreparationSupportOperations on McpConnectionNotifier {
  _McpTokenPreparation _prepareLocalTokenUpdates(
    _McpConnectedLocalRequest request,
  ) {
    final buffer = _McpPreparedTokenBuffer(
      _persistTokenUpdate,
      _initialOAuthToken(request.serverInfo),
    );

    return (
      buffer: buffer,
      subscription: request.client.onTokenUpdate?.listen(buffer.update),
    );
  }

  Future<List<McpToolInfo>> _fetchPreparedLocalTools(
    _McpConnectedLocalRequest request,
  ) async {
    final tools = await request.manager.getTools(request.client);
    if (_isDisposed) throw const McpVerificationRequiredException();

    return tools;
  }
}

String _mcpConnectionFingerprint(McpServerFormToCreate server) {
  final bearerToken = server.bearerToken?.trim() ?? '';

  return jsonEncode({
    'url': server.url.trim(),
    'transport': server.transport.toJson(),
    'authenticationType': server.authenticationType.name,
    'bearerTokenDigest': sha256.convert(utf8.encode(bearerToken)).toString(),
    'oauthClientId': server.oauthClientId?.trim() ?? '',
  });
}

McpConnectionVerification _mcpVerificationSummary(
  _PreparedMcpConnection session,
) => (
  id: session.id,
  toolCount: session.tools.length,
  expiresAt: session.expiresAt,
);

_McpLocalPreparedData _mcpLocalPreparedData(_McpLocalPreparedRequest data) {
  final request = data.request;

  return (
    manager: request.manager,
    serverInfo: request.serverInfo,
    client: request.client,
    tools: data.tools,
    latestOAuthToken: data.buffer.latestOAuthToken,
    tokenSubscription: data.tokenSubscription,
  );
}

McpAuthenticationType _preparedMcpAuthentication(
  McpAuthenticationType authenticationType,
  OAuthTokenEntity? latestToken,
) {
  if (authenticationType case final McpAuthenticationTypeOAuth oauth
      when latestToken != null) {
    return oauth.copyWith(token: latestToken);
  }

  return authenticationType;
}

extension _McpConnectionAddOperations on McpConnectionNotifier {
  Future<McpServerToCreate> _buildMcpServerInfo(
    McpServerFormToCreate server, {
    void Function(McpOAuthDeviceCode deviceCode)? onOAuthDeviceCode,
    bool Function()? isOAuthCancelled,
  }) => BuildMcpServerToCreateUseCase(
    authenticator: .new(
      callbackUrlScheme: 'me-auravibes',
      clientName: 'Aura Vibes MCP Client',
    ),
    onDeviceCode: onOAuthDeviceCode,
    isOAuthCancelled: isOAuthCancelled,
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

  Future<McpServerEntity> _persistMcpServer(
    _LocalMcpAddRequest request,
    List<McpToolInfo> tools,
  ) => _repositoryFor(request.workspaceId).addMcpServerWithTools(
    workspaceId: request.workspaceId,
    serverToCreate: request.serverForPersistence,
    tools: tools,
  );

  Future<void> _commitLocalPreparedMcpConnection(
    _PreparedMcpConnection session,
    McpServerFormToCreate serverToCreate,
    String workspaceId,
  ) async {
    final manager = session.manager;
    final client = session.client;
    if (manager == null || client == null) {
      throw const McpVerificationRequiredException();
    }
    final request = await _createLocalMcpAddRequest(
      session,
      manager,
      serverToCreate,
      workspaceId,
    );
    await _persistLocalPreparedMcpConnection(session, request, client);
  }

  Future<_LocalMcpAddRequest> _createLocalMcpAddRequest(
    _PreparedMcpConnection session,
    McpManagerService manager,
    McpServerFormToCreate serverToCreate,
    String workspaceId,
  ) async {
    final serverInfo = _preparedServerInfo(session, serverToCreate);
    final repository = _notifierRef.read(serviceConnectionRepositoryProvider);
    final serviceConnectionId = await _createMcpServiceConnection(
      repository,
      workspaceId,
      serverInfo,
    );

    return (
      manager: manager,
      serverInfo: serverInfo,
      serverForPersistence: serverInfo.copyWith(
        serviceConnectionId: serviceConnectionId,
      ),
      workspaceId: workspaceId,
      serviceConnectionId: serviceConnectionId,
      serviceConnectionRepository: repository,
    );
  }
}

extension _McpConnectionLocalCommitOperations on McpConnectionNotifier {
  Future<void> _persistLocalPreparedMcpConnection(
    _PreparedMcpConnection session,
    _LocalMcpAddRequest request,
    McpManagerClient client,
  ) async {
    McpServerEntity? persistedServer;
    try {
      persistedServer = await _persistPreparedLocalData(session, request);
      await _finishPreparedLocalMcp(session, request, client, persistedServer);
    } on Object {
      session.tokenPersistenceId = null;
      await _cleanupFailedLocalMcpCommit(request, persistedServer);
      rethrow;
    }
  }

  Future<McpServerEntity> _persistPreparedLocalData(
    _PreparedMcpConnection session,
    _LocalMcpAddRequest request,
  ) async {
    if (session.tokenSubscription != null) {
      session.tokenPersistenceId = request.serviceConnectionId;
    }
    _requireLivePreparedConnection();
    await _persistPreparedLocalOAuthToken(session, request);
    final server = await _persistMcpServer(request, session.tools);
    _requireLivePreparedConnection();
    await _persistPreparedLocalOAuthToken(session, request);

    return server;
  }

  Future<void> _persistPreparedLocalOAuthToken(
    _PreparedMcpConnection session,
    _LocalMcpAddRequest request,
  ) => _persistBufferedOAuthToken(
    session,
    request.serviceConnectionRepository,
    request.serviceConnectionId,
    request.serverInfo,
  );

  Future<void> _finishPreparedLocalMcp(
    _PreparedMcpConnection session,
    _LocalMcpAddRequest request,
    McpManagerClient client,
    McpServerEntity server,
  ) async {
    await _finishLocalMcpAdd(
      (server: server, tools: session.tools, client: client),
      request.manager,
      request.workspaceId,
    );
    _adoptPreparedTokenUpdates(
      session,
      serverId: server.id,
      serviceConnectionId: request.serviceConnectionId,
    );
    await _completePreparedMcpConnection(session.id);
  }

  void _requireLivePreparedConnection() {
    if (_isDisposed) throw const McpVerificationRequiredException();
  }

  Future<void> _cleanupFailedLocalMcpCommit(
    _LocalMcpAddRequest request,
    McpServerEntity? persistedServer,
  ) async {
    if (persistedServer != null) {
      final _ = await _repositoryFor(request.workspaceId)
          .deleteMcpServer(persistedServer.id);
    }
    final serviceConnectionId = request.serviceConnectionId;
    if (serviceConnectionId != null) {
      await request.serviceConnectionRepository.deleteOwnedMcpCredential(
        serviceConnectionId,
      );
    }
  }

  McpServerToCreate _preparedServerInfo(
    _PreparedMcpConnection session,
    McpServerFormToCreate serverToCreate,
  ) {
    final serverInfo = session.serverInfo;
    if (serverInfo == null) {
      throw const McpVerificationRequiredException();
    }

    return serverInfo.copyWith(
      name: serverToCreate.name.trim(),
      description: serverToCreate.description?.trim(),
      authenticationType: _preparedMcpAuthentication(
        serverInfo.authenticationType,
        session.latestOAuthToken,
      ),
    );
  }

  Future<void> _persistBufferedOAuthToken(
    _PreparedMcpConnection session,
    ServiceConnectionRepository repository,
    String? serviceConnectionId,
    McpServerToCreate serverInfo,
  ) async {
    if (serviceConnectionId == null) return;
    final authenticationType = serverInfo.authenticationType;
    if (authenticationType is! McpAuthenticationTypeOAuth) return;
    final latestToken = session.latestOAuthToken;
    if (latestToken == null || latestToken == authenticationType.token) return;

    await repository.updateOAuthToken(
      id: serviceConnectionId,
      token: latestToken,
    );
  }

  Future<void> _finishLocalMcpAdd(
    _AddedMcpServer added,
    McpManagerService manager,
    String workspaceId,
  ) async {
    if (_isDisposed) {
      await manager.disconnect(added.client);
      throw const McpVerificationRequiredException();
    }
    _appendConnectedMcp(added);
    _notifierRef.invalidate(workspaceToolsProvider(workspaceId));
  }
}

String _mcpCommitFingerprint(McpServerFormToCreate server) => jsonEncode({
  'name': server.name.trim(),
  'description': server.description?.trim(),
});

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
      LogRedaction.redact(error.toString()),
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
  Future<void> _commitCloudPreparedMcpConnection(
    _PreparedMcpConnection session,
    McpServerFormToCreate server,
    String workspaceId,
  ) async {
    final verificationReceipt = session.verificationReceipt;
    if (verificationReceipt == null) {
      throw const McpVerificationRequiredException();
    }
    final requestId = _cloudCommitRequestId(session, server);
    final result = await _cloudRepository.createMcpServer(
      workspaceId: workspaceId,
      server: server,
      requestId: requestId,
      verificationReceipt: verificationReceipt,
    );
    await _completeCloudPreparedMcpConnection(session, result, workspaceId);
  }

  Future<void> _completeCloudPreparedMcpConnection(
    _PreparedMcpConnection session,
    ({McpServerEntity server, DiscoverMcpServerResult discovery}) result,
    String workspaceId,
  ) async {
    if (_isDisposed) return;
    _setCloudDiscovery(result.server, result.discovery);
    await _completePreparedMcpConnection(session.id);
    _notifierRef.invalidate(workspaceToolsProvider(workspaceId));
  }

  String _cloudCommitRequestId(
    _PreparedMcpConnection session,
    McpServerFormToCreate server,
  ) {
    final fingerprint = _mcpCommitFingerprint(server);
    if (session.cloudCommitFingerprint != fingerprint ||
        session.cloudCreateRequestId == null) {
      session
        ..cloudCreateRequestId = const UuidV7().generate()
        ..cloudCommitFingerprint = fingerprint;
    }

    return session.cloudCreateRequestId ??
        (throw const McpVerificationRequiredException());
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
    if (manager != null) {
      for (final connection in _lastKnownState) {
        manager.disconnect(connection.client);
      }
    }
    for (final subscription in _tokenSubscriptions.values) {
      unawaited(subscription.cancel());
    }
    _tokenSubscriptions.clear();
    for (final id in _preparedMcpConnections.keys.toList()) {
      unawaited(discardPreparedMcpConnection(id));
    }
  }
}

@Riverpod(keepAlive: true)
McpManagerService mcpManagerService(Ref _) {
  return McpManagerService();
}
