import 'package:auravibes_engine/auravibes_engine.dart';

class const ConnectorToolCatalogItem({
  required final String toolId,
  required final String connectorName,
  required final String title,
  required final String description,
  final String? connectorId,
  final ConnectorToolDefinition? toolDefinition,
  final Map<String, dynamic> inputJsonSchema = const {},
  final bool requiresConnection = false,
});
