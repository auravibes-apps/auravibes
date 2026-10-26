import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'object_repository.dart';

class const ObjectMutationAccess(
  final Session session,
  final WorkspaceMember member,
  final Transaction transaction,
) {
  Future<void> requireDelete(int objectId) async {
    if (member.role == 'owner') return;
    final upload = await ObjectRepository().findUpload(
      session,
      workspaceId: member.workspaceId,
      objectId: objectId,
      transaction: transaction,
    );
    if (upload?.actorUserId != member.userId) {
      throw ObjectException(code: .objectNotFound);
    }
  }
}
