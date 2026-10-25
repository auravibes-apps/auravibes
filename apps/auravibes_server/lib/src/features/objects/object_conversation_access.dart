import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspaces/repositories/cloud_workspace_repository.dart'
    as workspaces;
import 'object_item_access.dart';
import 'object_repository.dart';

/// Workspace-scoped Conversations cannot implicitly broaden a private item.
class const ObjectConversationAccess(
  final Session session,
  final int workspaceId,
  final String actorUserId,
  final Transaction transaction,
) {
  ObjectRepository get _repository => ObjectRepository();

  Future<bool> canUse(int objectId) async {
    final member = await _member();
    if (member == null) return false;
    final items = ObjectItemAccess(session, member, transaction: transaction);
    if (await _shared(objectId, items)) return true;

    return !await _retained(objectId, items) && await _uploader(objectId);
  }

  Future<WorkspaceMember?> _member() =>
      workspaces.CloudWorkspaceRepository().findActiveMember(
        session,
        workspaceId: workspaceId,
        userId: actorUserId,
        transaction: transaction,
      );

  Future<bool> _shared(int id, ObjectItemAccess items) async =>
      await items.publiclyReadable(id) ||
      await _repository.hasReadableMessageReference(
        session,
        workspaceId: workspaceId,
        objectId: id,
        transaction: transaction,
      );

  Future<bool> _retained(int id, ObjectItemAccess items) async =>
      await items.retained(id) ||
      await _repository.hasLiveReference(
        session,
        workspaceId: workspaceId,
        objectId: id,
        transaction: transaction,
      );

  Future<bool> _uploader(int id) async {
    final upload = await _repository.findUpload(
      session,
      workspaceId: workspaceId,
      objectId: id,
      transaction: transaction,
    );

    return upload?.actorUserId == actorUserId;
  }
}
