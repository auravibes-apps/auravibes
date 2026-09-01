import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/usecases/cloud_service_connection_usecases.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_service_connection_usecase.g.dart';

class DeleteServiceConnectionUsecase({
  required ModelConnectionStore modelConnectionRepository,
  required final Future<void> Function(String id) deleteSkillCredential,
}) {
  final ModelConnectionStore modelConnectionStore = modelConnectionRepository;
  Future<void> call({
    required String connectionId,
    required ServiceConnectionListItemKind kind,
  }) {
    return switch (kind) {
      ServiceConnectionListItemKind.modelProvider =>
        modelConnectionStore.deleteModelConnection(connectionId),
      ServiceConnectionListItemKind.skillCredential => deleteSkillCredential(
        connectionId,
      ),
      ServiceConnectionListItemKind.mcpServer => throw StateError(
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
    final session = await ref.watch(
      workspaceSessionForRouteProvider(workspaceId).future,
    );
    final gateway = await ref.watch(
      cloudWorkspaceStateGatewayProvider(session).future,
    );

    return DeleteServiceConnectionUsecase(
      modelConnectionRepository: await ref.watch(
        modelConnectionStoreProvider(workspaceId).future,
      ),
      deleteSkillCredential: gateway == null
          ? ref.watch(skillCredentialsRepositoryProvider).deleteCredential
          : CloudServiceConnectionUsecases(CloudWorkspaceResourceStore(gateway))
                .deleteById,
    );
  } finally {
    link.close();
  }
}
// Top-level API/provider declarations are required by their consumers.
