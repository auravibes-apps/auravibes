import 'package:auravibes_app/domain/entities/credentials_entities.dart';
import 'package:auravibes_app/features/models/providers/model_providers_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_models_providers.g.dart';

@riverpod
Future<List<CredentialsEntity>> listCredentials(
  Ref ref, {
  required String workspaceId,
}) async {
  final credentialsModelRepository = ref.watch(
    modelProvidersRepositoryProvider,
  );

  return credentialsModelRepository.getCredentials(
    ModelProviderFilter(workspaces: [workspaceId]),
  );
}
