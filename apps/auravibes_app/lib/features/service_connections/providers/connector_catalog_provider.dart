import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/service_connections/models/connector_capability_filter.dart';
import 'package:auravibes_app/features/service_connections/models/connector_catalog_item.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connector_catalog_provider.g.dart';

@riverpod
Stream<List<ConnectorCatalogItem>> connectorCatalog(
  Ref ref,
  String workspaceId, {
  ConnectorCapabilityFilter filter = .all,
}) async* {
  final modelProviders = await ref.watch(
    apiModelProvidersProvider(workspaceId: workspaceId).future,
  );
  final connections = await ref.watch(
    serviceConnectionsProvider(workspaceId).future,
  );
  final offerings = _connectorOfferings(modelProviders);

  yield ConnectorCatalogItem.fromOfferings(
    offerings,
    connections: connections,
    filter: filter,
  );
}

List<ConnectorCatalogOffering> _connectorOfferings(
  List<ApiModelProviderEntity> modelProviders,
) => [..._modelProviderOfferings(modelProviders), ..._toolSkillOfferings()];

List<ConnectorCatalogOffering> _modelProviderOfferings(
  List<ApiModelProviderEntity> modelProviders,
) {
  final connectorByProviderId = _modelProviderConnectorsById();

  return [
    for (final provider in modelProviders)
      _modelProviderOffering(provider, connectorByProviderId[provider.id]),
  ];
}

Map<String, ConnectorDefinition> _modelProviderConnectorsById() => {
  for (final connector in connectorDefinitions)
    for (final providerId in connector.compatibleModelProviderIds)
      providerId: connector,
};

ConnectorCatalogOffering _modelProviderOffering(
  ApiModelProviderEntity provider,
  ConnectorDefinition? connector,
) => ConnectorCatalogOffering(
  id: connector?.identifier ?? provider.id,
  name: connector?.title ?? provider.name,
  offersModels: true,
  serviceIds: [provider.id],
  modelProviderIds: [provider.id],
);

List<ConnectorCatalogOffering> _toolSkillOfferings() => [
  for (final connector in connectorDefinitions.where(
    (connector) => connector.tools.isNotEmpty,
  ))
    ConnectorCatalogOffering(
      id: connector.identifier,
      name: connector.title,
      offersTools: true,
      serviceIds: connector.compatibleModelProviderIds,
    ),
];
