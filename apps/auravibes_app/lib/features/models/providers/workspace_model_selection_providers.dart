import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_model_selection_providers.g.dart';

@riverpod
Future<WorkspaceModelSelectionWithConnectionEntity?>
workspaceModelSelectionById(
  Ref ref,
  String workspaceModelSelectionId,
) {
  return ref
      .watch(workspaceModelSelectionRepositoryProvider)
      .getWorkspaceModelSelectionById(workspaceModelSelectionId);
}

@riverpod
Future<int?> modelContextLimit(
  Ref ref,
  String workspaceModelSelectionId,
) async {
  final selectedModel = await ref.watch(
    workspaceModelSelectionByIdProvider(workspaceModelSelectionId).future,
  );
  final modelId = selectedModel?.workspaceModelSelection.modelId;
  final providerId = selectedModel?.modelsProvider.id;
  if (modelId == null || providerId == null) return null;

  final value = await ref.watch(
    getModelByProviderAndModelIdProvider(
      providerId: providerId,
      modelId: modelId,
    ).future,
  );
  return value?.limitContext;
}
