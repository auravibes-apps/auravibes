import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/usecases/cloud_service_connection_usecases.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_service_connection_usecase.g.dart';

class DeleteServiceConnectionUsecase {
  DeleteServiceConnectionUsecase({
    required ModelConnectionStore modelConnectionRepository,
    SkillCredentialsRepository? skillCredentialsRepository,
    Future<void> Function(String id)? deleteSkillCredential,
  }) : modelConnectionStore = modelConnectionRepository,
       deleteSkillCredential =
           deleteSkillCredential ??
           (skillCredentialsRepository == null
               ? _missingSkillCredentialStore
               : skillCredentialsRepository.deleteCredential);

  final ModelConnectionStore modelConnectionStore;
  final Future<void> Function(String id) deleteSkillCredential;

  static Future<void> _missingSkillCredentialStore(String _) =>
      Future<void>.error(StateError('Skill credential store is unavailable'));

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

@Riverpod(dependencies: [cloudWorkspaceStateGateway])
Future<DeleteServiceConnectionUsecase> deleteServiceConnectionUsecase(
  Ref ref,
  String workspaceId,
) async {
  final gateway = await ref.watch(cloudWorkspaceStateGatewayProvider.future);

  return DeleteServiceConnectionUsecase(
    modelConnectionRepository: await ref.watch(
      modelConnectionStoreProvider(workspaceId).future,
    ),
    deleteSkillCredential: gateway == null
        ? ref.watch(skillCredentialsRepositoryProvider).deleteCredential
        : CloudServiceConnectionUsecases(
            CloudWorkspaceResourceStore(gateway),
          ).deleteById,
  );
}
