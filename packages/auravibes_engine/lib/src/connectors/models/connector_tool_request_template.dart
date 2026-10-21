import 'package:auravibes_engine/src/connectors/models/connector_credential_attribute_definition.dart';
import 'package:auravibes_engine/src/connectors/models/connector_tool_input_definition.dart';
import 'package:auravibes_engine/src/connectors/models/connector_request_template.dart';

class const ConnectorToolRequestTemplate({
  required final ConnectorRequestTemplate template,
  required final Map<String, ConnectorToolInputDefinition> inputs,
  final Map<String, ConnectorCredentialAttributeDefinition> credentialDefinitions =
      const {},
});
