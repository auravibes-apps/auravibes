import 'package:auravibes_app/features/workspaces/models/workspace_revision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const ManageWorkspaceHistoryUsecase(
  final WorkspaceHistoryRepository repository,
) {
  Future<List<WorkspaceRevision>> history(WorkspaceTrashTarget target) =>
      repository.history(target);

  Future<bool> restore(
    WorkspaceTrashTarget target,
    int revision, {
    required Future<bool> Function() approve,
    ConversationToolAccessMode mode = .defaultMode,
  }) async {
    if (mode == .defaultMode && !await approve()) return false;
    await repository.restore(target, revision);
    return true;
  }

  Future<bool> permanentlyDelete(
    WorkspaceTrashTarget target, {
    required Future<bool> Function() approve,
    ConversationToolAccessMode mode = .defaultMode,
  }) async {
    if (mode == .defaultMode && !await approve()) return false;
    await repository.permanentlyDelete(target);
    return true;
  }
}
