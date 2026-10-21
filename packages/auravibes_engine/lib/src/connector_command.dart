import 'package:auravibes_engine/src/tool_spec.dart';

const listConnectorConnectionsToolName = 'list_connector_connections';
const listConnectorToolsToolName = 'list_connector_tools';
const executeConnectorToolName = 'execute_connector_tool';

const connectorToolCommandNames = <String>{
  listConnectorConnectionsToolName,
  listConnectorToolsToolName,
  executeConnectorToolName,
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
