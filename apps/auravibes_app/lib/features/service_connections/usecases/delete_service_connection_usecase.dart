import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/cloud_service_connection_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_service_connection_usecase.g.dart';

class DeleteServiceConnectionUsecase({
  required ModelConnectionStore modelConnectionRepository,
  required final Future<void> Function(String id) deleteConnectorConnection,
}) {
  final ModelConnectionStore modelConnectionStore = modelConnectionRepository;
  Future<void> call({
    required String connectionId,
    required ServiceConnectionListItemKind kind,
  }) {
    return switch (kind) {
      .modelProvider => modelConnectionStore.deleteModelConnection(
        connectionId,
      ),
      .connector => deleteConnectorConnection(connectionId),
      .mcpServer => throw StateError(
        'MCP server service connections cannot be deleted by this action.',
      ),
    };
  }
}

@riverpod
Future<DeleteServiceConnectionUsecase> deleteServiceConnectionUsecase(
  Ref ref,
  String workspaceId,
) async {
  final link = ref.keepAlive();
  try {
    return DeleteServiceConnectionUsecase(
      modelConnectionRepository: await ref.watch(
        modelConnectionStoreProvider(workspaceId).future,
      ),
      deleteConnectorConnection: await _deleteConnectorConnection(
        ref,
        workspaceId,
      ),
    );
  } finally {
    link.close();
  }
}

Future<Future<void> Function(String id)> _deleteConnectorConnection(
  Ref ref,
  String workspaceId,
) async {
  final gateway = await _cloudGateway(ref, workspaceId);

  if (gateway != null) {
    return CloudServiceConnectionUsecases(.new(gateway)).deleteById;
  }

  return _localDeleteOperation(ref, workspaceId);
}

Future<CloudWorkspaceStateGateway?> _cloudGateway(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );

  return await ref.watch(cloudWorkspaceStateGatewayProvider(session).future);
}

Future<void> Function(String id) _localDeleteOperation(
  Ref ref,
  String workspaceId,
) {
  final serviceConnections = ref.watch(serviceConnectionRepositoryProvider);

  Future<void> deleteLocalConnectorConnection(String id) => serviceConnections
      .deleteConnectorConnection(id, workspaceId: workspaceId);

  return deleteLocalConnectorConnection;
}
// Top-level API/provider declarations are required by their consumers.
