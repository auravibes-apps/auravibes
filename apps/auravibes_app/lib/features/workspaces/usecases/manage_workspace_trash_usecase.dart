import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const ManageWorkspaceTrashUsecase(
  final WorkspaceTrashRepository _repository,
) {
  Future<WorkspaceDeletedReference?> deletedReference(
    String tableId,
    String recordId,
  ) => _repository.deletedReference(tableId, recordId);

  Future<List<WorkspaceTrashBatch>> list() => _repository.list();

  Future<WorkspaceTrashBatch> preview(WorkspaceTrashTarget target) {
    validateWorkspaceTrashTarget(target);

    return _repository.preview(target);
  }

  Future<WorkspaceTrashBatch?> apply(
    WorkspaceTrashTarget target, {
    required Future<bool> Function(WorkspaceTrashBatch plan) approve,
    ConversationToolAccessMode mode = .defaultMode,
  }) async {
    final plan = await preview(target);
    if (mode == .defaultMode && !await approve(plan)) return null;

    return await _repository.trash(target, planToken: plan.planToken);
  }

  Future<WorkspaceTrashRestoration> restore(String batchId) =>
      _repository.restore(batchId);
}
