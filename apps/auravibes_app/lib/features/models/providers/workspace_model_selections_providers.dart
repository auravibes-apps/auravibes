import 'package:auravibes_app/domain/entities/workspace_model_selection_entities.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_model_selections_providers.g.dart';

@riverpod
Future<List<WorkspaceModelSelectionWithConnectionEntity>>
listWorkspaceModelSelections(
  Ref ref, {
  required String workspaceId,
}) async {
  final workspaceModelSelectionRepository = ref.watch(
    workspaceModelSelectionRepositoryProvider,
  );

  return workspaceModelSelectionRepository.getWorkspaceModelSelections(
    WorkspaceModelSelectionFilter(workspaces: [workspaceId]),
  );
}

/// Groups models by provider name for two-step model selection.
/// Returns a map where keys are provider names and values are lists of models.
@riverpod
Future<Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>>
listModelsGroupedByProvider(Ref ref, {required String workspaceId}) async {
  // Await the underlying FutureProvider so loading/error states propagate automatically.
  final models = await ref.watch(
    listWorkspaceModelSelectionsProvider(workspaceId: workspaceId).future,
  );

  final grouped = <String, List<WorkspaceModelSelectionWithConnectionEntity>>{};

  for (final model in models) {
    final providerName = model.modelsProvider.name;
    grouped.putIfAbsent(providerName, () => []).add(model);
  }

  // Sort provider names alphabetically (FR-006)
  final sortedKeys = grouped.keys.toList()..sort();

  return {for (final key in sortedKeys) key: grouped[key]!};
}
