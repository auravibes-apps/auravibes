import 'dart:convert';

import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_app_skill_tool_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:collection/collection.dart';
import 'package:riverpod/riverpod.dart';

typedef ConnectorConnectionsLoader =
    Future<List<AppSkillCredentialCandidate>> Function(
      String workspaceId,
      AppSkillDefinition connector,
    );

typedef ConnectorToolRunner = Future<Object?> Function({
  required String workspaceId,
  required AppSkillDefinition connector,
  required AppSkillToolDefinition tool,
  required Map<String, dynamic> arguments,
});

typedef _ConnectorExecutionRequest = ({
  String toolId,
  Map<String, Object?> arguments,
  String? connectionId,
  String? revision,
});

typedef _ResolvedConnectorExecution = ({
  AppSkillDefinition connector,
  AppSkillToolDefinition tool,
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
  static List<AppSkillToolDefinition> connectorTools(
    AppSkillDefinition connector,
  ) => connector.tools
      .where((tool) => tool.urlTemplate != null)
      .toList(growable: false);

  static String toolId(
    AppSkillDefinition connector,
    AppSkillToolDefinition tool,
  ) => connectorToolId(connector, tool);

  static String revision(
    AppSkillDefinition connector,
    AppSkillToolDefinition tool,
  ) => connectorToolRevision(connector, tool);
}

class _ConnectorCommandDiscovery({
  required final List<AppSkillDefinition> connectors,
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
    AppSkillDefinition connector,
  ) async {
    final connectorTools = _ConnectorToolCatalog.connectorTools(connector);
    if (connectorTools.isEmpty) return const [];

    final connections = await loadConnections(workspaceId, connector);

    return _toolRecords(connector, connectorTools, connections);
  }

  void _addConnections(
    Map<String, _ConnectorConnectionRecord> connectionsById,
    AppSkillDefinition connector,
    List<AppSkillCredentialCandidate> connections,
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
    AppSkillDefinition connector,
    List<AppSkillToolDefinition> tools,
    List<AppSkillCredentialCandidate> connections,
  ) {
    final connectionOptions = _connectionOptions(connections);

    return [
      for (final tool in tools) _toolRecord(connector, tool, connectionOptions),
    ];
  }

  Map<String, Object?> _toolRecord(
    AppSkillDefinition connector,
    AppSkillToolDefinition tool,
    List<Map<String, String>> connectionOptions,
  ) => {
    'toolId': _ConnectorToolCatalog.toolId(connector, tool),
    'connectorId': connector.identifier,
    'connectorName': connector.title,
    'name': tool.title,
    'description': tool.description,
    'inputSchema': Map<String, Object?>.from(tool.inputJsonSchema),
    'revision': _ConnectorToolCatalog.revision(connector, tool),
    'requiresConnection': tool.requiresCredential,
    'connections': connectionOptions,
  };

  List<Map<String, String>> _connectionOptions(
    List<AppSkillCredentialCandidate> connections,
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
  final List<AppSkillDefinition> connectors = const [],
}) {
  Future<Object?> call({
    required String workspaceId,
    required String commandName,
    required Map<String, dynamic> arguments,
  }) async {
    try {
      return await _dispatch(workspaceId, commandName, arguments);
    } on AgentToolExecutionFailure catch (_, stackTrace) {
      _throwCommandFailure(
        stackTrace,
        message: 'Connector command failed. Check the Connection and retry.',
      );
    } on _ConnectorCommandException catch (error, stackTrace) {
      _throwFailure(error, stackTrace);
    } on FormatException catch (_, stackTrace) {
      _throwFailure(
        const _ConnectorCommandException(
          code: 'invalid_arguments',
          message: 'Arguments do not match the current Connector contract.',
        ),
        stackTrace,
      );
    } on Object catch (_, stackTrace) {
      _throwCommandFailure(
        stackTrace,
        message: 'Connector command failed. Check the Connection and retry.',
      );
    }
  }

  Future<Object?> _dispatch(
    String workspaceId,
    String commandName,
    Map<String, dynamic> arguments,
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
    ).execute(workspaceId, arguments),
    _ => throw const _ConnectorCommandException(
      code: 'unknown_command',
      message: 'Unknown Connector command.',
    ),
  };

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
  required final List<AppSkillDefinition> connectors,
  required final ConnectorConnectionsLoader loadConnections,
  required final ConnectorToolRunner runTool,
}) {
  Future<Object?> execute(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final request = _ConnectorExecutionArgumentParser.parse(arguments);
    final execution = await _resolveExecution(workspaceId, request);

    return await _runConnectorTool(
      workspaceId: workspaceId,
      connector: execution.connector,
      tool: execution.tool,
      arguments: execution.arguments,
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
    AppSkillDefinition connector,
    AppSkillToolDefinition tool,
  ) {
    _validateRevision(request.revision, connector, tool);
    _validateArguments(
      Map<String, Object?>.from(tool.inputJsonSchema),
      request.arguments,
    );
  }

  Future<String?> _resolveConnectionId({
    required String workspaceId,
    required AppSkillDefinition connector,
    required _ConnectorExecutionRequest request,
    required AppSkillToolDefinition tool,
  }) async {
    final connections = await _currentConnections(
      workspaceId: workspaceId,
      connector: connector,
      requiresConnection: tool.requiresCredential,
    );

    return _selectConnection(
      connections: connections,
      explicitConnectionId: request.connectionId,
      requiresConnection: tool.requiresCredential,
    );
  }

  void _validateRevision(
    String? requestedRevision,
    AppSkillDefinition connector,
    AppSkillToolDefinition tool,
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

  Future<List<AppSkillCredentialCandidate>> _currentConnections({
    required String workspaceId,
    required AppSkillDefinition connector,
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
      executionArguments['credentialId'] = connectionId;
    }

    return executionArguments;
  }

  Future<Object?> _runConnectorTool({
    required String workspaceId,
    required AppSkillDefinition connector,
    required AppSkillToolDefinition tool,
    required Map<String, dynamic> arguments,
  }) async {
    try {
      return await runTool(
        workspaceId: workspaceId,
        connector: connector,
        tool: tool,
        arguments: arguments,
      );
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

  ({AppSkillDefinition connector, AppSkillToolDefinition tool}) _resolveTool(
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
  required List<AppSkillCredentialCandidate> connections,
  required String? explicitConnectionId,
  required bool requiresConnection,
}) {
  if (!requiresConnection) {
    return _selectOptionalConnection(connections, explicitConnectionId);
  }

  return _selectRequiredConnection(connections, explicitConnectionId);
}

String? _selectOptionalConnection(
  List<AppSkillCredentialCandidate> connections,
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
  List<AppSkillCredentialCandidate> connections,
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

bool _hasConnection(List<AppSkillCredentialCandidate> connections, String id) =>
    connections.any((connection) => connection.id == id);

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
    listAppSkillCredentialCandidatesUsecaseProvider,
  );
  final runAppSkillTool = ref.watch(runAppSkillToolUsecaseProvider);

  return ConnectorCommandUsecase(
    loadConnections: (workspaceId, connector) =>
        listConnections.call(workspaceId: workspaceId, skill: connector),
    runTool:
        ({
          required workspaceId,
          required connector,
          required tool,
          required arguments,
        }) => runAppSkillTool.call(
          workspaceId: workspaceId,
          skillSlug: connector.slug,
          toolSlug: tool.slug,
          arguments: arguments,
        ),
    connectors: serviceSkillDefinitions,
  );
});
