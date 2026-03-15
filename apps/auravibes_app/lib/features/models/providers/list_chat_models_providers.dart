import 'package:auravibes_app/domain/entities/credentials_models_entities.dart';
import 'package:auravibes_app/features/models/providers/model_providers_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_chat_models_providers.g.dart';

@riverpod
Future<List<CredentialsModelWithProviderEntity>> listCredentialsCredentials(
  Ref ref,
) async {
  final credentialsModelRepository = ref.watch(
    credentialsModelsRepositoryProvider,
  );
  final workspaceRepository = ref.watch(workspaceRepositoryProvider);

  final workspaces = await workspaceRepository.getAllWorkspaces();

  return credentialsModelRepository.getCredentialsModels(
    CredentialsModelsFilter(workspaces: workspaces.map((w) => w.id).toList()),
  );
}

/// Groups models by provider name for two-step model selection.
/// Returns a map where keys are provider names and values are lists of models.
@riverpod
Future<Map<String, List<CredentialsModelWithProviderEntity>>>
listModelsGroupedByProvider(Ref ref) async {
  // Await the underlying FutureProvider so loading/error states propagate automatically.
  final models = await ref.watch(listCredentialsCredentialsProvider.future);

  final grouped = <String, List<CredentialsModelWithProviderEntity>>{};

  for (final model in models) {
    final providerName = model.modelsProvider.name;
    grouped.putIfAbsent(providerName, () => []).add(model);
  }

  // Sort provider names alphabetically (FR-006)
  final sortedKeys = grouped.keys.toList()..sort();

  return {for (final key in sortedKeys) key: grouped[key]!};
}
