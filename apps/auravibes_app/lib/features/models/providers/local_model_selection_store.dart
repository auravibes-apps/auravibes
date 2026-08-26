part of 'model_store_providers.dart';

class _LocalModelSelectionStore implements ModelSelectionStore {
  const _LocalModelSelectionStore(this._repository);

  final WorkspaceModelSelectionRepository _repository;

  @override
  Future<WorkspaceModelSelectionWithConnectionEntity?> getById(String id) =>
      _repository.getWorkspaceModelSelectionById(id);

  @override
  Stream<List<WorkspaceModelSelectionWithConnectionEntity>> watch(
    String workspaceId,
  ) => _repository.watchWorkspaceModelSelections(
    WorkspaceModelSelectionFilter(workspaces: [workspaceId]),
  );
}
