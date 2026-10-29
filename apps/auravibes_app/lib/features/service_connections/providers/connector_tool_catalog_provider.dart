import 'package:auravibes_app/features/service_connections/models/connector_tool_catalog_item.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connector_tool_catalog_provider.g.dart';

@riverpod
List<ConnectorToolCatalogItem> connectorToolCatalog(Ref _) {
  return _connectorToolCatalog(connectorDefinitions);
}

List<ConnectorToolCatalogItem> _connectorToolCatalog(
  Iterable<ConnectorDefinition> connectors,
) =>
    [for (final connector in connectors) ..._connectorTools(connector)]
      ..sort(_compareConnectorTools);

List<ConnectorToolCatalogItem> _connectorTools(ConnectorDefinition connector) =>
    [
      for (final tool in connector.tools)
        if (tool.urlTemplate != null)
          ConnectorToolCatalogItem(
            toolId: connectorToolId(connector, tool),
            connectorName: connector.title,
            title: tool.title,
            description: tool.description,
            connectorId: connector.identifier,
            toolDefinition: tool,
            inputJsonSchema: tool.inputJsonSchema,
            requiresConnection: tool.requiresConnection,
          ),
    ];

int _compareConnectorTools(
  ConnectorToolCatalogItem left,
  ConnectorToolCatalogItem right,
) {
  final connectorOrder = left.connectorName.compareTo(right.connectorName);

  return connectorOrder == 0
      ? left.title.compareTo(right.title)
      : connectorOrder;
}
