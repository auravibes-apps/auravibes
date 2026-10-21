import 'package:auravibes_engine/src/connectors/models/connector_tool_request_template.dart';
import 'package:auravibes_engine/src/connectors/models/connector_tool_request_definition.dart';

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
    return template == null
        ? null
        : ConnectorToolRequestDefinition(
            request: template.template,
            inputs: template.inputs,
            credentialDefinitions: template.credentialDefinitions,
            inputSchemaOverride: Map<String, Object?>.from(inputJsonSchema),
          );
  }
}
