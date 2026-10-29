import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const ManageWorkspaceTableAccessUsecase(
  final WorkspaceTableAccessRepository _repository,
) {
  Future<List<WorkspaceTableMember>> members(WorkspaceTable table) {
    _requireOwner(table);

    return _repository.members(table.id);
  }

  Future<void> setMemberAccess({
    required WorkspaceTable table,
    required String userId,
    required String? access,
  }) {
    _requireOwner(table);
    if (access != null && access != 'read' && access != 'edit') {
      throw const WorkspaceTableException();
    }

    return _repository.setMemberAccess(
      table: table,
      userId: userId,
      access: access,
    );
  }
}

void _requireOwner(WorkspaceTable table) {
  if (!table.canManage || !table.supportsSharing) {
    throw const WorkspaceTableException(denied: true);
  }
}
