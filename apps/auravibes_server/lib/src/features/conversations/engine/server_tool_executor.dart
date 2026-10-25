import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../agents/agent_catalog_repository.dart';
import '../../agents/agent_catalog_use_cases.dart';
import '../../mcp_servers/mcp_oauth_token_resolver.dart';
import '../../mcp_servers/mcp_server_headers.dart';
import '../../mcp_servers/mcp_server_policy.dart';
import '../../mcp_servers/mcp_sse_session.dart';
import '../../mcp_servers/pinned_http_client.dart';
import '../../skills/repositories/skill_resource_repository.dart';
import '../../sync/stream/sync_wakeups.dart';
import '../../workspace_state/repositories/workspace_state_repository.dart';
import '../../workspace_state/usecases/workspace_connector_access_usecases.dart';
import '../../workspace_state/usecases/workspace_state_usecases.dart';
import '../../workspace_state/workspace_secret_cipher.dart';
import '../../workspace_state/workspace_secret_resolver.dart';
import '../domain/conversation_values.dart';
import '../repositories/cloud_connector_write_journal.dart';
import '../repositories/conversation_repository.dart' as conversation_repo;
import '../usecases/conversation_usecases.dart';
import 'background_work_result_reader.dart';
import 'conversation_host_effects.dart';
import 'server_agent_guidance.dart';
import 'server_tool_runtime.dart';

typedef _ConnectorReader = ({int workspaceId, String userId});
typedef _ConnectorReadTarget = ({
  ConnectorDefinition connector,
  ConnectorToolDefinition tool,
});
typedef _ConnectorConnections = ({
  List<Map<String, dynamic>> services,
  List<Map<String, dynamic>> models,
});

String cloudServiceConnectionId(String connectionId) =>
    connectionId.startsWith('service:')
    ? connectionId.substring('service:'.length)
    : connectionId;

Map<String, String> cloudModelConnectorCredentialAttributes(
  String providerId,
  String secret,
) {
  if (providerId != 'openai-codex') return {'apiKey': secret};

  final token = jsonDecode(secret);
  if (token is! Map<String, dynamic> || token['accessToken'] is! String) {
    throw const FormatException('Provider credential is unavailable.');
  }
  final idToken = token['idToken'];
  final accountId = idToken is String ? _codexAccountId(idToken) : null;
  if (accountId == null) {
    throw const FormatException('Provider credential is unavailable.');
  }

  return {'apiKey': token['accessToken']! as String, 'accountId': accountId};
}

String? _codexAccountId(String idToken) {
  final parts = idToken.split('.');
  if (parts.length != 3) return null;
  final normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
  final padded = normalized.padRight((normalized.length + 3) ~/ 4 * 4, '=');
  final claims = jsonDecode(utf8.decode(base64Decode(padded)));
  if (claims is! Map<String, dynamic>) return null;
  final auth = claims['https://api.openai.com/auth'];
  final accountId = auth is Map ? auth['chatgpt_account_id'] : null;

  return switch (accountId) {
    final String id when id.isNotEmpty => id,
    _ =>
      claims['chatgpt_account_id'] is String
          ? claims['chatgpt_account_id']! as String
          : null,
  };
}

bool _isCloudConnectorConnection(
  Map<String, dynamic> data,
  String connectorId,
) =>
    data['kind'] == 'customHttp' &&
    data['serviceId'] == connectorId &&
    data['isEnabled'] != false &&
    data['hasSecret'] == true;

List<Map<String, String>> cloudConnectorConnectionOptions({
  required ConnectorDefinition connector,
  required Iterable<Map<String, dynamic>> serviceConnections,
  Iterable<Map<String, dynamic>> modelConnections = const [],
}) => [
  for (final connection in serviceConnections)
    if (connection['kind'] == 'customHttp' &&
        connection['serviceId'] == connector.identifier &&
        connection['isEnabled'] != false &&
        connection['hasSecret'] == true)
      if (connection['id'] case final String id)
        {
          'id': 'service:$id',
          'name': connection['name'] is String
              ? connection['name']! as String
              : id,
        },
  for (final connection in modelConnections)
    if (connector.compatibleModelProviderIds.contains(
          connection['providerId'],
        ) &&
        connection['hasSecret'] == true)
      if (connection['id'] case final String id)
        {
          'id': 'model:$id',
          'name': connection['name'] is String
              ? connection['name']! as String
              : id,
        },
];

Map<String, Object?> cloudConnectorConnectionRecords({
  required Iterable<ConnectorDefinition> connectors,
  required Iterable<Map<String, dynamic>> serviceConnections,
  Iterable<Map<String, dynamic>> modelConnections = const [],
}) {
  final connectionsById = <String, Map<String, Object?>>{};
  for (final connector in connectors) {
    if (!connector.tools.any((tool) => tool.urlTemplate != null)) continue;
    for (final connection in cloudConnectorConnectionOptions(
      connector: connector,
      serviceConnections: serviceConnections,
      modelConnections: modelConnections,
    )) {
      final record = connectionsById.putIfAbsent(
        connection['id']!,
        () => {
          'id': connection['id'],
          'name': connection['name'],
          'connectorIds': <String>[],
        },
      );
      (record['connectorIds']! as List<String>).add(connector.identifier);
    }
  }
  return {
    'connections': [
      for (final record in connectionsById.values)
        {
          ...record,
          'connectorIds': (record['connectorIds']! as List<String>)..sort(),
        },
    ],
  };
}

List<Map<String, Object?>> cloudConnectorToolRecords({
  required Iterable<ConnectorDefinition> connectors,
  required Iterable<Map<String, dynamic>> serviceConnections,
  Iterable<Map<String, dynamic>> modelConnections = const [],
}) {
  final records = <Map<String, Object?>>[];
  for (final connector in connectors) {
    final connections = cloudConnectorConnectionOptions(
      connector: connector,
      serviceConnections: serviceConnections,
      modelConnections: modelConnections,
    );
    for (final tool in connector.tools) {
      if (tool.urlTemplate == null) continue;
      if (tool.requiresConnection && connections.isEmpty) continue;

      records.add({
        'toolId': connectorToolId(connector, tool),
        'connectorId': connector.identifier,
        'connectorName': connector.title,
        'name': tool.title,
        'description': tool.description,
        'inputSchema': Map<String, Object?>.from(tool.inputJsonSchema),
        'revision': connectorToolRevision(connector, tool),
        'requiresConnection': tool.requiresConnection,
        'connections': connections,
      });
    }
  }
  records.sort(
    (left, right) => '${left['toolId']}'.compareTo('${right['toolId']}'),
  );
  return records;
}

String? resolveCloudConnectorConnectionId({
  required List<Map<String, String>> connections,
  required bool requiresConnection,
  String? requestedConnectionId,
}) {
  if (!requiresConnection) {
    if (requestedConnectionId == null) return null;
    if (connections.any(
      (connection) => connection['id'] == requestedConnectionId,
    )) {
      return requestedConnectionId;
    }
    _throwCloudConnectorCommandFailure(
      'connection_unavailable',
      'Connection is not available for this Connector tool.',
      StackTrace.current,
    );
  }
  if (connections.isEmpty) {
    _throwCloudConnectorCommandFailure(
      'connection_required',
      'No enabled Connection is available for this tool. Connect one in the '
          'current workspace and retry.',
      StackTrace.current,
    );
  }
  if (requestedConnectionId != null) {
    if (connections.any(
      (connection) => connection['id'] == requestedConnectionId,
    )) {
      return requestedConnectionId;
    }
    _throwCloudConnectorCommandFailure(
      'connection_unavailable',
      'Connection is not available for this Connector tool.',
      StackTrace.current,
    );
  }
  if (connections.length == 1) return connections.single['id'];
  _throwCloudConnectorCommandFailure(
    'connection_selection_required',
    'Choose a Connection by passing connectionId to execute_connector_tool.',
    StackTrace.current,
  );
}

({ConnectorDefinition connector, ConnectorToolDefinition tool})
resolveCloudConnectorTool({
  required String toolId,
  required Map<String, dynamic> arguments,
  String? revision,
  Iterable<ConnectorDefinition>? connectors,
}) {
  for (final connector in connectors ?? connectorDefinitions) {
    for (final tool in connector.tools) {
      if (tool.urlTemplate == null ||
          connectorToolId(connector, tool) != toolId) {
        continue;
      }
      if (revision != null &&
          revision != connectorToolRevision(connector, tool)) {
        _throwCloudConnectorCommandFailure(
          'stale_contract',
          'Connector tool contract changed. Refresh and retry.',
          StackTrace.current,
        );
      }
      try {
        validateToolArguments(tool.inputJsonSchema, arguments);
      } on FormatException {
        _throwCloudConnectorCommandFailure(
          'invalid_tool_arguments',
          'Arguments do not match this Connector tool schema. Refresh the '
              'contract and retry.',
          StackTrace.current,
        );
      }
      return (connector: connector, tool: tool);
    }
  }
  _throwCloudConnectorCommandFailure(
    'unknown_tool',
    'Unknown Connector tool ID. Refresh Connector tools and retry.',
    StackTrace.current,
  );
}

class const _CloudConnectorCommandException({
  required final String code,
  required final String message,
}) implements Exception;

Never _throwCloudConnectorCommandFailure(
  String code,
  String message,
  StackTrace stackTrace,
) => Error.throwWithStackTrace(
  AgentToolExecutionFailure(
    responseRaw: jsonEncode({
      'error': {'code': code, 'message': message},
      'recoverable': true,
    }),
    error: _CloudConnectorCommandException(code: code, message: message),
    stackTrace: stackTrace,
    failurePhase: 'connector.command',
  ),
  stackTrace,
);

PatchWorkspaceStateRequest cloudSkillSelectionPatchRequest({
  required int workspaceId,
  required String turnRequestId,
  required String conversationId,
  required String skillId,
  required bool isAppSkill,
  required String toolCallId,
}) {
  final resourceId = '$conversationId:$skillId';
  final operation = WorkspacePatchOperation(
    operation: WorkspacePatchOperationKind.create,
    resourceKind: WorkspaceResourceKind.conversationSkillSelection,
    resourceId: resourceId,
    data: jsonEncode({
      'id': resourceId,
      'conversationId': conversationId,
      'skillId': skillId,
      if (isAppSkill) 'source': 'app',
    }),
    fieldMask: const [],
  );
  return PatchWorkspaceStateRequest(
    workspaceId: workspaceId,
    requestId: '$turnRequestId:$toolCallId:activate_skill:$skillId',
    operations: [operation],
  );
}

typedef ServerToolExecutorInterlock = Future<void> Function();
const _runCreateChildPhase = 'run.createChild';
const _runCreatePromptPhase = 'run.createPrompt';
const _runContinueAgentPhase = 'run.continueAgent';

Future<({Uri uri, List<InternetAddress> addresses})>
validateServerSkillRequestTarget(
  UrlRequest request, {
  required bool requireHttps,
  Future<List<InternetAddress>> Function(String host) lookup =
      InternetAddress.lookup,
  Duration dnsTimeout = const Duration(seconds: 5),
}) async {
  final uri = requirePublicUriSyntax(request.url, requireHttps: requireHttps);
  final addresses = await lookup(uri.host).timeout(dnsTimeout);
  if (addresses.isEmpty ||
      addresses.any(
        (address) => isPrivateIpAddress(
          address.rawAddress,
          isIpv6: address.type == InternetAddressType.IPv6,
        ),
      )) {
    throw const FormatException(publicUrlError);
  }
  return (uri: uri, addresses: addresses);
}

void rejectServerSkillRedirect(bool isRedirect) {
  if (isRedirect) throw const HttpException('Redirect rejected.');
}

Future<String> readBoundedServerSkillResponse(
  Stream<List<int>> response, {
  int maxBytes = McpServerPolicy.maxResponseBytes,
  Duration idleTimeout = const Duration(seconds: 30),
}) async {
  final bytes = <int>[];
  await for (final chunk in response.timeout(idleTimeout)) {
    bytes.addAll(chunk);
    if (bytes.length > maxBytes) {
      throw const FormatException('Tool response is too large.');
    }
  }
  return utf8.decode(bytes);
}

Future<void> closeOnServerSkillCancellation({
  required Future<bool> Function() isCancelled,
  required void Function() close,
  required Future<void> done,
  Duration pollInterval = const Duration(milliseconds: 100),
}) async {
  while (true) {
    if (await isCancelled()) {
      close();
      return;
    }
    final completed = await Future.any([
      done.then((_) => true),
      Future<void>.delayed(pollInterval).then((_) => false),
    ]);
    if (completed) return;
  }
}

Future<T> runBoundedServerSkillRequest<T>({
  required Duration timeout,
  required Future<T> Function() run,
  required void Function() close,
}) async {
  final timedOut = Completer<T>();
  final timer = Timer(timeout, () {
    close();
    timedOut.completeError(
      TimeoutException('Tool request timed out.', timeout),
    );
  });
  try {
    return await Future.any([run(), timedOut.future]);
  } finally {
    timer.cancel();
  }
}

Future<T> runBoundedServerSkillHttpRequest<T>({
  required Duration timeout,
  required Future<T> Function(void Function(HttpClient client) registerClient)
  run,
  void Function(HttpClient client)? closeClient,
}) {
  HttpClient? activeClient;
  var closed = false;
  void close() {
    closed = true;
    final client = activeClient;
    if (client != null) {
      (closeClient ?? (client) => client.close(force: true))(client);
    }
  }

  return runBoundedServerSkillRequest(
    timeout: timeout,
    close: close,
    run: () => run((client) {
      activeClient = client;
      if (closed) {
        (closeClient ?? (client) => client.close(force: true))(client);
      }
    }),
  );
}

class const ServerToolExecutorService({
  final ServerToolExecutorInterlock? beforeChildLaunch,
  final ServerToolExecutorInterlock? afterChildContinuation,
  final ServerToolExecutorInterlock? beforeSkillSelectionMutation,
  final Set<String>? a2uiSupportedComponents,
  final ConnectorHttpClient? connectorHttpClient,
}) {
  Future<void> readConnectorAccess(
    Session session, {
    required int workspaceId,
    required String userId,
    required Map<String, dynamic> arguments,
  }) => _checkReadAccess(session, (
    workspaceId: workspaceId,
    userId: userId,
  ), arguments);

  Future<void> _checkReadAccess(
    Session session,
    _ConnectorReader actor,
    Map<String, dynamic> arguments,
  ) async {
    final target = _readContract(arguments);
    await _authorizeRead(session, actor, target);
    await _requireReadConnection(
      session,
      actor.workspaceId,
      target,
      arguments['connectionId'] as String?,
    );
  }

  Future<void> _authorizeRead(
    Session session,
    _ConnectorReader actor,
    _ConnectorReadTarget target,
  ) => const WorkspaceConnectorAccessUsecases().requireEnabled(
    session,
    workspaceId: actor.workspaceId,
    userId: actor.userId,
    toolId: connectorToolId(target.connector, target.tool),
    tool: target.tool,
  );

  Future<void> _requireReadConnection(
    Session session,
    int workspaceId,
    _ConnectorReadTarget target,
    String? id,
  ) async {
    final connections = await _readConnections(session, workspaceId);
    final options = cloudConnectorConnectionOptions(
      connector: target.connector,
      serviceConnections: connections.services,
      modelConnections: connections.models,
    );
    final _ = resolveCloudConnectorConnectionId(
      connections: options,
      requiresConnection: target.tool.requiresConnection,
      requestedConnectionId: id,
    );
  }

  Future<Object?> readConnector(
    Session session, {
    required int workspaceId,
    required String userId,
    required Map<String, dynamic> arguments,
  }) => _readConnector(session, (
    workspaceId: workspaceId,
    userId: userId,
  ), arguments);

  Future<Object?> _readConnector(
    Session session,
    _ConnectorReader actor,
    Map<String, dynamic> arguments,
  ) async {
    final _ = _readContract(arguments);
    final connections = await _readConnections(session, actor.workspaceId);

    return await _executeRead(session, actor, arguments, connections);
  }

  Future<Object?> _executeRead(
    Session session,
    _ConnectorReader actor,
    Map<String, dynamic> arguments,
    _ConnectorConnections connections,
  ) => _executeConnectorTool(
    session,
    (workspaceId: actor.workspaceId, userId: actor.userId, turn: null),
    _readRequest(arguments),
    connections.services,
    connections.models,
  );

  Future<_ConnectorConnections> _readConnections(
    Session session,
    int workspaceId,
  ) async => (
    services: await _connectorServiceConnections(session, workspaceId),
    models: await _connectorModelConnections(session, workspaceId),
  );

  Future<Object?> call(
    Session session,
    ConversationTurn turn,
    ServerResolvedTool tool,
    ServerToolRequest request,
  ) async {
    await _throwIfCancelled(
      session,
      turn,
      isCancelled: request.isCancelled,
    );
    return switch (tool.descriptor.kind) {
      AgentResolvedToolKind.mcp => _runMcp(
        session,
        turn,
        tool,
        request.arguments,
      ),
      AgentResolvedToolKind.skillControl => _runSkillControl(
        session,
        turn,
        tool,
        request,
      ),
      AgentResolvedToolKind.connectorCommand => _runConnectorCommand(
        session,
        turn,
        tool,
        request,
      ),
      AgentResolvedToolKind.builtIn
          when tool.descriptor.tableId == backgroundWorkResultReaderTableId &&
              tool.descriptor.toolIdentifier ==
                  backgroundWorkResultReaderToolName =>
        _readBackgroundWorkResult(session, turn, request.arguments),
      AgentResolvedToolKind.skillNative
          when tool.descriptor.skillSlug == agentsSkillSlug =>
        _runSubAgentTool(session, turn, tool, request),
      AgentResolvedToolKind.skillNative =>
        throw const ServerToolNotConfiguredException(),
      _ => throw const ServerToolNotConfiguredException(),
    };
  }

  Future<Object?> _runConnectorCommand(
    Session session,
    ConversationTurn turn,
    ServerResolvedTool tool,
    ServerToolRequest request,
  ) async {
    try {
      validateToolArguments(tool.spec.inputJsonSchema, request.arguments);
      final serviceConnections = await _connectorServiceConnections(
        session,
        turn.workspaceId,
      );
      final modelConnections = await _connectorModelConnections(
        session,
        turn.workspaceId,
      );
      return switch (tool.descriptor.toolIdentifier) {
        listConnectorConnectionsToolName => cloudConnectorConnectionRecords(
          connectors: connectorDefinitions,
          serviceConnections: serviceConnections,
          modelConnections: modelConnections,
        ),
        listConnectorToolsToolName => {
          'tools': cloudConnectorToolRecords(
            connectors: connectorDefinitions,
            serviceConnections: serviceConnections,
            modelConnections: modelConnections,
          ),
        },
        executeConnectorToolName => await _executeConnectorTool(
          session,
          (
            workspaceId: turn.workspaceId,
            userId: turn.initiatorUserId,
            turn: turn,
          ),
          request,
          serviceConnections,
          modelConnections,
        ),
        _ => throw const _CloudConnectorCommandException(
          code: 'unknown_command',
          message: 'Unknown Connector command.',
        ),
      };
    } on CloudWorkspaceException catch (_, stackTrace) {
      _throwCloudConnectorCommandFailure(
        'tool_access_denied',
        'This tool is disabled or unavailable for your role. Ask a workspace owner or admin.',
        stackTrace,
      );
    } on _CloudConnectorCommandException catch (error, stackTrace) {
      _throwCloudConnectorCommandFailure(
        error.code,
        error.message,
        stackTrace,
      );
    } on AgentToolExecutionFailure catch (failure, stackTrace) {
      if (_trustedConnectorFailure(failure)) {
        rethrow;
      }
      _throwCloudConnectorCommandFailure(
        'execution_failed',
        'Connector command failed. Check the Connection and retry.',
        stackTrace,
      );
    } on ConversationCancelledException {
      rethrow;
    } on Object catch (_, stackTrace) {
      _throwCloudConnectorCommandFailure(
        'execution_failed',
        'Connector command failed. Check the Connection and retry.',
        stackTrace,
      );
    }
  }

  Future<List<Map<String, dynamic>>> _connectorServiceConnections(
    Session session,
    int workspaceId,
  ) async {
    final resources = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.resourceKind.equals(WorkspaceResourceKind.serviceConnection) &
          table.deletedAt.equals(null),
    );
    return [
      for (final resource in resources)
        {'id': resource.resourceId, ..._jsonMap(resource.data)},
    ];
  }

  Future<List<Map<String, dynamic>>> _connectorModelConnections(
    Session session,
    int workspaceId,
  ) async {
    final connections = await WorkspaceModelConnection.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) & table.deletedAt.equals(null),
    );
    return [
      for (final connection in connections)
        {
          'id': connection.connectionId,
          'name': connection.name,
          'providerId': connection.providerId,
          'hasSecret': connection.hasSecret,
        },
    ];
  }

  Future<Object?> _executeConnectorTool(
    Session session,
    ({int workspaceId, String userId, ConversationTurn? turn}) actor,
    ServerToolRequest request,
    List<Map<String, dynamic>> serviceConnections,
    List<Map<String, dynamic>> modelConnections,
  ) async {
    final toolId = request.arguments['toolId'];
    if (toolId is! String || toolId.trim().isEmpty) {
      throw const _CloudConnectorCommandException(
        code: 'invalid_arguments',
        message: 'toolId must be a non-empty string.',
      );
    }
    final rawArguments = request.arguments['args'];
    if (rawArguments is! Map) {
      throw const _CloudConnectorCommandException(
        code: 'invalid_arguments',
        message: 'args must be an object.',
      );
    }
    final arguments = <String, dynamic>{};
    for (final entry in rawArguments.entries) {
      if (entry.key is! String) {
        throw const _CloudConnectorCommandException(
          code: 'invalid_arguments',
          message: 'args keys must be strings.',
        );
      }
      arguments[entry.key! as String] = entry.value;
    }
    final requestedRevision = request.arguments['revision'];
    final requestedConnectionId = request.arguments['connectionId'];
    if (requestedRevision != null && requestedRevision is! String ||
        requestedConnectionId != null && requestedConnectionId is! String) {
      throw const _CloudConnectorCommandException(
        code: 'invalid_arguments',
        message: 'revision and connectionId must be strings.',
      );
    }

    final resolved = resolveCloudConnectorTool(
      toolId: toolId.trim(),
      arguments: arguments,
      revision: requestedRevision as String?,
    );

    await const WorkspaceConnectorAccessUsecases().requireEnabled(
      session,
      workspaceId: actor.workspaceId,
      userId: actor.userId,
      toolId: toolId.trim(),
      tool: resolved.tool,
    );

    final connectionOptions = resolved.tool.requiresConnection
        ? cloudConnectorConnectionOptions(
            connector: resolved.connector,
            serviceConnections: serviceConnections,
            modelConnections: modelConnections,
          )
        : const <Map<String, String>>[];
    final connectionId = resolveCloudConnectorConnectionId(
      connections: connectionOptions,
      requiresConnection: resolved.tool.requiresConnection,
      requestedConnectionId: requestedConnectionId as String?,
    );
    var credentials = const <String, String>{};
    if (connectionId != null) {
      if (connectionId.startsWith('model:')) {
        final resourceId = connectionId.substring('model:'.length);
        final modelConnection = await WorkspaceModelConnection.db.findFirstRow(
          session,
          where: (table) =>
              table.workspaceId.equals(actor.workspaceId) &
              table.connectionId.equals(resourceId) &
              table.deletedAt.equals(null),
        );
        if (modelConnection == null ||
            !modelConnection.hasSecret ||
            !resolved.connector.compatibleModelProviderIds.contains(
              modelConnection.providerId,
            )) {
          _throwCloudConnectorCommandFailure(
            'connection_unavailable',
            'Connection is not available for this Connector tool.',
            StackTrace.current,
          );
        }
        final secret = await _secret(
          session,
          actor.workspaceId,
          actor.userId,
          WorkspaceSecretKind.provider,
          resourceId,
        );
        if (secret == null) {
          _throwCloudConnectorCommandFailure(
            'connection_unavailable',
            'Connection is not available for this Connector tool.',
            StackTrace.current,
          );
        }
        credentials = cloudModelConnectorCredentialAttributes(
          modelConnection.providerId,
          await const WorkspaceSecretCipher().decrypt(session, secret),
        );
      } else {
        final resourceId = cloudServiceConnectionId(connectionId);
        final resource = await _resource(
          session,
          actor.workspaceId,
          WorkspaceResourceKind.serviceConnection,
          resourceId,
        );
        if (!_isCloudConnectorConnection(
          _jsonMap(resource.data),
          resolved.connector.identifier,
        )) {
          _throwCloudConnectorCommandFailure(
            'connection_unavailable',
            'Connection is not available for this Connector tool.',
            StackTrace.current,
          );
        }
        final secret = await const WorkspaceSecretResolver().find(
          session,
          workspaceId: actor.workspaceId,
          kind: WorkspaceSecretKind.provider,
          scope: WorkspaceSecretScope.workspace,
          ownerUserId: actor.userId,
          resourceId: resourceId,
        );
        if (secret == null) {
          _throwCloudConnectorCommandFailure(
            'connection_unavailable',
            'Connection is not available for this Connector tool.',
            StackTrace.current,
          );
        }
        credentials = {
          'apiKey': await const WorkspaceSecretCipher().decrypt(
            session,
            secret,
          ),
        };
      }
    }
    final executionArguments = Map<String, dynamic>.from(arguments);
    if (connectionId != null) {
      executionArguments.remove('connectionId');
    }
    return await ConnectorRequestExecution(
      executor: ConnectorToolTemplateExecutor(
        const ResolveConnectorRequestTemplate(),
        _connectorHttpClient(
          session,
          actor.turn,
          requireHttps: credentials.isNotEmpty,
          isCancelled: request.isCancelled,
        ),
      ),
      connector: resolved.connector,
      tool: resolved.tool,
      inputs: executionArguments,
      connectionId: connectionId ?? '',
      operationId: _connectorOperationId(request),
      journal: CloudConnectorWriteJournal(session, actor.workspaceId),
      credentials: credentials,
    ).call();
  }

  Future<Map<String, Object?>> _readBackgroundWorkResult(
    Session session,
    ConversationTurn turn,
    Map<String, dynamic> arguments,
  ) async {
    final workId = arguments['work_id'];
    final offset = arguments['offset'];
    final maxBytes = arguments['max_bytes'];
    if (workId is! String ||
        workId.isEmpty ||
        offset is! int ||
        maxBytes is! int) {
      throw const FormatException('Invalid background result request.');
    }
    final work = await BackgroundWorkRecord.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(turn.workspaceId) &
          table.conversationId.equals(turn.conversationId) &
          table.stableId.equals(workId),
    );
    if (work == null) {
      throw const FormatException('Background result is not available.');
    }
    return backgroundWorkResultPage(
      workId: work.stableId,
      status: work.status,
      resultContent: work.resultContent,
      resultByteLength: work.resultByteLength,
      offset: offset,
      maxBytes: maxBytes,
    );
  }

  Future<Object?> _runSkillControl(
    Session session,
    ConversationTurn turn,
    ServerResolvedTool tool,
    ServerToolRequest request,
  ) async {
    if (tool.descriptor.toolIdentifier == loadSkillResourceToolName) {
      return _loadSkillResource(session, turn, request.arguments);
    }
    if (tool.descriptor.toolIdentifier != activateSkillToolName) {
      throw const ServerToolNotConfiguredException();
    }
    final target = SkillActivationTarget.fromArguments(
      Map<String, Object?>.from(request.arguments),
    );
    final state = await _skillCommandState(session, turn);
    final skillId = _availableSkillId(target.slug, state);
    if (skillId == null) throw const ServerToolNotConfiguredException();
    final manifest = await buildCloudSkillManifest(
      slug: target.slug,
      userSkills: state.userSkills,
      languageCode: request.languageCode,
    );
    if (manifest == null || manifest.revision != target.revision) {
      throw FormatException(
        'Skill revision changed; use the current skill catalog to refresh: '
        '${target.slug}',
      );
    }
    final resources = await _skillResourceSummaries(
      session,
      turn,
      target.slug,
      skillId,
    );
    if (!state.selectedSkillIds.contains(skillId) &&
        !state.authorizedSkillIds.contains(skillId)) {
      await _throwIfCancelled(session, turn);
      await beforeSkillSelectionMutation?.call();
      await WorkspaceStateUseCases(WorkspaceStateRepository()).patch(
        session,
        userId: turn.initiatorUserId,
        request: cloudSkillSelectionPatchRequest(
          workspaceId: turn.workspaceId,
          turnRequestId: turn.requestId,
          conversationId: state.conversation.stableId,
          skillId: skillId,
          isAppSkill: !_isUserSkill(skillId, state.userSkills),
          toolCallId: request.id,
        ),
        guard: (transaction) => _throwIfCancelledUnderTurnLock(
          session,
          turn,
          transaction,
        ),
      );
    }
    return buildSkillActivationResult(
      manifest: manifest,
      content: _skillContent(target.slug, state, request.languageCode),
      resources: resources,
    );
  }

  Future<Object?> _loadSkillResource(
    Session session,
    ConversationTurn turn,
    Map<String, dynamic> arguments,
  ) async {
    final target = SkillResourceTarget.fromArguments(
      Map<String, Object?>.from(arguments),
    );
    final state = await _skillCommandState(session, turn);
    final skillId = _availableSkillId(target.skill, state);
    if (skillId == null || !state.authorizedSkillIds.contains(skillId)) {
      throw const ServerToolNotConfiguredException();
    }
    final appSkill = _appSkillDefinition(target.skill);
    if (appSkill != null) {
      final resource = appSkill.resources
          .where((candidate) => candidate.slug == target.resource)
          .firstOrNull;
      if (resource == null) {
        throw const ServerToolNotConfiguredException();
      }
      return buildSkillResourceResult(
        skillSlug: target.skill,
        resourceSlug: target.resource,
        title: resource.title,
        content: resource.content,
      );
    }
    final resource = await SkillResourceDataRepository().findBySlug(
      session,
      workspaceId: turn.workspaceId,
      skillId: skillId,
      slug: target.resource,
    );
    if (resource == null) throw const ServerToolNotConfiguredException();

    return buildSkillResourceResult(
      skillSlug: target.skill,
      resourceSlug: resource.slug,
      title: resource.title,
      content: resource.content,
    );
  }

  Future<List<SkillResourceSummary>> _skillResourceSummaries(
    Session session,
    ConversationTurn turn,
    String slug,
    String skillId,
  ) async {
    final appSkill = _appSkillDefinition(slug);
    if (appSkill != null) {
      return appSkill.resources.map((resource) => resource.summary).toList();
    }
    final resources = await SkillResourceDataRepository().list(
      session,
      workspaceId: turn.workspaceId,
      skillId: skillId,
    );

    return resources
        .map(
          (resource) => SkillResourceSummary(
            slug: resource.slug,
            title: resource.title,
            description: resource.description,
          ),
        )
        .toList();
  }

  Future<
    ({
      Conversation conversation,
      Set<String> selectedSkillIds,
      Set<String> authorizedSkillIds,
      List<Map<String, dynamic>> userSkills,
      List<Map<String, dynamic>> appSkillSettings,
      List<Map<String, dynamic>> serviceConnections,
    })
  >
  _skillCommandState(Session session, ConversationTurn turn) async {
    final conversation = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(turn.conversationId) &
          table.workspaceId.equals(turn.workspaceId),
    );
    if (conversation == null) throw const ServerToolNotConfiguredException();
    final resources = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(turn.workspaceId) &
          table.deletedAt.equals(null),
    );
    Map<String, dynamic> withId(WorkspaceResource resource) => {
      'id': resource.resourceId,
      ..._jsonMap(resource.data),
    };
    final selectedSkillIds = resources
        .where(
          (resource) =>
              resource.resourceKind ==
              WorkspaceResourceKind.conversationSkillSelection,
        )
        .map(withId)
        .where((data) => data['conversationId'] == conversation.stableId)
        .map((data) => data['skillId'])
        .whereType<String>()
        .toSet();
    final modelConnections = await WorkspaceModelConnection.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(turn.workspaceId) &
          table.deletedAt.equals(null),
    );
    return (
      conversation: conversation,
      selectedSkillIds: selectedSkillIds,
      authorizedSkillIds: cloudAuthorizedSkillIds(
        conversation: conversation,
        resources: resources,
      ),
      userSkills: resources
          .where(
            (resource) =>
                resource.resourceKind == WorkspaceResourceKind.skill &&
                _jsonMap(resource.data)['source'] != 'app',
          )
          .map(withId)
          .toList(),
      appSkillSettings: resources
          .where(
            (resource) =>
                resource.resourceKind == WorkspaceResourceKind.skillSetting,
          )
          .map(withId)
          .toList(),
      serviceConnections: [
        ...resources
            .where(
              (resource) =>
                  resource.resourceKind ==
                  WorkspaceResourceKind.serviceConnection,
            )
            .map(withId),
        for (final connection in modelConnections)
          {
            'id': connection.connectionId,
            'name': connection.name,
            'kind': 'modelProvider',
            'providerId': connection.providerId,
            'hasSecret': connection.hasSecret,
          },
      ],
    );
  }

  String? _availableSkillId(
    String slug,
    ({
      Conversation conversation,
      Set<String> selectedSkillIds,
      Set<String> authorizedSkillIds,
      List<Map<String, dynamic>> userSkills,
      List<Map<String, dynamic>> appSkillSettings,
      List<Map<String, dynamic>> serviceConnections,
    })
    state,
  ) {
    final user = state.userSkills
        .where((skill) => skill['slug'] == slug)
        .firstOrNull;
    if (user != null &&
        cloudUserSkillReady(
          user,
          state.serviceConnections,
        )) {
      return user['id'] as String?;
    }
    if (slug == agentsSkillSlug &&
        state.conversation.parentConversationStableId == null &&
        cloudAppSkillEnabled(agentsSkillSlug, state.appSkillSettings)) {
      return agentsSkillSlug;
    }
    final app = cloudAppSkillDefinitions
        .where((skill) => skill.slug == slug || skill.identifier == slug)
        .firstOrNull;
    if (app == null) return null;
    if (app.contentOnly) {
      if (app.slug == a2uiSkillSlug &&
          a2uiSupportedComponents?.isEmpty == true) {
        return null;
      }
      return state.conversation.parentConversationStableId == null
          ? app.identifier
          : null;
    }
    if (!cloudServiceSkillReady(app, state.serviceConnections)) {
      return null;
    }
    return app.identifier;
  }

  AppSkillDefinition? _appSkillDefinition(String slug) {
    final appSkill = cloudAppSkillDefinitions
        .where((skill) => skill.slug == slug || skill.identifier == slug)
        .firstOrNull;
    if (appSkill == null ||
        appSkill.slug != a2uiSkillSlug ||
        a2uiSupportedComponents == null) {
      return appSkill;
    }
    return a2uiSkillDefinitionForComponents(a2uiSupportedComponents!);
  }

  bool _isUserSkill(
    String skillId,
    Iterable<Map<String, dynamic>> userSkills,
  ) => userSkills.any((skill) => skill['id'] == skillId);

  String _skillContent(
    String slug,
    ({
      Conversation conversation,
      Set<String> selectedSkillIds,
      Set<String> authorizedSkillIds,
      List<Map<String, dynamic>> userSkills,
      List<Map<String, dynamic>> appSkillSettings,
      List<Map<String, dynamic>> serviceConnections,
    })
    state,
    String? languageCode,
  ) {
    final user = state.userSkills
        .where((skill) => skill['slug'] == slug)
        .firstOrNull;
    if (user?['content'] case final String content) return content;
    if (slug == agentsSkillSlug) {
      return serverAgentsSkillContentForLanguageCode(languageCode);
    }
    final app = cloudAppSkillDefinitions
        .where((skill) => skill.slug == slug || skill.identifier == slug)
        .firstOrNull;
    if (app != null) return app.content;
    throw const ServerToolNotConfiguredException();
  }

  Future<Object?> _runSubAgentTool(
    Session session,
    ConversationTurn turn,
    ServerResolvedTool tool,
    ServerToolRequest request,
  ) async {
    if (tool.descriptor.toolIdentifier == listAgentsToolName) {
      final result = await _listAgents(session, turn, request.arguments);

      return {
        ...result,
        'hint': serverGeneralSubAgentHintForLanguageCode(
          request.languageCode,
        ),
      };
    }
    if (tool.descriptor.toolIdentifier != runSubAgentToolName) {
      throw const ServerToolNotConfiguredException();
    }
    final rawAgentId = request.arguments['agentId'];
    final id = const Uuid().v4();
    final useCases = ConversationUseCases(
      conversation_repo.ConversationRepository(),
    );
    ConversationSummary? child;
    final startedAt = DateTime.now().toUtc();
    var failurePhase = 'run.validate';
    void logLifecycle(
      String phase, {
      String? childId,
      required String state,
      int childCount = 1,
    }) {
      session.log(
        'Sub-agent lifecycle: parentConversation=${turn.conversationId}, '
        'parentTurn=${turn.id}, toolCall=${request.id}, '
        'childConversation=${childId ?? '-'}, phase=$phase, '
        'elapsedMs=${DateTime.now().toUtc().difference(startedAt).inMilliseconds}, '
        'childCount=$childCount, state=$state.',
      );
    }

    try {
      final input = _validatedSubAgentRequest(request.arguments);
      failurePhase = 'run.parentValidation';
      final parent = await _requireSubAgentParent(session, turn);
      failurePhase = 'run.agentValidation';
      await _validateSubAgentAgent(session, turn, input.agentId);
      failurePhase = _runCreateChildPhase;
      await _throwIfCancelled(session, turn);
      logLifecycle(_runCreateChildPhase, state: 'started');
      child = await useCases.create(
        session,
        userId: turn.initiatorUserId,
        request: CreateConversationRequest(
          workspaceId: turn.workspaceId,
          requestId: '$id:create',
          conversationId: id,
          title: input.title.trim(),
          isPinned: false,
          modelId:
              await _activeTurnModelSelectionId(session, turn) ??
              parent.modelId,
          agentId: input.agentId,
          parentConversationId: parent.stableId,
        ),
      );
      await _recordSubAgentChildConversation(
        session,
        turn: turn,
        toolCallId: request.id,
        childConversationId: child.id,
      );
      logLifecycle(
        _runCreateChildPhase,
        childId: child.id,
        state: 'completed',
      );
      failurePhase = _runCreatePromptPhase;
      logLifecycle(_runCreatePromptPhase, childId: child.id, state: 'started');
      final queued = await useCases.queueConversationMessage(
        session,
        userId: turn.initiatorUserId,
        request: QueueConversationMessageRequest(
          workspaceId: turn.workspaceId,
          requestId: '$id:queue',
          conversationId: child.id,
          expectedProjectionRevision: child.revision,
          clientMessageId: '$id:user',
          content: input.prompt.trim(),
          attachmentIds: const [],
          languageCode: request.languageCode,
        ),
      );
      logLifecycle(
        _runCreatePromptPhase,
        childId: child.id,
        state: 'completed',
      );
      failurePhase = 'run.beforeChildLaunch';
      await beforeChildLaunch?.call();
      failurePhase = _runContinueAgentPhase;
      logLifecycle(
        _runContinueAgentPhase,
        childId: child.id,
        state: 'started',
      );
      final started = await useCases.continueConversation(
        session,
        userId: turn.initiatorUserId,
        request: ContinueConversationRequest(
          workspaceId: turn.workspaceId,
          requestId: '$id:continue',
          conversationId: child.id,
          expectedProjectionRevision: queued.conversation.projectionRevision,
          languageCode: request.languageCode,
        ),
        parentTurnId: turn.id,
        parentToolCallId: request.id,
      );
      logLifecycle(
        _runContinueAgentPhase,
        childId: child.id,
        state: 'completed',
      );
      failurePhase = 'run.readResult';
      final execution = started.activeExecution;
      if (execution == null) throw const ServerToolNotConfiguredException();
      await afterChildContinuation?.call();
      await session.db.transaction(
        (transaction) => _throwIfCancelledUnderTurnLock(
          session,
          turn,
          transaction,
        ),
      );
      logLifecycle(
        'run.awaitingSubAgents',
        childId: child.id,
        state: 'waiting',
      );
      return ServerToolAwaitingSubAgents(
        children: [
          {
            'conversationId': child.id,
            'turnId': execution.id,
            'status': execution.status,
            if (child.agentId != null) 'agentId': child.agentId,
          },
        ],
      );
    } on ConversationCancelledException {
      logLifecycle(
        failurePhase,
        childId: child?.id,
        state: 'cancelled',
      );
      if (child != null) {
        await _compensateCancelledChild(
          session,
          turn: turn,
          childId: child.id,
          useCases: useCases,
        );
      }
      rethrow;
    } on AgentToolExecutionFailure catch (failure) {
      logLifecycle(
        failure.failurePhase,
        childId: child?.id,
        state: 'failed',
      );
      if (child == null) rethrow;

      throw _subAgentFailure(
        error: failure.error,
        stackTrace: failure.stackTrace,
        failurePhase: failure.failurePhase,
        childId: child.id,
        agentId: child.agentId,
      );
    } on Object catch (error, stackTrace) {
      logLifecycle(
        failurePhase,
        childId: child?.id,
        state: 'failed',
      );
      if (child != null && await _isCancelled(session, turn)) {
        await _compensateCancelledChild(
          session,
          turn: turn,
          childId: child.id,
          useCases: useCases,
        );
      }
      throw _subAgentFailure(
        error: error,
        stackTrace: stackTrace,
        failurePhase: failurePhase,
        childId: child?.id,
        agentId: child?.agentId ?? (rawAgentId is String ? rawAgentId : null),
      );
    }
  }

  ({String title, String prompt, String? agentId}) _validatedSubAgentRequest(
    Map<String, dynamic> arguments,
  ) {
    final title = arguments['title'];
    final prompt = arguments['prompt'];
    final agentId = arguments['agentId'];
    if (title is! String ||
        title.trim().isEmpty ||
        title.length > maxSubAgentTitleLength ||
        prompt is! String ||
        prompt.trim().isEmpty ||
        prompt.length > maxSubAgentPromptLength ||
        (agentId != null && agentId is! String)) {
      throw const FormatException('Invalid sub-agent request.');
    }
    return (
      title: title,
      prompt: prompt,
      agentId: agentId as String?,
    );
  }

  Future<Conversation> _requireSubAgentParent(
    Session session,
    ConversationTurn turn,
  ) async {
    final parent = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(turn.conversationId) &
          table.workspaceId.equals(turn.workspaceId) &
          table.deletedAt.equals(null),
    );
    if (parent == null || parent.parentConversationStableId != null) {
      throw const ServerToolNotConfiguredException();
    }
    return parent;
  }

  Future<void> _validateSubAgentAgent(
    Session session,
    ConversationTurn turn,
    String? agentId,
  ) async {
    if (agentId is String &&
        !await _isRunnableAgent(session, turn.workspaceId, agentId)) {
      throw const ServerToolNotConfiguredException();
    }
  }

  AgentToolExecutionFailure _subAgentFailure({
    required Object error,
    required StackTrace stackTrace,
    required String failurePhase,
    String? childId,
    String? agentId,
  }) => AgentToolExecutionFailure(
    responseRaw: jsonEncode({
      'conversationId': ?childId,
      'status': 'error',
      'content': 'Sub-agent failed.',
      'agentId': ?agentId,
    }),
    error: error,
    stackTrace: stackTrace,
    failurePhase: failurePhase,
  );

  Future<String?> _activeTurnModelSelectionId(
    Session session,
    ConversationTurn turn,
  ) async {
    final messageId = turn.userMessageId;
    if (messageId == null) return null;
    final message = await ConversationMessage.db.findById(session, messageId);
    if (message?.metadataJson == null) return null;
    final selectionId = _jsonMap(message!.metadataJson!)['modelSelectionId'];
    return selectionId is String && selectionId.isNotEmpty ? selectionId : null;
  }

  Future<void> _recordSubAgentChildConversation(
    Session session, {
    required ConversationTurn turn,
    required String toolCallId,
    required String childConversationId,
  }) async {
    var detached = false;
    var stopRequested = false;
    await session.db.transaction((transaction) async {
      final call = await ConversationToolCall.db.findFirstRow(
        session,
        where: (table) =>
            table.workspaceId.equals(turn.workspaceId) &
            table.turnId.equals(turn.id!) &
            table.stableId.equals(toolCallId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (call == null) return;
      detached = call.backgroundWorkStableId != null;
      final workId = call.backgroundWorkStableId;
      if (workId != null) {
        final work = await BackgroundWorkRecord.db.findFirstRow(
          session,
          where: (table) =>
              table.workspaceId.equals(turn.workspaceId) &
              table.conversationId.equals(turn.conversationId) &
              table.conversationToolCallId.equals(call.id) &
              table.stableId.equals(workId),
          transaction: transaction,
        );
        stopRequested = work?.status == 'stopRequested';
      }
      final resultJson = call.resultJson;
      final acknowledgement = detached && resultJson != null
          ? _withChildConversationAcknowledgement(
              resultJson,
              childConversationId,
            )
          : resultJson;
      await ConversationToolCall.db.updateRow(
        session,
        call.copyWith(
          childConversationStableId: childConversationId,
          resultJson: acknowledgement,
          revision: call.revision + 1,
          updatedAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
    });
    if (stopRequested) {
      await ConversationUseCases(
        conversation_repo.ConversationRepository(),
      ).stopBackgroundSubAgentChild(
        session,
        userId: turn.initiatorUserId,
        workspaceId: turn.workspaceId,
        childConversationId: childConversationId,
        requestId: 'background-work-stop:$toolCallId:child',
      );
    }
    if (!detached) return;
    final parent = await Conversation.db.findById(session, turn.conversationId);
    if (parent == null) return;
    await SyncWakeups.publishConversation(
      session,
      workspaceId: turn.workspaceId,
      conversationId: parent.stableId,
    );
  }

  String? _withChildConversationAcknowledgement(
    String resultJson,
    String childConversationId,
  ) {
    final decoded = jsonDecode(resultJson);
    if (decoded is! Map<String, dynamic> ||
        decoded['status'] != 'running_in_background') {
      return resultJson;
    }
    return jsonEncode({...decoded, 'childConversationId': childConversationId});
  }

  Future<void> _compensateCancelledChild(
    Session session, {
    required ConversationTurn turn,
    required String childId,
    required ConversationUseCases useCases,
  }) async {
    final parent = await Conversation.db.findById(session, turn.conversationId);
    if (parent == null) return;
    final activeTurn = await session.db.transaction((transaction) async {
      final child = await Conversation.db.findFirstRow(
        session,
        where: (table) =>
            table.workspaceId.equals(turn.workspaceId) &
            table.stableId.equals(childId) &
            table.parentConversationStableId.equals(parent.stableId) &
            table.deletedAt.equals(null),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (child == null) return null;
      final execution = child.activeExecutionId == null
          ? null
          : await ConversationExecution.db.findById(
              session,
              child.activeExecutionId!,
              transaction: transaction,
              lockMode: LockMode.forUpdate,
            );
      if (execution != null) {
        return ConversationTurn.db.findFirstRow(
          session,
          where: (table) =>
              table.workspaceId.equals(turn.workspaceId) &
              table.requestId.equals(execution.stableId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
      }
      final pending = await ConversationMessage.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(turn.workspaceId) &
            table.conversationId.equals(child.id) &
            table.pendingOrder.notEquals(null),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      for (final message in pending) {
        await ConversationMessage.db.deleteRow(
          session,
          message,
          transaction: transaction,
        );
      }
      await Conversation.db.updateRow(
        session,
        child.copyWith(
          deletedAt: DateTime.now().toUtc(),
          revision: child.revision + 1,
          updatedAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
      return null;
    });
    if (activeTurn == null ||
        ConversationStatuses.isTerminal(activeTurn.status)) {
      return;
    }
    await useCases.cancelTurn(
      session,
      userId: turn.initiatorUserId,
      request: CancelTurnRequest(
        workspaceId: turn.workspaceId,
        requestId: '$childId:cancelled-parent',
        turnId: activeTurn.requestId,
        expectedTurnRevision: activeTurn.revision,
      ),
    );
    await _retireCancelledChildExecution(
      session,
      workspaceId: turn.workspaceId,
      childId: childId,
      actorUserId: turn.initiatorUserId,
    );
  }

  Future<void> _retireCancelledChildExecution(
    Session session, {
    required int workspaceId,
    required String childId,
    required String actorUserId,
  }) => session.db.transaction((transaction) async {
    final child = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.stableId.equals(childId),
      transaction: transaction,
    );
    final childDatabaseId = child?.id;
    final executionId = child?.activeExecutionId;
    if (childDatabaseId == null || executionId == null) return;
    final execution = await ConversationExecution.db.findById(
      session,
      executionId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (execution == null) return;
    final lockedChild = await Conversation.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.id.equals(childDatabaseId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (lockedChild == null || lockedChild.activeExecutionId != execution.id) {
      return;
    }
    final now = DateTime.now().toUtc();
    if (execution.assistantMessageId case final assistantMessageId?) {
      final assistant = await ConversationMessage.db.findById(
        session,
        assistantMessageId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (assistant != null &&
          !ConversationStatuses.isMessageTerminal(assistant.status)) {
        await ConversationMessage.db.updateRow(
          session,
          assistant.copyWith(
            content: '',
            status: ConversationStatuses.cancelled,
            metadataJson: '{"errorCode":"cancelled"}',
            revision: assistant.revision + 1,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      }
    }
    await ConversationExecution.db.updateRow(
      session,
      execution.copyWith(
        status: ConversationStatuses.cancelled,
        terminalAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    final sequence = lockedChild.eventSequence + 1;
    await Conversation.db.updateRow(
      session,
      lockedChild.copyWith(
        executionState: 'idle',
        activeExecutionId: null,
        eventSequence: sequence,
        projectionRevision: lockedChild.projectionRevision + 1,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await ConversationEvent.db.insertRow(
      session,
      ConversationEvent(
        workspaceId: workspaceId,
        conversationId: lockedChild.id!,
        sequence: sequence,
        eventId: const Uuid().v7(),
        actorUserId: actorUserId,
        requestId: '$childId:cancelled-parent',
        kind: ConversationEventType.executionStopped,
        payloadJson: jsonEncode({
          'executionId': execution.stableId,
          'status': ConversationStatuses.cancelled,
        }),
        createdAt: now,
      ),
      transaction: transaction,
    );
  });

  Future<Map<String, Object?>> _listAgents(
    Session session,
    ConversationTurn turn,
    Map<String, dynamic> arguments,
  ) async {
    final query = SubAgentCatalogQuery.fromArguments(
      turn.workspaceId.toString(),
      arguments,
    );
    final page =
        await AgentCatalogUseCases(
          AgentCatalogRepository(),
          WorkspaceStateRepository(),
        ).list(
          session,
          userId: turn.initiatorUserId,
          request: ListAgentsRequest(
            workspaceId: turn.workspaceId,
            search: query.query,
            type: switch (query.type) {
              'main' => AgentCatalogType.chatSelector,
              'sub_agent' => AgentCatalogType.subAgentList,
              _ => null,
            },
            status: AgentCatalogStatus.enabled,
            limit: query.limit,
            cursor: query.cursor,
          ),
        );
    return {
      'agents': [
        for (final agent in page.agents)
          {
            'id': agent.id,
            'name': agent.name,
            'description': agent.description,
            'types': _agentCatalogTypes(agent.visibility),
          },
      ],
      'nextCursor': page.nextCursor,
      'hint': generalSubAgentHint,
    };
  }

  Future<bool> _isRunnableAgent(
    Session session,
    int workspaceId,
    String agentId,
  ) async {
    final resource = await WorkspaceResource.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.resourceKind.equals(WorkspaceResourceKind.agent) &
          table.resourceId.equals(agentId) &
          table.deletedAt.equals(null),
    );
    return resource != null &&
        _agentTypes(_jsonMap(resource.data), 'sub_agent').isNotEmpty;
  }

  List<String> _agentTypes(Map<String, dynamic> data, Object? filter) {
    if (data['isEnabled'] == false) return const [];
    final types = switch (data['visibility']) {
      'chatSelector' => const ['main'],
      'subAgentList' => const ['sub_agent'],
      _ => const ['main', 'sub_agent'],
    };
    return filter == null || types.contains(filter) ? types : const [];
  }

  List<String> _agentCatalogTypes(AgentCatalogVisibility visibility) =>
      switch (visibility) {
        .chatSelector => const ['main'],
        .subAgentList => const ['sub_agent'],
        .both => const ['main', 'sub_agent'],
      };

  Future<Object?> _runMcp(
    Session session,
    ConversationTurn turn,
    ServerResolvedTool tool,
    Map<String, dynamic> arguments,
  ) async {
    await const WorkspaceConnectorAccessUsecases().requireMcp(
      session,
      workspaceId: turn.workspaceId,
      userId: turn.initiatorUserId,
      resourceId: tool.descriptor.tableId,
    );
    final serverId = tool.descriptor.mcpServerId!;
    final server = await _resource(
      session,
      turn.workspaceId,
      WorkspaceResourceKind.mcpServer,
      serverId,
    );
    final data = _jsonMap(server.data);
    final transport = data['transport'];
    if (transport is! Map ||
        !{'streamableHttp', 'sse'}.contains(transport['type'])) {
      throw const ServerToolNotConfiguredException();
    }
    final uri = McpServerPolicy.validateUri(data['url'] as String);
    final addresses = await InternetAddress.lookup(
      uri.host,
    ).timeout(const Duration(seconds: 5));
    McpServerPolicy.validateAddresses(addresses);
    final secret = await _secret(
      session,
      turn.workspaceId,
      turn.initiatorUserId,
      WorkspaceSecretKind.mcp,
      serverId,
    );
    await _throwIfCancelled(session, turn);
    final decrypted = secret == null
        ? null
        : data['authType'] == 'oauth'
        ? await McpOAuthTokenResolver().resolve(
            session,
            secret,
            actorUserId: turn.initiatorUserId,
          )
        : await const WorkspaceSecretCipher().decrypt(session, secret);
    final bearerToken = data['authType'] == 'httpHeaders' ? null : decrypted;
    final httpHeaders = data['authType'] == 'httpHeaders'
        ? parseMcpHttpHeaders(decrypted)
        : const <String, String>{};
    final result = transport['type'] == 'sse'
        ? await _callSse(
            session,
            turn,
            uri,
            addresses.first,
            tool.descriptor.toolIdentifier,
            arguments,
            bearerToken: bearerToken,
            httpHeaders: httpHeaders,
          )
        : await _postJson(
            session,
            turn,
            uri,
            addresses,
            {
              'jsonrpc': '2.0',
              'id': 1,
              'method': 'tools/call',
              'params': {
                'name': tool.descriptor.toolIdentifier,
                'arguments': arguments,
              },
            },
            bearerToken: bearerToken,
            httpHeaders: httpHeaders,
          );
    return McpToolResult(
      content: switch (result['content']) {
        final List<dynamic> content =>
          content
              .whereType<Map<String, dynamic>>()
              .where((item) => item['type'] == 'text')
              .map((item) => McpTextContent('${item['text'] ?? ''}'))
              .toList(),
        _ => const [],
      },
      structuredContent: switch (result['structuredContent']) {
        final Map<String, dynamic> content => content,
        _ => null,
      },
      isError: result['isError'] as bool?,
    ).toModelText();
  }

  Future<Map<String, Object?>> _callSse(
    Session serverSession,
    ConversationTurn turn,
    Uri uri,
    InternetAddress address,
    String toolName,
    Map<String, dynamic> arguments, {
    String? bearerToken,
    Map<String, String> httpHeaders = const {},
  }) async {
    final sse = await McpSseSession.connect(
      uri,
      address,
      bearerToken: bearerToken,
      httpHeaders: httpHeaders,
    );
    final done = Completer<void>();
    unawaited(
      _closeClientOnCancellation(sse.client, serverSession, turn, done),
    );
    try {
      await sse.request(1, 'initialize', {
        'protocolVersion': '2025-06-18',
        'capabilities': <String, Object?>{},
        'clientInfo': {'name': 'AuraVibes Server', 'version': '1.0.0'},
      });
      await sse.notify('notifications/initialized', const {});
      return await sse.request(2, 'tools/call', {
        'name': toolName,
        'arguments': arguments,
      });
    } finally {
      if (!done.isCompleted) done.complete();
      await sse.close();
    }
  }

  Future<Map<String, dynamic>> _postJson(
    Session session,
    ConversationTurn turn,
    Uri uri,
    List<InternetAddress> addresses,
    Map<String, Object?> body, {
    String? bearerToken,
    Map<String, String> httpHeaders = const {},
  }) async {
    final client = _client(uri, addresses);
    final requestDone = Completer<void>();
    unawaited(_closeClientOnCancellation(client, session, turn, requestDone));
    try {
      final request = await client.postUrl(uri);
      request
        ..followRedirects = false
        ..headers.contentType = ContentType.json
        ..headers.set('Accept', 'application/json');
      if (bearerToken != null) {
        request.headers.set('Authorization', 'Bearer $bearerToken');
      }
      httpHeaders.forEach(request.headers.set);
      request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != HttpStatus.ok || response.isRedirect) {
        throw const HttpException('Tool request failed.');
      }
      final decoded = jsonDecode(await _readResponse(response));
      if (decoded is! Map<String, dynamic> ||
          decoded['result'] is! Map<String, dynamic>) {
        throw const FormatException('Invalid tool response.');
      }
      return decoded['result']! as Map<String, dynamic>;
    } on Object {
      await _throwIfCancelled(session, turn);
      rethrow;
    } finally {
      client.close(force: true);
      if (!requestDone.isCompleted) requestDone.complete();
    }
  }

  ConnectorHttpClient _connectorHttpClient(
    Session session,
    ConversationTurn? turn, {
    required bool requireHttps,
    Future<bool> Function()? isCancelled,
  }) =>
      connectorHttpClient ??
      ((input) => CancelableOperation<UrlResponse>.fromFuture(
        runBoundedServerSkillHttpRequest(
          timeout: input.timeout,
          run: (registerClient) async {
            final target = await validateServerSkillRequestTarget(
              input,
              requireHttps: requireHttps,
            );
            await _throwIfCancelled(session, turn);
            return _request(
              session,
              turn,
              target.uri,
              target.addresses,
              input,
              onClient: registerClient,
              isCancelled: isCancelled,
            );
          },
        ),
      ));

  Future<UrlResponse> _request(
    Session session,
    ConversationTurn? turn,
    Uri uri,
    List<InternetAddress> addresses,
    UrlRequest input, {
    void Function(HttpClient client)? onClient,
    Future<bool> Function()? isCancelled,
  }) async {
    final client = _client(uri, addresses);
    onClient?.call(client);
    final requestDone = Completer<void>();
    unawaited(
      _closeClientOnCancellation(
        client,
        session,
        turn,
        requestDone,
        isCancelled: isCancelled,
      ),
    );
    final stopwatch = Stopwatch()..start();
    try {
      final request = await client.openUrl(input.method.value, uri);
      request.followRedirects = false;
      input.headers.forEach(request.headers.set);
      if (input.body != null) request.write(input.body);
      final response = await request.close().timeout(input.timeout);
      rejectServerSkillRedirect(response.isRedirect);
      final headers = <String, List<String>>{};
      response.headers.forEach((name, values) => headers[name] = values);
      return UrlResponse(
        statusCode: response.statusCode,
        body: await _readResponse(response, idleTimeout: input.timeout),
        headers: headers,
        elapsed: stopwatch.elapsed,
      );
    } on Object {
      await _throwIfCancelled(session, turn, isCancelled: isCancelled);
      rethrow;
    } finally {
      client.close(force: true);
      if (!requestDone.isCompleted) requestDone.complete();
    }
  }

  Future<void> _throwIfCancelled(
    Session session,
    ConversationTurn? turn, {
    Future<bool> Function()? isCancelled,
  }) async {
    if (await (isCancelled?.call() ??
        (turn == null ? Future.value(false) : _isCancelled(session, turn)))) {
      throw const ConversationCancelledException();
    }
  }

  Future<bool> _isCancelled(
    Session session,
    ConversationTurn turn,
  ) => const DatabaseConversationCancellationProbe().isCancelled(
    session,
    turn.id!,
  );

  Future<void> _throwIfCancelledUnderTurnLock(
    Session session,
    ConversationTurn turn,
    Transaction transaction,
  ) async {
    final current = await ConversationTurn.db.findById(
      session,
      turn.id!,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (current == null ||
        current.cancellationRequestedAt != null ||
        ConversationStatuses.isTerminal(current.status)) {
      throw const ConversationCancelledException();
    }
  }

  Future<void> _closeClientOnCancellation(
    HttpClient client,
    Session session,
    ConversationTurn? turn,
    Completer<void> requestDone, {
    Future<bool> Function()? isCancelled,
  }) => closeOnServerSkillCancellation(
    isCancelled:
        isCancelled ??
        () => turn == null
            ? Future.value(false)
            : const DatabaseConversationCancellationProbe().isCancelled(
                session,
                turn.id!,
              ),
    close: () {
      if (!requestDone.isCompleted) client.close(force: true);
    },
    done: requestDone.future,
  );

  HttpClient _client(Uri uri, List<InternetAddress> addresses) =>
      pinnedHttpClient(uri, addresses.first)
        ..connectionTimeout = const Duration(seconds: 10);

  Future<String> _readResponse(
    HttpClientResponse response, {
    Duration? idleTimeout,
  }) {
    final timeout = idleTimeout;
    if (timeout == null) return readBoundedServerSkillResponse(response);
    return readBoundedServerSkillResponse(response, idleTimeout: timeout);
  }

  Future<WorkspaceResource> _resource(
    Session session,
    int workspaceId,
    WorkspaceResourceKind kind,
    String id,
  ) async {
    final resource = await WorkspaceResource.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.resourceKind.equals(kind) &
          table.resourceId.equals(id) &
          table.deletedAt.equals(null),
    );
    if (resource == null) throw const ServerToolNotConfiguredException();
    return resource;
  }

  Future<WorkspaceSecret?> _secret(
    Session session,
    int workspaceId,
    String userId,
    WorkspaceSecretKind kind,
    String resourceId,
  ) => const WorkspaceSecretResolver().findForInitiator(
    session,
    workspaceId: workspaceId,
    kind: kind,
    initiatorUserId: userId,
    resourceId: resourceId,
    allowWorkspaceFallback: true,
  );

  Map<String, dynamic> _jsonMap(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  }
}

class const ServerToolNotConfiguredException() implements Exception;

bool _trustedConnectorFailure(AgentToolExecutionFailure failure) =>
    failure.error is _CloudConnectorCommandException ||
    const {'connector.write', 'connector.read'}.contains(failure.failurePhase);

String _connectorOperationId(ServerToolRequest request) {
  final id = request.arguments['operationId'];
  if (id == null) return request.id;
  if (id is String && id.isNotEmpty) return id;
  throw const _CloudConnectorCommandException(
    code: 'invalid_arguments',
    message: 'operationId must be a non-empty string.',
  );
}

_ConnectorReadTarget _readContract(Map<String, dynamic> arguments) {
  final target = _resolveReadTarget(arguments);
  if (connectorToolWrites(target.tool)) {
    throw CloudWorkspaceException(code: .validationFailed);
  }

  return target;
}

_ConnectorReadTarget _resolveReadTarget(Map<String, dynamic> arguments) {
  final {
    'toolId': String toolId,
    'revision': String revision,
    'args': Map<Object?, Object?> inputs,
  } = arguments;

  return resolveCloudConnectorTool(
    toolId: toolId,
    arguments: Map<String, dynamic>.from(inputs),
    revision: revision,
  );
}

ServerToolRequest _readRequest(Map<String, dynamic> arguments) => .new(
  id: '',
  name: executeConnectorToolName,
  arguments: arguments,
);
