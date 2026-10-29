import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'workspace_trash_access.dart';
import 'workspace_trash_store.dart';

class const WorkspaceTrashContext(
  final WorkspaceTrashAccess access,
  final WorkspaceTrashStore store,
  final WorkspaceMember member,
  final CloudWorkspace workspace,
) {
  static Future<WorkspaceTrashContext> load(
    Session session,
    int workspaceId,
    String userId,
    Transaction transaction,
  ) async {
    final access = WorkspaceTrashAccess(
      session,
      workspaceId,
      userId,
      transaction,
    );
    final locked = await access.lock();
    return .new(
      access,
      .new(session, workspaceId, transaction),
      locked.member,
      locked.workspace,
    );
  }

  Future<void> require(WorkspaceResource resource) =>
      access.require(member, resource);
  Future<bool> readable(WorkspaceResource resource) =>
      access.readable(member, resource);
  Future<bool> writable(WorkspaceResource resource) =>
      access.writable(member, resource);
  Future<void> requireBatch(
    WorkspaceTrashBatch batch,
    List<WorkspaceResource> rows,
  ) async {
    for (final input in trashMembers(batch)) {
      final row = trashMemberResource(rows, input);
      if (row == null) trashDenied();
      await require(row);
    }
  }
}
