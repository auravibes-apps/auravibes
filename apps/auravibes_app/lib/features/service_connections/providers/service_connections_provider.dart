import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/usecases/cloud_service_connection_usecases.dart';
import 'package:auravibes_app/features/service_connections/usecases/watch_service_connection_list_items_usecase.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'service_connections_provider.g.dart';

@riverpod
Stream<List<ServiceConnectionListItem>> serviceConnections(
  Ref ref,
  String workspaceId,
) async* {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (gateway != null) {
    final modelStore = await ref.watch(
      modelConnectionStoreProvider(workspaceId).future,
    );
    final serviceUsecases = CloudServiceConnectionUsecases(
      CloudWorkspaceResourceStore(gateway),
    );
    yield* Rx.combineLatest2(
      modelStore.watchModelConnections(
        ModelConnectionFilter(workspaces: [workspaceId]),
      ),
      serviceUsecases.watch(),
      (models, services) => [
        ...models.map(ServiceConnectionListItem.fromModelConnection),
        ...services.map(
          (connection) => _cloudServiceConnectionItem(
            connection,
            workspaceId,
          ),
        ),
      ]..sort((a, b) => a.name.compareTo(b.name)),
    );

    return;
  }

  final usecase = WatchServiceConnectionListItemsUsecase(
    ref.watch(appDatabaseProvider),
    ref.watch(modelConnectionRepositoryProvider),
    ref.watch(
      skillCredentialDefinitionsRepositoryProvider,
    ),
    ref.watch(skillCredentialsRepositoryProvider),
    DateTime.now,
  );

  yield* usecase(workspaceId);
}

ServiceConnectionListItem _cloudServiceConnectionItem(
  CloudServiceConnection connection,
  String workspaceId,
) => ServiceConnectionListItem(
  id: connection.id,
  workspaceId: workspaceId,
  name: connection.name,
  serviceName: connection.serviceId,
  kind: ServiceConnectionListItemKind.skillCredential,
  keySuffix: connection.keySuffix,
  credentialDefinitionId: connection.credentialDefinitionId,
  mcpServerId: null,
  authenticationType: null,
  displayStatus: connection.hasSecret
      ? ServiceConnectionDisplayStatus.connected
      : ServiceConnectionDisplayStatus.unknown,
  expiresAt: null,
  lastRefreshedAt: null,
  lastAuthError: null,
  metadataValues: const [],
  canRefresh: false,
  canReconnect: false,
);
