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
        'contract and workspace Connection access are checked at execution.',
    inputJsonSchema: const {
      'type': 'object',
      'properties': {
        'toolId': {'type': 'string'},
        'args': {'type': 'object'},
        'connectionId': {'type': 'string'},
        'revision': {'type': 'string'},
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
