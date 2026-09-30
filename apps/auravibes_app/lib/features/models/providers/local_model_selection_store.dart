part of 'model_store_providers.dart';

class const _LocalModelSelectionStore(
  final WorkspaceModelSelectionRepository _repository,
) implements ModelSelectionStore {
  @override
  Future<WorkspaceModelSelectionWithConnectionEntity?> getById(String id) =>
      _repository.getWorkspaceModelSelectionById(id);

  @override
  Future<void> updateToolSamplingPolicy(
    String selectionId,
    ToolSamplingPolicy? policy,
  ) => _repository.updateToolSamplingPolicy(selectionId, policy);

  @override
  Stream<List<WorkspaceModelSelectionWithConnectionEntity>> watch(
    String workspaceId,
  ) => _repository.watchWorkspaceModelSelections(
    .new(workspaces: [workspaceId]),
  );
}
