import 'package:auravibes_app/features/service_connections/models/connector_capability_filter.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';

class const ConnectorCatalogItem({
  required final String id,
  required final String name,
  required final bool offersModels,
  required final bool offersTools,
  required final bool isConnected,
  required final int connectionCount,
  required final List<String> modelProviderIds,
}) {
  static List<ConnectorCatalogItem> fromOfferings(
    Iterable<ConnectorCatalogOffering> offerings, {
    required List<ServiceConnectionListItem> connections,
    ConnectorCapabilityFilter filter = .all,
  }) {
    final items = [
      for (final offering in _mergeOfferings(offerings))
        if (_matchesFilter(offering, filter))
          _catalogItem(offering, _connectionsFor(offering, connections)),
    ];

    return items..sort((a, b) => a.name.compareTo(b.name));
  }
}

class const ConnectorCatalogOffering({
  required final String id,
  required final String name,
  final bool offersModels = false,
  final bool offersTools = false,
  final List<String> serviceIds = const [],
  final List<String> modelProviderIds = const [],
});

Iterable<ConnectorCatalogOffering> _mergeOfferings(
  Iterable<ConnectorCatalogOffering> offerings,
) {
  final merged = <String, ConnectorCatalogOffering>{};
  for (final offering in offerings) {
    final existing = merged[offering.id];
    merged[offering.id] = existing == null
        ? offering
        : _mergeOffering(existing, offering);
  }

  return merged.values;
}

ConnectorCatalogOffering _mergeOffering(
  ConnectorCatalogOffering existing,
  ConnectorCatalogOffering offering,
) => ConnectorCatalogOffering(
  id: offering.id,
  name: existing.name,
  offersModels: existing.offersModels || offering.offersModels,
  offersTools: existing.offersTools || offering.offersTools,
  serviceIds: {..._serviceIds(existing), ..._serviceIds(offering)}.toList(),
  modelProviderIds: {
    ...existing.modelProviderIds,
    ...offering.modelProviderIds,
  }.toList(),
);

List<ServiceConnectionListItem> _connectionsFor(
  ConnectorCatalogOffering offering,
  List<ServiceConnectionListItem> connections,
) {
  final serviceIds = _serviceIds(offering);

  return connections
      .where(_isConnectorConnection)
      .where((connection) => serviceIds.contains(connection.serviceName))
      .toList();
}

ConnectorCatalogItem _catalogItem(
  ConnectorCatalogOffering offering,
  List<ServiceConnectionListItem> connections,
) => ConnectorCatalogItem(
  id: offering.id,
  name: offering.name,
  offersModels: offering.offersModels,
  offersTools: offering.offersTools,
  isConnected: connections.any(
    (connection) =>
        connection.displayStatus == ServiceConnectionDisplayStatus.connected,
  ),
  connectionCount: connections.length,
  modelProviderIds: offering.modelProviderIds,
);

bool _isConnectorConnection(ServiceConnectionListItem connection) =>
    connection.kind == ServiceConnectionListItemKind.modelProvider ||
    connection.kind == ServiceConnectionListItemKind.connector;

bool _matchesFilter(
  ConnectorCatalogOffering offering,
  ConnectorCapabilityFilter filter,
) => switch (filter) {
  .all => true,
  .models => offering.offersModels,
  .tools => offering.offersTools,
};

Iterable<String> _serviceIds(ConnectorCatalogOffering? offering) {
  if (offering == null) return const [];

  return {offering.id, ...offering.serviceIds};
}
