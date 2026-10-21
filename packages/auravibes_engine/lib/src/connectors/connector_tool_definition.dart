import 'package:auravibes_engine/src/connectors/execution/resolve_connector_request_template.dart';
import 'package:auravibes_engine/src/connectors/models/connector_tool_request_definition.dart';
import 'package:auravibes_engine/src/connectors/models/connector_tool_request_template.dart';

const Map<String, dynamic> defaultConnectorToolInputJsonSchema = {
  'type': 'object',
  'properties': <String, Object?>{},
  'required': <String>[],
  'additionalProperties': false,
};

class const ConnectorToolDefinition({
  required final String slug,
  required final String title,
  required final String description,
  final Map<String, dynamic> inputJsonSchema =
      defaultConnectorToolInputJsonSchema,
  final ConnectorToolRequestTemplate? urlTemplate,
  final bool requiresConnection = false,
}) {
  ConnectorToolRequestDefinition? get definition {
    final template = urlTemplate;
    if (template == null) return null;

    final definition = ConnectorToolRequestDefinition(
      request: template.template,
      inputs: template.inputs,
      credentialDefinitions: template.credentialDefinitions,
      inputSchemaOverride: Map<String, Object?>.from(inputJsonSchema),
    );
    validateConnectorToolRequestDefinition(definition);

    return definition;
  }
}
