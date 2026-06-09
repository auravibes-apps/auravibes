import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:rxdart/rxdart.dart';

final StreamProviderFamily<List<ServiceConnectionListItem>, String>
serviceConnectionsProvider =
    StreamProvider.family<List<ServiceConnectionListItem>, String>((
      ref,
      workspaceId,
    ) {
      final modelConnectionRepository = ref.watch(
        modelConnectionRepositoryProvider,
      );
      final credentialDefinitionsRepository = ref.watch(
        skillCredentialDefinitionsRepositoryProvider,
      );
      final credentialsRepository = ref.watch(
        skillCredentialsRepositoryProvider,
      );

      return Rx.combineLatest3(
        modelConnectionRepository.watchModelConnections(
          ModelConnectionFilter(workspaces: [workspaceId]),
        ),
        credentialDefinitionsRepository.watchDefinitions(workspaceId),
        credentialsRepository.watchCredentialsForWorkspace(workspaceId),
        _buildItems,
      );
    });

List<ServiceConnectionListItem> _buildItems(
  List<ModelConnectionEntity> modelConnections,
  List<SkillCredentialDefinitionEntity> definitions,
  List<SkillCredentialEntity> credentials,
) {
  final definitionsById = {
    for (final definition in definitions) definition.id: definition,
  };
  final skillCredentialItems = credentials.map((credential) {
    final definition = definitionsById[credential.credentialDefinitionId];

    return ServiceConnectionListItem.fromSkillCredential(
      credential: credential,
      definition: definition,
    );
  });

  return [
    ...modelConnections.map(ServiceConnectionListItem.fromModelConnection),
    ...skillCredentialItems,
  ]..sort((a, b) => a.name.compareTo(b.name));
}
