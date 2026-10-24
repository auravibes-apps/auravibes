import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';

class const WorkspaceRevision({
  required final WorkspaceTrashTarget target,
  required final Map<String, dynamic> data,
});

abstract interface class WorkspaceHistoryRepository implements WorkspaceHistoryPolicyRepository {
  Future<List<WorkspaceRevision>> history(WorkspaceTrashTarget target);
  Future<void> restore(WorkspaceTrashTarget target, int revision);
  Future<void> permanentlyDelete(WorkspaceTrashTarget target);
}
