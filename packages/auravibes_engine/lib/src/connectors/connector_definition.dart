import 'package:auravibes_engine/src/connectors/connector_tool_definition.dart';

class const ConnectorDefinition({
  required final String identifier,
  required final String title,
  required final String description,
  final List<ConnectorToolDefinition> tools = const [],
  final List<String> compatibleModelProviderIds = const [],
});
