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
  Future<bool> canUse(int objectId) async {
    final member = await workspaces.CloudWorkspaceRepository().findActiveMember(
      session,
      workspaceId: workspaceId,
      userId: actorUserId,
      transaction: transaction,
    );
    if (member == null) return false;
    final items = ObjectItemAccess(session, member, transaction: transaction);
    final repository = ObjectRepository();
    if (await items.publiclyReadable(objectId) ||
        await repository.hasReadableMessageReference(
          session,
          workspaceId: workspaceId,
          objectId: objectId,
          transaction: transaction,
        )) {
      return true;
    }
    if (await items.retained(objectId) ||
        await repository.hasLiveReference(
          session,
          workspaceId: workspaceId,
          objectId: objectId,
          transaction: transaction,
        )) {
      return false;
    }
    final upload = await repository.findUpload(
      session,
      workspaceId: workspaceId,
      objectId: objectId,
      transaction: transaction,
    );
    return upload?.actorUserId == actorUserId;
  }
}
