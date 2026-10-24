import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_revision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const ManageWorkspaceHistoryUsecase(
  final WorkspaceHistoryRepository repository,
) {
  Future<WorkspaceHistoryPolicy> policy() => repository.policy();

  Future<bool> configurePolicy(
    WorkspaceHistoryPolicy current,
    int? days, {
    required Future<bool> Function() approve,
    ConversationToolAccessMode mode = .defaultMode,
  }) async {
    WorkspaceHistoryPolicy.validate(days);
    if (!current.canManage) throw const WorkspaceTableException(denied: true);
    if (mode == .defaultMode && !await approve()) return false;
    await repository.configure(current, days);

    return true;
  }

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
