import 'dart:convert';

import 'package:auravibes_engine/src/connectors/connector_definition.dart';
import 'package:auravibes_engine/src/connectors/connector_tool_definition.dart';
import 'package:auravibes_engine/src/tool_spec.dart';
import 'package:crypto/crypto.dart';

const listConnectorConnectionsToolName = 'list_connector_connections';
const listConnectorToolsToolName = 'list_connector_tools';
const executeConnectorToolName = 'execute_connector_tool';

const connectorToolCommandNames = <String>{
  listConnectorConnectionsToolName,
  listConnectorToolsToolName,
  executeConnectorToolName,
};

String connectorToolId(
  ConnectorDefinition connector,
  ConnectorToolDefinition tool,
) => 'connector/${connector.identifier}/${tool.slug}';

String connectorToolRevision(
  ConnectorDefinition connector,
  ConnectorToolDefinition tool,
) {
  final contract = _canonicalJson({
    'toolId': connectorToolId(connector, tool),
    'connectorId': connector.identifier,
    'toolSlug': tool.slug,
    'description': tool.description,
    'inputSchema': tool.inputJsonSchema,
    'requiresConnection': tool.requiresConnection,
    'compatibleConnectionProviderIds': connector.compatibleModelProviderIds,
    'definition': tool.definition?.toJson(),
  });
  return sha256.convert(utf8.encode(contract)).toString();
}

String _canonicalJson(Object value) => jsonEncode(_canonicalize(value));

Object? _canonicalize(Object? value) => switch (value) {
  final Map<Object?, Object?> map => {
    for (final key in map.keys.map((key) => '$key').toList()..sort())
      key: _canonicalize(map[key]),
  },
  final List<Object?> list => [for (final item in list) _canonicalize(item)],
  _ => value,
};

List<ToolSpec> buildConnectorCommandToolSpecs() => [
  ToolSpec(
    name: listConnectorConnectionsToolName,
    description: 'List Connections available in the current workspace.',
    inputJsonSchema: _emptyObjectSchema,
  ),
  ToolSpec(
    name: listConnectorToolsToolName,
    description:
        'List Connector tool IDs, current input schemas, revisions, and '
        'matching workspace Connections.',
    inputJsonSchema: _emptyObjectSchema,
  ),
  ToolSpec(
    name: executeConnectorToolName,
    description:
        'Execute a Connector tool by stable tool ID. The current tool '
        'contract and workspace Connection access are checked at execution. '
        'Reuse an existing operationId for write retries; uncertain writes '
        'require provider reconciliation and cannot be blindly repeated.',
    inputJsonSchema: const {
      'type': 'object',
      'properties': {
        'toolId': {'type': 'string'},
        'args': {'type': 'object'},
        'connectionId': {'type': 'string'},
        'revision': {'type': 'string'},
        'operationId': {
          'type': 'string',
          'description':
              'Reuse the returned operationId when checking or '
              'retrying a write. Use a new ID only for an intentional '
              'new action.',
        },
      },
      'required': ['toolId', 'args'],
      'additionalProperties': false,
    },
  ),
];

const _emptyObjectSchema = <String, Object?>{
  'type': 'object',
  'properties': <String, Object?>{},
  'required': <String>[],
  'additionalProperties': false,
};

/// Unknown targets conservatively require write approval; declared reads retain
/// their configured permission. Execution still validates the full contract.
bool connectorCommandMayWrite(
  Object? arguments,
  Iterable<ConnectorDefinition> connectors,
) {
  final target = connectorCommandTarget(arguments, connectors);
  final method = target?.urlTemplate?.template.method.value;
  return method != 'GET' && method != 'HEAD';
}

ConnectorToolDefinition? connectorCommandTarget(
  Object? arguments,
  Iterable<ConnectorDefinition> connectors,
) {
  final id = _commandTargetId(arguments);
  for (final connector in connectors) {
    final target = _targetInConnector(connector, id);
    if (target != null) return target;
  }
  return null;
}

ConnectorToolDefinition? _targetInConnector(
  ConnectorDefinition connector,
  Object? id,
) => connector.tools
    .where((tool) => connectorToolId(connector, tool) == id)
    .firstOrNull;

Object? _commandTargetId(Object? arguments) {
  try {
    final value = arguments is String ? jsonDecode(arguments) : arguments;
    return value is Map<String, dynamic> ? value['toolId'] : null;
  } on FormatException {
    return null;
  }
}
