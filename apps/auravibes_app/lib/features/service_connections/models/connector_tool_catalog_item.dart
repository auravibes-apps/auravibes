class const ConnectorToolCatalogItem({
  required final String toolId,
  required final String connectorName,
  required final String title,
  required final String description,
  final Map<String, dynamic> inputJsonSchema = const {},
  final bool requiresConnection = false,
});
