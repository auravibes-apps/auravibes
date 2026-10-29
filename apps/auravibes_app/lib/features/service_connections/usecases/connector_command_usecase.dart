import 'dart:convert';

import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/features/service_connections/usecases/run_connector_tool_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:collection/collection.dart';
import 'package:riverpod/riverpod.dart';

typedef ConnectorConnectionsLoader =
    Future<List<ConnectorConnectionCandidate>> Function(
      String workspaceId,
      ConnectorDefinition connector,
    );

typedef ConnectorToolRunner = Future<Object?> Function({
  required String workspaceId,
  required ConnectorDefinition connector,
  required ConnectorToolDefinition tool,
  required Map<String, dynamic> arguments,
});

typedef _ConnectorExecutionRequest = ({
  String toolId,
  Map<String, Object?> arguments,
  String? connectionId,
  String? revision,
  String? operationId,
});

typedef _ResolvedConnectorExecution = ({
  ConnectorDefinition connector,
  ConnectorToolDefinition tool,
  Map<String, dynamic> arguments,
});

class _ConnectorConnectionRecord({
  required final String id,
  required final String name,
}) {
  final Set<String> connectorIds = {};

  Map<String, Object?> toJson() {
    final sortedConnectorIds = connectorIds.toList()..sort();

    return {'id': id, 'name': name, 'connectorIds': sortedConnectorIds};
  }
}

class _ConnectorToolCatalog {
  static List<ConnectorToolDefinition> connectorTools(
    ConnectorDefinition connector,
  ) => connector.tools
      .where((tool) => tool.urlTemplate != null)
      .toList(growable: false);

  static String toolId(
    ConnectorDefinition connector,
    ConnectorToolDefinition tool,
  ) => connectorToolId(connector, tool);

  static String revision(
    ConnectorDefinition connector,
    ConnectorToolDefinition tool,
  ) => connectorToolRevision(connector, tool);
}

class _ConnectorCommandDiscovery({
  required final List<ConnectorDefinition> connectors,
  required final ConnectorConnectionsLoader loadConnections,
}) {
  Future<Map<String, Object?>> listConnections(String workspaceId) async {
    final connectionsById = <String, _ConnectorConnectionRecord>{};
    for (final connector in connectors) {
      if (_ConnectorToolCatalog.connectorTools(connector).isEmpty) continue;
      final connections = await loadConnections(workspaceId, connector);
      _addConnections(connectionsById, connector, connections);
    }

    return {
      'connections': [for (final item in connectionsById.values) item.toJson()],
    };
  }

  Future<Map<String, Object?>> listTools(String workspaceId) async {
    final tools = <Map<String, Object?>>[];
    for (final connector in connectors) {
      tools.addAll(await _toolRecordsForConnector(workspaceId, connector));
    }
    tools.sort(_compareToolIds);

    return {'tools': tools};
  }

  Future<List<Map<String, Object?>>> _toolRecordsForConnector(
    String workspaceId,
    ConnectorDefinition connector,
  ) async {
    final connectorTools = _ConnectorToolCatalog.connectorTools(connector);
    if (connectorTools.isEmpty) return const [];

    final connections = await loadConnections(workspaceId, connector);

    return _toolRecords(connector, connectorTools, connections);
  }

  void _addConnections(
    Map<String, _ConnectorConnectionRecord> connectionsById,
    ConnectorDefinition connector,
    List<ConnectorConnectionCandidate> connections,
  ) {
    for (final connection in connections) {
      final item = connectionsById.putIfAbsent(
        connection.id,
        () => _ConnectorConnectionRecord(
          id: connection.id,
          name: connection.name,
        ),
      );
      final _ = item.connectorIds.add(connector.identifier);
    }
  }

  List<Map<String, Object?>> _toolRecords(
    ConnectorDefinition connector,
    List<ConnectorToolDefinition> tools,
    List<ConnectorConnectionCandidate> connections,
  ) {
    final connectionOptions = _connectionOptions(connections);

    return [
      for (final tool in tools)
        if (!tool.requiresConnection || connectionOptions.isNotEmpty)
          _toolRecord(connector, tool, connectionOptions),
    ];
  }

  Map<String, Object?> _toolRecord(
    ConnectorDefinition connector,
    ConnectorToolDefinition tool,
    List<Map<String, String>> connectionOptions,
  ) => {
    'toolId': _ConnectorToolCatalog.toolId(connector, tool),
    'connectorId': connector.identifier,
    'connectorName': connector.title,
    'name': tool.title,
    'description': tool.description,
    'inputSchema': Map<String, Object?>.from(tool.inputJsonSchema),
    'revision': _ConnectorToolCatalog.revision(connector, tool),
    'requiresConnection': tool.requiresConnection,
    'connections': connectionOptions,
  };

  List<Map<String, String>> _connectionOptions(
    List<ConnectorConnectionCandidate> connections,
  ) => [
    for (final connection in connections)
      {'id': connection.id, 'name': connection.name},
  ];

  int _compareToolIds(Map<String, Object?> left, Map<String, Object?> right) =>
      '${left['toolId']}'.compareTo('${right['toolId']}');
}

class const ConnectorCommandUsecase({
  required final ConnectorConnectionsLoader loadConnections,
  required final ConnectorToolRunner runTool,
  final List<ConnectorDefinition> connectors = const [],
}) {
  Future<Object?> call({
    required String workspaceId,
    required String commandName,
    required Map<String, dynamic> arguments,
    String operationId = '',
  }) async {
    try {
      return await _dispatch(workspaceId, commandName, arguments, operationId);
    } on AgentToolExecutionFailure catch (failure, stackTrace) {
      if (_authorizationFailure(failure)) {
        rethrow;
      }
      _throwExecutionFailure(stackTrace);
    } on _ConnectorCommandException catch (error, stackTrace) {
      _throwFailure(error, stackTrace);
    } on FormatException catch (_, stackTrace) {
      _throwInvalidArguments(stackTrace);
    } on Object catch (_, stackTrace) {
      _throwExecutionFailure(stackTrace);
    }
  }

  Future<Object?> _dispatch(
    String workspaceId,
    String commandName,
    Map<String, dynamic> arguments,
    String operationId,
  ) => switch (commandName) {
    listConnectorConnectionsToolName => _ConnectorCommandDiscovery(
      connectors: connectors,
      loadConnections: loadConnections,
    ).listConnections(workspaceId),
    listConnectorToolsToolName => _ConnectorCommandDiscovery(
      connectors: connectors,
      loadConnections: loadConnections,
    ).listTools(workspaceId),
    executeConnectorToolName => _ConnectorCommandExecution(
      connectors: connectors,
      loadConnections: loadConnections,
      runTool: runTool,
    ).execute(workspaceId, arguments, operationId),
    _ => throw const _ConnectorCommandException(
      code: 'unknown_command',
      message: 'Unknown Connector command.',
    ),
  };

  static Never _throwExecutionFailure(StackTrace stackTrace) =>
      _throwCommandFailure(
        stackTrace,
        message: 'Connector command failed. Check the Connection and retry.',
      );

  static Never _throwCommandFailure(
    StackTrace stackTrace, {
    required String message,
  }) {
    final error = _ConnectorCommandException(
      code: 'execution_failed',
      message: message,
    );
    _throwFailure(error, stackTrace);
  }

  static Never _throwFailure(
    _ConnectorCommandException error,
    StackTrace stackTrace,
  ) => Error.throwWithStackTrace(_toolFailure(error, stackTrace), stackTrace);
}

class _ConnectorCommandExecution({
  required final List<ConnectorDefinition> connectors,
  required final ConnectorConnectionsLoader loadConnections,
  required final ConnectorToolRunner runTool,
}) {
  Future<Object?> execute(
    String workspaceId,
    Map<String, dynamic> arguments,
    String operationId,
  ) async {
    final request = _ConnectorExecutionArgumentParser.parse(arguments);
    final execution = await _resolveExecution(workspaceId, request);

    return await _runConnectorTool(
      workspaceId: workspaceId,
      connector: execution.connector,
      tool: execution.tool,
      arguments: {
        ...execution.arguments,
        if ((request.operationId ?? operationId).isNotEmpty)
          '_connectorOperationId': request.operationId ?? operationId,
      },
    );
  }

  Future<_ResolvedConnectorExecution> _resolveExecution(
    String workspaceId,
    _ConnectorExecutionRequest request,
  ) async {
    final descriptor = _resolveTool(request.toolId);
    final connector = descriptor.connector;
    final tool = descriptor.tool;
    _validateToolContract(request, connector, tool);
    final connectionId = await _resolveConnectionId(
      workspaceId: workspaceId,
      connector: connector,
      request: request,
      tool: tool,
    );

    return (
      connector: connector,
      tool: tool,
      arguments: _executionArguments(request.arguments, connectionId),
    );
  }

  void _validateToolContract(
    _ConnectorExecutionRequest request,
    ConnectorDefinition connector,
    ConnectorToolDefinition tool,
  ) {
    _validateRevision(request.revision, connector, tool);
    _validateArguments(
      Map<String, Object?>.from(tool.inputJsonSchema),
      request.arguments,
    );
  }

  Future<String?> _resolveConnectionId({
    required String workspaceId,
    required ConnectorDefinition connector,
    required _ConnectorExecutionRequest request,
    required ConnectorToolDefinition tool,
  }) async {
    final connections = await _currentConnections(
      workspaceId: workspaceId,
      connector: connector,
      requiresConnection: tool.requiresConnection,
    );

    return _selectConnection(
      connections: connections,
      explicitConnectionId: request.connectionId,
      requiresConnection: tool.requiresConnection,
    );
  }

  void _validateRevision(
    String? requestedRevision,
    ConnectorDefinition connector,
    ConnectorToolDefinition tool,
  ) {
    final currentRevision = _ConnectorToolCatalog.revision(connector, tool);
    if (requestedRevision != null && requestedRevision != currentRevision) {
      throw const _ConnectorCommandException(
        code: 'stale_contract',
        message: 'Connector tool contract changed. Refresh and retry.',
      );
    }
  }

  void _validateArguments(
    Map<String, Object?> inputSchema,
    Map<String, Object?> arguments,
  ) {
    try {
      validateToolArguments(inputSchema, arguments);
    } on FormatException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const _ConnectorCommandException(
          code: 'invalid_tool_arguments',
          message:
              'Arguments do not match this Connector tool schema. Refresh the '
              'contract and retry.',
        ),
        stackTrace,
      );
    }
  }

  Future<List<ConnectorConnectionCandidate>> _currentConnections({
    required String workspaceId,
    required ConnectorDefinition connector,
    required bool requiresConnection,
  }) async {
    if (!requiresConnection) return const [];

    return await loadConnections(workspaceId, connector);
  }

  Map<String, dynamic> _executionArguments(
    Map<String, Object?> arguments,
    String? connectionId,
  ) {
    final executionArguments = Map<String, dynamic>.from(arguments);
    if (connectionId != null) {
      executionArguments['connectionId'] = connectionId;
    }

    return executionArguments;
  }

  Future<Object?> _runConnectorTool({
    required String workspaceId,
    required ConnectorDefinition connector,
    required ConnectorToolDefinition tool,
    required Map<String, dynamic> arguments,
  }) async {
    try {
      return await runTool(
        workspaceId: workspaceId,
        connector: connector,
        tool: tool,
        arguments: arguments,
      );
    } on AgentToolExecutionFailure {
      rethrow;
    } on Object catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const _ConnectorCommandException(
          code: 'execution_failed',
          message: 'Connector tool failed. Check the Connection and retry.',
        ),
        stackTrace,
      );
    }
  }

  ({ConnectorDefinition connector, ConnectorToolDefinition tool}) _resolveTool(
    String toolId,
  ) {
    for (final connector in connectors) {
      final tool = _ConnectorToolCatalog.connectorTools(connector)
          .firstWhereOrNull(
            (tool) => _ConnectorToolCatalog.toolId(connector, tool) == toolId,
          );
      if (tool != null) return (connector: connector, tool: tool);
    }
    throw const _ConnectorCommandException(
      code: 'unknown_tool',
      message: 'Unknown Connector tool ID. Refresh Connector tools and retry.',
    );
  }
}

class _ConnectorExecutionArgumentParser {
  static _ConnectorExecutionRequest parse(Map<String, dynamic> arguments) {
    final toolId = _requiredToolId(arguments);
    final rawArguments = arguments['args'];
    if (rawArguments is! Map) {
      throw const _ConnectorCommandException(
        code: 'invalid_arguments',
        message: 'args must be an object.',
      );
    }

    return (
      toolId: toolId,
      arguments: _stringKeyedArguments(rawArguments),
      connectionId: _optionalString(arguments, 'connectionId'),
      revision: _optionalString(arguments, 'revision'),
      operationId: _operationId(arguments),
    );
  }

  static String _requiredToolId(Map<String, dynamic> arguments) {
    final toolId = arguments['toolId'];
    if (toolId is String && toolId.trim().isNotEmpty) return toolId.trim();

    throw const _ConnectorCommandException(
      code: 'invalid_arguments',
      message: 'toolId must be a non-empty string.',
    );
  }

  static String? _optionalString(Map<String, dynamic> arguments, String key) {
    final value = arguments[key];
    if (value == null || value is String) return value as String?;

    throw _ConnectorCommandException(
      code: 'invalid_arguments',
      message: '$key must be a string.',
    );
  }

  static String? _operationId(Map<String, dynamic> arguments) {
    final value = arguments['operationId'];
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    throw const _ConnectorCommandException(
      code: 'invalid_arguments',
      message: 'operationId must be a non-empty string.',
    );
  }

  static Map<String, Object?> _stringKeyedArguments(
    Map<Object?, Object?> arguments,
  ) {
    final normalized = <String, Object?>{};
    for (final entry in arguments.entries) {
      final key = entry.key;
      if (key is! String) {
        throw const _ConnectorCommandException(
          code: 'invalid_arguments',
          message: 'args keys must be strings.',
        );
      }
      normalized[key] = entry.value;
    }

    return normalized;
  }
}

String? _selectConnection({
  required List<ConnectorConnectionCandidate> connections,
  required String? explicitConnectionId,
  required bool requiresConnection,
}) {
  if (!requiresConnection) {
    return _selectOptionalConnection(connections, explicitConnectionId);
  }

  return _selectRequiredConnection(connections, explicitConnectionId);
}

String? _selectOptionalConnection(
  List<ConnectorConnectionCandidate> connections,
  String? connectionId,
) {
  if (connectionId == null) return null;
  if (_hasConnection(connections, connectionId)) return connectionId;

  throw const _ConnectorCommandException(
    code: 'connection_unavailable',
    message: 'Connection is not available for this Connector tool.',
  );
}

String _selectRequiredConnection(
  List<ConnectorConnectionCandidate> connections,
  String? connectionId,
) {
  if (connections.isEmpty) {
    throw const _ConnectorCommandException(
      code: 'connection_required',
      message:
          'No enabled Connection is available for this tool. Connect one in '
          'the current workspace and retry.',
    );
  }
  if (connectionId != null) {
    if (_hasConnection(connections, connectionId)) return connectionId;

    throw const _ConnectorCommandException(
      code: 'connection_unavailable',
      message: 'Connection is not available for this Connector tool.',
    );
  }
  if (connections.length == 1) return connections.single.id;

  throw const _ConnectorCommandException(
    code: 'connection_selection_required',
    message:
        'Choose a Connection by passing connectionId to '
        'execute_connector_tool.',
  );
}

bool _hasConnection(
  List<ConnectorConnectionCandidate> connections,
  String id,
) => connections.any((connection) => connection.id == id);

class const _ConnectorCommandException({
  required final String code,
  required final String message,
}) implements Exception;

AgentToolExecutionFailure _toolFailure(
  _ConnectorCommandException failure,
  StackTrace stackTrace,
) => AgentToolExecutionFailure(
  responseRaw: jsonEncode({
    'error': {'code': failure.code, 'message': failure.message},
    'recoverable': true,
  }),
  error: failure,
  stackTrace: stackTrace,
  failurePhase: 'connector.command',
);

final connectorCommandUsecaseProvider = Provider<ConnectorCommandUsecase>((
  ref,
) {
  final listConnections = ref.watch(
    listConnectorConnectionCandidatesUsecaseProvider,
  );
  final runConnectorTool = ref.watch(runConnectorToolUsecaseProvider);

  return ConnectorCommandUsecase(
    loadConnections: (workspaceId, connector) => listConnections.forConnector(
      workspaceId: workspaceId,
      connector: connector,
    ),
    runTool:
        ({
          required workspaceId,
          required connector,
          required tool,
          required arguments,
        }) => runConnectorTool.call((
          workspaceId: workspaceId,
          connectorId: connector.identifier,
          toolSlug: tool.slug,
          arguments: Map<String, dynamic>.from(arguments)
            ..remove('_connectorOperationId'),
          operationId: arguments['_connectorOperationId'] as String? ?? '',
        )),
    connectors: connectorDefinitions,
  );
});

Never _throwInvalidArguments(StackTrace stackTrace) =>
    ConnectorCommandUsecase._throwFailure(
      const _ConnectorCommandException(
        code: 'invalid_arguments',
        message: 'Arguments do not match the current Connector contract.',
      ),
      stackTrace,
    );

bool _authorizationFailure(AgentToolExecutionFailure failure) =>
    failure.failurePhase == 'connector.authorization' ||
    failure.failurePhase == 'connector.write' ||
    failure.failurePhase == 'connector.read';
