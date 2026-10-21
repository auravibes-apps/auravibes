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
  final skillByProviderId = _modelProviderSkillsById();

  return [
    for (final provider in modelProviders)
      _modelProviderOffering(provider, skillByProviderId[provider.id]),
  ];
}

Map<String, AppSkillDefinition> _modelProviderSkillsById() => {
  for (final skill in serviceSkillDefinitions)
    for (final providerId in skill.compatibleModelProviderIds)
      providerId: skill,
};

ConnectorCatalogOffering _modelProviderOffering(
  ApiModelProviderEntity provider,
  AppSkillDefinition? skill,
) => ConnectorCatalogOffering(
  id: skill?.identifier ?? provider.id,
  name: skill?.title ?? provider.name,
  offersModels: true,
  serviceIds: [provider.id],
  modelProviderIds: [provider.id],
);

List<ConnectorCatalogOffering> _toolSkillOfferings() => [
  for (final skill in serviceSkillDefinitions.where(
    (skill) => skill.tools.isNotEmpty,
  ))
    ConnectorCatalogOffering(
      id: skill.identifier,
      name: skill.title,
      offersTools: true,
      serviceIds: skill.compatibleModelProviderIds,
    ),
];
